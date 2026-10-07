import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/translation_service.dart';
import 'package_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                "Bienvenue / Welcome",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // 🌟 UPDATED TEXT: Removed Bengali for the initial launch
              Text(
                "Apprenez le français avec un support complet en :\nLearn in French with full support in:\nEnglish, Bengali, Arabic, Urdu & Pashto",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // UI & Supported Languages
              _buildLangButton("Français", "🇫🇷", "fr"),
              _buildLangButton("English", "🇺🇸", "en"),

              // ⚠️ COMMENTED OUT BENGALI FOR INITIAL LAUNCH
              _buildLangButton("বাংলা (Bengali)", "🇧🇩", "bn"),
              _buildLangButton("العربية (Arabic)", "🇸🇦", "ar"),
              _buildLangButton("اردو (Urdu)", "🇵🇰", "ur"),
              _buildLangButton("پښتو (Pashto)", "🇦🇫", "ps"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(String name, String flag, String code) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFFE5E5EA)),
        ),
        onPressed: () async {
          // This forces the ENTIRE Flutter app to rebuild with the new language JSON
          await context.setLocale(Locale(code));

          // Save for your custom services
          await TranslationService.setLanguage(code);

          // Save for PracticeQuizScreen DB queries
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selectedLanguage', code);

          if (mounted && context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (c) => const PackageScreen()),
            );
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
