import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../settings/settings_screen.dart';
import '../../services/database_helper.dart';
import '../premium/subscription_screen.dart';

class ProfileTab extends StatefulWidget {
  final String userPackage;
  const ProfileTab({super.key, required this.userPackage});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final User? user = FirebaseAuth.instance.currentUser;

  int _shareCount = 0;
  int _bonusMocks = 0;
  String _displayName = "Candidat";
  Map<String, String> _stats = {'quiz': '0', 'avg': '0%', 'rate': '0%'};

  List<Map<String, dynamic>> _masteryStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // 1. 🌟 FETCH SQLITE DATA FIRST (Works for everyone, logged in or not!)
      final masteryData = await DatabaseHelper.instance
          .getCategoryMasteryStats();
      if (mounted) {
        setState(() {
          _masteryStats = masteryData;
        });
      }

      // 2. 🌟 FETCH FIREBASE DATA (Only if the user is authenticated)
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>?;
          _displayName = userData?['name'] ?? "Candidat";
          _shareCount = userData?['share_count'] ?? 0;
          _bonusMocks = userData?['bonus_mocks'] ?? 0;
        }

        QuerySnapshot cloudResults = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('mock_scores')
            .get();

        int totalTests = cloudResults.docs.length;
        double totalScorePercentage = 0;
        int passedTests = 0;

        for (var doc in cloudResults.docs) {
          var data = doc.data() as Map<String, dynamic>;
          int score = data['score'] ?? 0;
          int total = data['total'] ?? 40;
          double percentage = total > 0 ? (score / total) * 100 : 0;
          totalScorePercentage += percentage;
          if (score >= 24) passedTests++;
        }

        if (mounted) {
          setState(() {
            _stats = {
              'quiz': totalTests.toString(),
              'avg': totalTests > 0
                  ? "${(totalScorePercentage / totalTests).toInt()}%"
                  : "0%",
              'rate': totalTests > 0
                  ? "${((passedTests / totalTests) * 100).toInt()}%"
                  : "0%",
            };
          });
        }
      }
    } catch (e) {
      print("Error loading profile data: $e");
    } finally {
      // 🌟 THE FIX: This ensures the loading spinner ALWAYS disappears!
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _inviteFriend() async {
    if (user == null) {
      // Free/Guest users cannot save shares to Firebase. Show an alert or prompt login.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez vous connecter pour inviter des amis et gagner des tests.',
          ),
        ),
      );
      return;
    }

    await Share.share(
      'Préparez votre naturalisation française avec PrepCivic ! Téléchargez l\'app : https://prepcivic.com',
    );

    int newCount = _shareCount + 1;
    if (newCount >= 5) {
      setState(() {
        _shareCount = 0;
        _bonusMocks += 1;
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'share_count': 0, 'bonus_mocks': FieldValue.increment(1)});
      _showUnlockDialog();
    } else {
      setState(() => _shareCount = newCount);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'share_count': newCount});
    }
  }

  void _showUnlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Icon(Icons.celebration, color: Colors.amber, size: 60),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'congratulations'.tr(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'mock_unlocked_desc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'awesome'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Header Section
                  Container(
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: 20,
                      right: 20,
                      bottom: 30,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.person_fill,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                CupertinoIcons.settings,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => const SettingsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.userPackage.toUpperCase().replaceAll(
                              '_',
                              ' ',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. The Viral Invite Feature
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.amber,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'invite_desc'.tr(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _shareCount / 5,
                            color: Colors.amber,
                            backgroundColor: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$_shareCount/5 ${'shared'.tr()}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _inviteFriend,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'invite_title'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_bonusMocks > 0) ...[
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "🎁 $_bonusMocks ${'bonus_mock_available'.tr()}",
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 3. Subscription / Upgrade Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.workspace_premium),
                        label: Text(
                          'subscription_plans'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Performance Statistics (Mock Exams)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'stats_title'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                CupertinoIcons.pencil_outline,
                                _stats['quiz']!,
                                "Tests",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                CupertinoIcons.chart_bar,
                                _stats['avg']!,
                                "Moyenne",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                CupertinoIcons.check_mark_circled,
                                _stats['rate']!,
                                "Réussite",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 5. Category Mastery Breakdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'category_mastery'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (_masteryStats.isEmpty)
                          const Center(child: Text("Aucune donnée disponible"))
                        else
                          ..._masteryStats.map((stat) {
                            int mastered = stat['mastered_questions'] ?? 0;
                            int total =
                                stat['total_questions'] ??
                                1; // Avoid divide by zero
                            double progress = mastered / total;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        stat['category'] ?? 'Catégorie',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "$mastered / $total",
                                        style: TextStyle(
                                          color: Colors.indigo.shade400,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: progress,
                                    color: Colors.green,
                                    backgroundColor: Colors.grey.shade200,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF007AFF), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
