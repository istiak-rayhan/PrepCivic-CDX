import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 The magic package
import '../../config/theme.dart';
import 'practice_quiz_screen.dart';

class CategorySelectionScreen extends StatelessWidget {
  final String userPackage;

  // 🌟 Kept the DB names as keys, but changed uiName to translation keys
  final Map<String, Map<String, dynamic>> categories = {
    'La République': {
      'uiName': 'cat_republic',
      'icon': CupertinoIcons.building_2_fill,
      'color': Colors.blue,
    },
    'Histoire': {
      'uiName': 'cat_history',
      'icon': CupertinoIcons.book_fill,
      'color': Colors.orange,
    },
    'Valeurs': {
      'uiName': 'cat_values',
      'icon': CupertinoIcons.heart_fill,
      'color': Colors.red,
    },
    'Situations': {
      'uiName': 'cat_situations',
      'icon': CupertinoIcons.person_3_fill,
      'color': Colors.green,
    },
    'Société': {
      'uiName': 'cat_society',
      'icon': CupertinoIcons.group_solid,
      'color': Colors.purple,
    },
    'Institutions': {
      'uiName': 'cat_institutions',
      'icon': CupertinoIcons.shield_fill,
      'color': Colors.teal,
    },
  };

  CategorySelectionScreen({super.key, required this.userPackage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'practice_modules'.tr(), // 🌟 REPLACED
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'choose_theme'.tr(), // 🌟 REPLACED
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.9,
                ),
                itemCount: categories.keys.length,
                itemBuilder: (context, index) {
                  String dbName = categories.keys.elementAt(index);
                  var data = categories[dbName]!;
                  return InkWell(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PracticeQuizScreen(
                            category: dbName,
                            userPackage: userPackage,
                          ),
                        ),
                      );
                    },
                    child: _buildCategoryCard(
                      title: (data['uiName'] as String)
                          .tr(), // 🌟 TRANSLATED HERE
                      icon: data['icon'],
                      color: data['color'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
