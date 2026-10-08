import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/question_model.dart';
import '../../services/database_service.dart';
import '../../services/purchase_service.dart';
import 'result_screen.dart';
import '../premium/subscription_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topicTitle;
  final VoidCallback? onDashboard;

  const QuizScreen({super.key, required this.topicTitle, this.onDashboard});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<QuestionModel> _questions = [];
  bool _isLoading = true;

  bool _isStarted = false;
  bool _isSubmitting = false;
  bool _needsPremium = false;

  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerChecked = false;
  int _score = 0;

  Timer? _timer;
  DateTime? _deadline;
  int _timeLeft = 45 * 60; // 45 minutes

  String _userTier = 'free';
  bool _hasTakenFreeMock = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // 🌟 SENIOR DEV OPS FIX: Safeguard against background thread execution
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _deadline = DateTime.now().add(Duration(seconds: _timeLeft));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isSubmitting) {
        timer.cancel();
        return;
      }
      final milliseconds = _deadline!.difference(DateTime.now()).inMilliseconds;
      final remaining = milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
      setState(() => _timeLeft = remaining);
      if (remaining == 0) {
        timer.cancel();
        _submitQuiz();
      }
    });
  }

  String get _formattedTime {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _isSubmitting = false;
    _needsPremium = false;
    _hasTakenFreeMock = false;
    _userTier = await PurchaseService.currentTier();
    if (!mounted) return;

    bool isMockTest =
        widget.topicTitle == 'mock_exam'.tr() ||
        widget.topicTitle == 'Examen Blanc (Mock Test)';

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && isMockTest && _userTier == 'free') {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get()
            .timeout(const Duration(seconds: 15));

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          _hasTakenFreeMock = data['has_taken_free_mock'] ?? false;
          int bonusMocks = data['bonus_mocks'] ?? 0;

          if (isMockTest && _userTier == 'free' && _hasTakenFreeMock) {
            if (bonusMocks <= 0) {
              _needsPremium = true;
            }
          }
        }
      }

      if (currentUser == null && isMockTest && _userTier == 'free') {
        final prefs = await SharedPreferences.getInstance();
        _hasTakenFreeMock = prefs.getBool('guest_free_mock_used') ?? false;
        _needsPremium = _hasTakenFreeMock;
      }

      List<QuestionModel> fetchedQuestions = [];

      if (isMockTest) {
        fetchedQuestions = await _dbService.getAllQuestions();
      } else {
        String moduleName = widget.topicTitle.toLowerCase();
        fetchedQuestions = await _dbService.getQuestionsForModule(moduleName);
      }

      if (fetchedQuestions.isNotEmpty) {
        fetchedQuestions.shuffle();
        int limit = isMockTest ? 40 : 10;
        if (fetchedQuestions.length > limit) {
          fetchedQuestions = fetchedQuestions.sublist(0, limit);
        }
      }

      if (mounted) {
        setState(() {
          _questions = fetchedQuestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error in QuizScreen _loadData: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTest() {
    if (_needsPremium) {
      _showPremiumUpsell();
    } else {
      setState(() {
        _isStarted = true;
      });
      _startTimer();
    }
  }

  void _showPremiumUpsell() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'premium_required'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'free_mock_used'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );

              if (result == true && mounted) {
                setState(() {
                  _needsPremium = false;
                  _userTier = 'premium';
                  _isStarted = true;
                });
                _startTimer();
              }
            },
            child: Text(
              'unlock_premium'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(int index) {
    if (_isAnswerChecked) return;

    setState(() {
      _selectedOptionIndex = index;
      _isAnswerChecked = true;
      if (index == _questions[_currentIndex].correctAnswerIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswerChecked = false;
      });
    } else {
      _submitQuiz();
    }
  }

  // 🌟 BULLETPROOF SUBMIT: Resolves permission issues and infinity spinners
  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await _dbService.saveQuizScore(
        widget.topicTitle,
        _score,
        _questions.length,
      );

      bool isMockTest =
          widget.topicTitle == 'mock_exam'.tr() ||
          widget.topicTitle == 'Examen Blanc (Mock Test)';
      if (isMockTest && _userTier == 'free') {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid);
          if (!_hasTakenFreeMock) {
            await userDocRef
                .set({'has_taken_free_mock': true}, SetOptions(merge: true))
                .timeout(const Duration(seconds: 15));
          } else {
            await userDocRef
                .set({
                  'bonus_mocks': FieldValue.increment(-1),
                }, SetOptions(merge: true))
                .timeout(const Duration(seconds: 15));
          }
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('guest_free_mock_used', true);
        }
      }
    } catch (e) {
      print("❌ DevOps Error saving quiz score/metadata: $e");
    } finally {
      // 🌟 Always pop spinner and route to results no matter the backend sync status
      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              score: _score,
              totalQuestions: _questions.length,
              onRestart: () {
                if (!mounted) return;
                setState(() {
                  _currentIndex = 0;
                  _score = 0;
                  _selectedOptionIndex = null;
                  _isAnswerChecked = false;
                  _isLoading = true;
                  _isStarted = false;
                  _timeLeft = 45 * 60;
                });
                _loadData();
              },
              onDashboard: () {
                if (!mounted) return;
                _timer?.cancel();
                setState(() {
                  _isStarted = false;
                  _currentIndex = 0;
                  _score = 0;
                  _selectedOptionIndex = null;
                  _isAnswerChecked = false;
                  _timeLeft = 45 * 60;
                });
                _loadData();
                if (widget.onDashboard != null) {
                  widget.onDashboard!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      }
    }
  }

  // 🌟 ARCHITECT LEVEL FIX: System Back Button Confirmation Dialog
  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Abandonner le test ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir quitter ? Votre progression actuelle sera perdue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Continuer",
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Quitter", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                size: 80,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              widget.topicTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Êtes-vous prêt à tester vos connaissances ? Assurez-vous d'être dans un environnement calme.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.format_list_numbered,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_questions.length} Questions",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.indigo),
                      const SizedBox(height: 8),
                      Text(
                        _formattedTime,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "Commencer le test",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.topicTitle,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 1),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('question_load_error'.tr()),
              TextButton(onPressed: _loadData, child: Text('retry'.tr())),
            ],
          ),
        ),
      );
    }

    if (!_isStarted) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: _buildStartScreen(),
      );
    }

    final question = _questions[_currentIndex];

    // 🌟 DEVOPS SECURITY WRAP: PopScope blocks unintended system back gestures during exams
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.topicTitle,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Center(
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: _timeLeft < 300 ? Colors.red : Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      color: _timeLeft < 300 ? Colors.red : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "${_currentIndex + 1} / ${_questions.length}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: Colors.grey[200],
                color: Colors.indigo,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  question.questionText ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final isSelected = _selectedOptionIndex == i;
                    final isCorrect = i == question.correctAnswerIndex;
                    Color bgColor = Colors.white;
                    Color borderColor = Colors.grey.shade300;
                    IconData? icon;

                    if (_isAnswerChecked) {
                      if (isCorrect) {
                        bgColor = Colors.green.shade50;
                        borderColor = Colors.green;
                        icon = Icons.check_circle;
                      } else if (isSelected) {
                        bgColor = Colors.red.shade50;
                        borderColor = Colors.red;
                        icon = Icons.cancel;
                      }
                    }

                    return InkWell(
                      onTap: () => _answerQuestion(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(
                            color: isSelected ? Colors.indigo : borderColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                question.options[i],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _isAnswerChecked && isCorrect
                                      ? Colors.green
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (icon != null) Icon(icon, color: borderColor),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isAnswerChecked)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentIndex == _questions.length - 1
                        ? 'finish_module'.tr()
                        : 'next_question'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
