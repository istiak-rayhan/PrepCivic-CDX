import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 The magic package
import '../../config/theme.dart';
import '../quiz/quiz_screen.dart'; // 🌟 FIXED IMPORT: Pointing to the new engine!
import '../practice/practice_quiz_screen.dart';

class QuizTab extends StatelessWidget {
  final String userPackage;
  const QuizTab({super.key, required this.userPackage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Quiz", // 'Quiz' is universal in most languages, safe to leave hardcoded!
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Random Quiz Banner
            InkWell(
              onTap: () {
                // 🌟 FIXED NAVIGATION: Using our new Mock Test Engine
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuizScreen(topicTitle: 'mock_exam'.tr()),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "⚡ ${'quick_quiz'.tr()}", // 🌟 REPLACED
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'start_random_test'.tr(), // 🌟 REPLACED
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Text(
              'by_category'.tr(), // 🌟 REPLACED
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // 2. Grid (Categories)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.85,
              children: [
                _buildCategoryCard(
                  context,
                  'cat_history'.tr(), // 🌟 Reused JSON key!
                  "Histoire", // Kept exact for SQLite DB
                  CupertinoIcons.book_fill,
                  Colors.blue,
                ),
                _buildCategoryCard(
                  context,
                  'cat_values'.tr(),
                  "Valeurs",
                  CupertinoIcons.heart_fill,
                  Colors.red,
                ),
                _buildCategoryCard(
                  context,
                  'cat_situations'.tr(),
                  "Situations",
                  CupertinoIcons.globe,
                  Colors.green,
                ),
                _buildCategoryCard(
                  context,
                  'cat_society'.tr(),
                  "Société",
                  CupertinoIcons.person_2_fill,
                  Colors.orange,
                ),
                _buildCategoryCard(
                  context,
                  'cat_institutions'.tr(),
                  "Institutions",
                  CupertinoIcons.building_2_fill,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String displayTitle,
    String dbCategory,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        // 🚀 NAVIGATION: Opens the quiz for this specific category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PracticeQuizScreen(
              category: dbCategory,
              userPackage: userPackage,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 30),
            Text(
              displayTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
