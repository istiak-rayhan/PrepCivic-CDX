import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  // List of supported languages with their display names and flags
  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    // ⚠️ COMMENTED OUT BENGALI FOR INITIAL LAUNCH
    {'code': 'bn', 'name': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'ur', 'name': 'اردو', 'flag': '🇵🇰'},
    {'code': 'ps', 'name': 'پښتو', 'flag': '🇦🇫'},
  ];

  void _updateLanguage(String code) async {
    // 1. Update the UI Text via easy_localization
    await context.setLocale(Locale(code));

    // 2. Save to SharedPreferences so the Quiz Database knows which column to read!
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', code);

    // 3. Force UI rebuild and show confirmation
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('welcome'.tr()),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 Get the current active language from easy_localization
    final currentLanguage = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'subtitle'.tr(), // 🌟 easy_localization translation call
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = currentLanguage == lang['code'];

                  return Card(
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 30),
                      ),
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade700,
                            )
                          : const Icon(
                              Icons.circle_outlined,
                              color: Colors.grey,
                            ),
                      onTap: () => _updateLanguage(lang['code']!),
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
}
