import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/practice_repository.dart';
import '../../services/question_text.dart';
import '../../config/theme.dart';
import '../premium/subscription_screen.dart';

class PracticeQuizScreen extends StatefulWidget {
  final String category;
  final String userPackage;
  final PracticeRepository repository;

  const PracticeQuizScreen({
    super.key,
    required this.category,
    required this.userPackage,
    this.repository = const LocalPracticeRepository(),
  });

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  bool isLoading = true;
  String activeLanguage = 'fr';
  bool _isReviewing = false;
  String? _loadError;
  final Set<String> _sessionQuestionIds = {};

  int correctAnswersCount = 0;
  Map<int, int> selectedOptions = {};
  Map<int, int> answerStatuses = {};

  String _userTier = 'free';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  String _getCleanFrench(String text) => QuestionText.french(text);

  String _getTranslation(String text, String french) =>
      QuestionText.translation(text, french);

  Future<void> _initializeData() async {
    try {
      final savedLang = await widget.repository.language();
      final tier = await widget.repository.tier();
      if (!mounted) return;
      setState(() {
        activeLanguage = savedLang;
        _userTier = tier;
      });
      await _loadQuestions();
    } catch (error) {
      debugPrint('Practice initialization failed: $error');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _loadError = 'question_load_error';
      });
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      isLoading = true;
      _loadError = null;
    });
    try {
      final data = await widget.repository.questions(
        widget.category,
        _userTier,
        _sessionQuestionIds,
      );
      if (!mounted) return;
      setState(() {
        questions = data;
        currentIndex = 0;
        correctAnswersCount = 0;
        selectedOptions.clear();
        answerStatuses.clear();
        _isReviewing = false;
        _sessionQuestionIds.addAll(data.map((q) => q['hash_id'] as String));
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Practice load failed: $error');
      if (mounted)
        setState(() {
          isLoading = false;
          _loadError = 'question_load_error';
        });
    }
  }

  void _checkAnswer(int optionId, bool isCorrect) async {
    if (_isReviewing || answerStatuses.containsKey(currentIndex)) return;

    setState(() {
      selectedOptions[currentIndex] = optionId;
      answerStatuses[currentIndex] = isCorrect ? 1 : 2;
      if (isCorrect) correctAnswersCount++;
    });

    final currentQuestion = questions[currentIndex];
    try {
      await widget.repository.saveAnswer(currentQuestion['hash_id'], isCorrect);
    } catch (error) {
      debugPrint('Progress sync failed: $error');
    }
  }

  void _nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else if (!_isReviewing) {
      _showCompletionSheet();
    }
  }

  void _prevQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void _showCompletionSheet() {
    bool isFree = _userTier == 'free';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 60,
              ),
              const SizedBox(height: 10),
              Text(
                'session_completed'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),

              Text(
                "${'score'.tr()}: $correctAnswersCount / ${questions.length}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                isFree
                    ? 'free_practice_completed'.tr()
                    : 'smart_10_completed'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFree
                        ? Colors.amber
                        : AppTheme.primaryColor,
                    foregroundColor: isFree ? Colors.black87 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    if (isFree) {
                      final purchased = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      );
                      if (purchased == true && mounted) {
                        await _initializeData();
                      }
                    } else {
                      await _loadQuestions();
                    }
                  },
                  icon: Icon(isFree ? Icons.workspace_premium : Icons.replay),
                  label: Text(
                    isFree ? 'practice_new_premium'.tr() : 'more_practice'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _isReviewing = true;
                      currentIndex = 0;
                    });
                  },
                  icon: Icon(Icons.history, color: AppTheme.primaryColor),
                  label: Text(
                    'practice_review'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pop(context);
                },
                child: Text(
                  'back_to_modules'.tr(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFlag(String langCode) {
    switch (langCode) {
      case 'bn':
        return '🇧🇩';
      case 'ar':
        return '🇸🇦';
      case 'ur':
        return '🇵🇰';
      case 'ps':
        return '🇦🇫';
      case 'en':
        return '🇬🇧';
      default:
        return '🌐';
    }
  }

  bool _isRTL(String langCode) => ['ar', 'ur', 'ps'].contains(langCode);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!.tr()),
              TextButton(onPressed: _initializeData, child: Text('retry'.tr())),
            ],
          ),
        ),
      );
    }
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'mastered_all'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    final question = questions[currentIndex];
    final options = question['options'] as List<dynamic>;

    // 🌟 1. Parse Main Question Perfectly
    final String cleanFrenchQuestion = _getCleanFrench(
      question['text_fr'] ?? '',
    );

    String translatedQuestion = '';
    if (activeLanguage != 'fr') {
      final String rawTranslated = question['text_$activeLanguage'] ?? '';
      translatedQuestion = _getTranslation(rawTranslated, cleanFrenchQuestion);

      // Safety Check: If translation is exactly the same as French, don't show it twice.
      if (translatedQuestion == cleanFrenchQuestion) {
        translatedQuestion = '';
      }
    }

    final int currentStatus = answerStatuses[currentIndex] ?? 0;
    final int? currentSelected = selectedOptions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${'question'.tr()} ${currentIndex + 1}/${questions.length}",
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: _isReviewing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'practice_review'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanFrenchQuestion,
                  textDirection:
                      ui.TextDirection.ltr, // 🌟 Shows ONLY clean French
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (translatedQuestion.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Directionality(
                      textDirection: _isRTL(activeLanguage)
                          ? ui.TextDirection.rtl
                          : ui.TextDirection.ltr,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_getFlag(activeLanguage)} ",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Expanded(
                            child: Text(
                              translatedQuestion, // 🌟 Shows ONLY the pure translation
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.blueGrey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index] as Map<String, dynamic>;
                final isSelected = currentSelected == opt['id'];
                final isCorrect = opt['is_correct'] == 1;

                // 🌟 2. Parse Options Perfectly
                final String cleanFrenchOption = _getCleanFrench(
                  opt['text_fr'] ?? '',
                );

                String translatedOption = '';
                if (activeLanguage != 'fr') {
                  final String rawTranslatedOpt =
                      opt['text_$activeLanguage'] ?? '';
                  translatedOption = _getTranslation(
                    rawTranslatedOpt,
                    cleanFrenchOption,
                  );

                  if (translatedOption == cleanFrenchOption) {
                    translatedOption = '';
                  }
                }

                Color cardColor = Colors.white;
                if (currentStatus != 0) {
                  if (isSelected && isCorrect)
                    cardColor = Colors.green.shade100;
                  if (isSelected && !isCorrect) cardColor = Colors.red.shade100;
                  if (!isSelected && isCorrect && currentStatus == 2) {
                    cardColor = Colors.green.shade50;
                  }
                }

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    onTap: _isReviewing
                        ? null
                        : () => _checkAnswer(opt['id'], isCorrect),
                    title: Text(
                      cleanFrenchOption,
                      textDirection: ui
                          .TextDirection
                          .ltr, // 🌟 Shows ONLY clean French Option
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: translatedOption.isNotEmpty
                        ? Directionality(
                            textDirection: _isRTL(activeLanguage)
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                            child: Text(
                              translatedOption, // 🌟 Shows ONLY pure translated Option
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : null,
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    trailing: (currentStatus != 0 && isCorrect)
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : (currentStatus != 0 && isSelected && !isCorrect)
                        ? const Icon(Icons.cancel, color: Colors.red)
                        : null,
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: currentIndex > 0 ? _prevQuestion : null,
                  icon: const Icon(Icons.arrow_back),
                  label: Text('prev'.tr()),
                ),
                ElevatedButton.icon(
                  onPressed: _isReviewing
                      ? () {
                          if (currentIndex == questions.length - 1) {
                            Navigator.pop(context);
                          } else {
                            _nextQuestion();
                          }
                        }
                      : currentStatus != 0
                      ? _nextQuestion
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    currentIndex == questions.length - 1
                        ? (_isReviewing
                              ? 'back_to_modules'.tr()
                              : 'finish'.tr())
                        : 'next'.tr(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
