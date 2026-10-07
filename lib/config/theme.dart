import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 1. New Apple-Style Colors
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color secondaryYellow = Color(0xFFFFD600);
  static const Color appleRed = Color(0xFFFF3B30);
  static const Color background = Color(0xFFF2F2F7);

  // Text Colors (Required for ProfileTab)
  static const Color textDark = Color(0xFF1C1C1E);
  static const Color textGrey = Color(0xFF8E8E93);

  // 🛠️ 2. BACKWARD COMPATIBILITY (This fixes your red errors)
  // We map the old names to the new Apple colors.
  static const Color primaryColor = primaryBlue;
  static const Color secondaryColor = appleRed;
  static const Color whiteColor = Colors.white;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    primaryColor: primaryBlue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: secondaryYellow,
      error: appleRed,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryBlue),
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Color(0xFFC7C7CC),
      showUnselectedLabels: true,
      elevation: 10,
    ),
  );
}
