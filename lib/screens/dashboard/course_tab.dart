import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import '../../config/theme.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 The magic package

class CourseTab extends StatelessWidget {
  final String userPackage;
  const CourseTab({super.key, required this.userPackage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'modules'.tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
      ),
      // 🌟 ADDED SingleChildScrollView to prevent overflow with 6 items
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.hammer,
                    size: 60,
                    color: AppTheme.secondaryYellow,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'coming_soon'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'coming_soon_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                // 🌟 All 6 Actual Database Categories Added!
                Opacity(
                  opacity: 0.5,
                  child: Column(
                    children: [
                      _buildLockedItem('module_republic'.tr()),
                      const SizedBox(height: 10),
                      _buildLockedItem('module_history'.tr()),
                      const SizedBox(height: 10),
                      _buildLockedItem('module_values'.tr()),
                      const SizedBox(height: 10),
                      _buildLockedItem('module_situations'.tr()),
                      const SizedBox(height: 10),
                      _buildLockedItem('module_society'.tr()),
                      const SizedBox(height: 10),
                      _buildLockedItem('module_institutions'.tr()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedItem(String title) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.grey, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
