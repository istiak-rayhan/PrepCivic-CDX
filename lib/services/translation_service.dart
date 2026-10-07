import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static String _currentLang = 'en'; // Changed default to English
  static const String _storageKey = 'selected_language';

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'welcome': 'Bonjour 👋',
      'subtitle': 'Préparez votre naturalisation',
      'btn_practice': 'Entraînement',
      'sub_practice': '8 Modules',
      'btn_mock': 'Examen Blanc',
      'sub_mock': 'Conditions réelles',
      'btn_stats': 'Voir Progrès',
      'login_title': 'Connexion',
      'register_title': 'Créer un compte',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'full_name': 'Nom complet',
      'btn_login': 'Se connecter',
      'btn_register': "S'inscrire",
      'no_account': 'Pas de compte? Inscrivez-vous',
      'already_account': 'Déjà un compte? Connectez-vous',
      'stats_title': 'Statistiques',
      'invite_title': 'Inviter',
      'invite_desc': 'Invitez 5 amis pour débloquer',
      'settings': 'Paramètres',
      'language': 'Langue',
      'faq': 'Foire aux questions (FAQ)',
      'contact': 'Nous contacter',
      'reset': 'Effacer ma progression',
      'logout': 'Se déconnecter',
      'results': 'Résultats',
      'back_menu': 'Retour au menu',
    },
    'en': {
      'welcome': 'Welcome 👋',
      'subtitle': 'Prepare for naturalization',
      'btn_practice': 'Practice',
      'sub_practice': '8 Modules',
      'btn_mock': 'Mock Exam',
      'sub_mock': 'Real conditions',
      'btn_stats': 'View Progress',
      'login_title': 'Welcome Back',
      'register_title': 'Create Account',
      'email': 'Email Address',
      'password': 'Password',
      'full_name': 'Full Name',
      'btn_login': 'Login',
      'btn_register': 'Register',
      'no_account': 'No account? Sign up',
      'already_account': 'Have an account? Login',
      'stats_title': 'Your Statistics',
      'invite_title': 'Invite',
      'invite_desc': 'Invite 5 friends to unlock',
      'settings': 'Settings',
      'language': 'Language',
      'faq': 'Frequently Asked Questions',
      'contact': 'Contact Us',
      'reset': 'Reset Progress',
      'logout': 'Log Out',
      'results': 'Results',
      'back_menu': 'Back to Menu',
    },
    'bn': {
      'welcome': 'স্বাগতম 👋',
      'subtitle': 'আপনার প্রস্তুতি শুরু করুন',
      'btn_practice': 'অনুশীলন',
      'sub_practice': '৮টি মডিউল',
      'btn_mock': 'মক টেস্ট',
      'sub_mock': 'আসল পরীক্ষার মত',
      'btn_stats': 'অগ্রগতি দেখুন',
      'login_title': 'লগইন করুন',
      'register_title': 'অ্যাকাউন্ট তৈরি করুন',
      'email': 'ইমেইল ঠিকানা',
      'password': 'পাসওয়ার্ড',
      'full_name': 'পুরো নাম',
      'btn_login': 'লগইন',
      'btn_register': 'নিবন্ধন করুন',
      'no_account': 'অ্যাকাউন্ট নেই? সাইন আপ করুন',
      'already_account': 'অ্যাকাউন্ট আছে? লগইন করুন',
      'stats_title': 'আপনার পরিসংখ্যান',
      'invite_title': 'আমন্ত্রণ',
      'invite_desc': 'আনলক করতে ৫ জন বন্ধুকে আমন্ত্রণ জানান',
      'settings': 'সেটিংস',
      'language': 'ভাষা',
      'faq': 'সাধারণ জিজ্ঞাসা (FAQ)',
      'contact': 'যোগাযোগ করুন',
      'reset': 'প্রগতি মুছুন',
      'logout': 'লগ আউট',
      'results': 'ফলাফল',
      'back_menu': 'মেনুতে ফিরে যান',
    },
  };

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLang = prefs.getString(_storageKey) ?? 'en';
  }

  static Future<void> setLanguage(String code) async {
    if (_localizedValues.containsKey(code)) {
      _currentLang = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, code);
    }
  }

  static String get currentLanguage => _currentLang;

  static String get(String key) {
    return _localizedValues[_currentLang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  static String french(String key) => get(key);

  static String dual(String key) {
    if (_currentLang == 'en' || _currentLang == 'fr') return get(key);
    return "${_localizedValues['fr']?[key]} / ${get(key)}";
  }

  static String dualInline(String key) => dual(key);
}
