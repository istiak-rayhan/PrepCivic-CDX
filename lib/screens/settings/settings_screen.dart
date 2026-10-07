import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/account_deletion_service.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 THE RIGHT TRANSLATION ENGINE
import '../../config/theme.dart';
import 'language_settings_screen.dart';
import '../../auth_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 🌍 URL Launcher Helper
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // 📧 Email Launcher Helper
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contact@torcdigital.fr',
      query: 'subject=Support Request - PrepCivic App',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // 🌟 App Store Mandatory Account Deletion
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'delete_confirm_title'.tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text('delete_confirm_desc'.tr(), style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr(),
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'delete'.tr(),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirm == true) {
      final passwordController = TextEditingController();
      final password = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('confirm_password'.tr()),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: 'password'.tr()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, passwordController.text),
              child: Text('delete'.tr()),
            ),
          ],
        ),
      );
      // Wait for the dialog's transition before disposing its controller.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      passwordController.dispose();
      if (password == null || password.isEmpty || !context.mounted) return;
      final navigator = Navigator.of(context, rootNavigator: true);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator(color: Colors.red)),
        ),
      );
      try {
        await AccountDeletionService.delete(password);
        if (context.mounted) {
          navigator.pop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      } catch (error) {
        if (context.mounted) {
          navigator.pop();
          final authenticationError =
              error is FirebaseAuthException &&
              [
                'wrong-password',
                'invalid-credential',
                'requires-recent-login',
              ].contains(error.code);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (authenticationError ? 'reauth_required' : 'delete_failed')
                    .tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text('settings'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 SECTION: General
            _buildSectionTitle('section_general'.tr()),
            _buildSection([
              _buildTile(
                icon: Icons.language,
                title: 'language'.tr(),
                subtitle: context.locale.languageCode.toUpperCase(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const LanguageSettingsScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            // 🌟 SECTION: Support & Legal
            _buildSectionTitle('section_support_legal'.tr()),
            _buildSection([
              _buildTile(
                icon: CupertinoIcons.question_circle,
                title: 'faq'.tr(),
                subtitle: 'faq_sub'.tr(),
                onTap: () {}, // Add FAQ route if you have one
              ),
              _buildTile(
                icon: CupertinoIcons.mail,
                title: 'contact'.tr(),
                subtitle: "contact@torcdigital.fr",
                onTap: _launchEmail,
              ),
              _buildTile(
                icon: CupertinoIcons.doc_text,
                title: 'privacy_policy'.tr(),
                subtitle: 'privacy_sub'.tr(),
                onTap: () =>
                    _launchURL('https://torcdigital.fr/privacy-policy/'),
              ),
              _buildTile(
                icon: CupertinoIcons.doc_text_fill,
                title: 'terms_of_use'.tr(),
                subtitle: 'terms_sub'.tr(),
                onTap: () =>
                    _launchURL('https://torcdigital.fr/terms-and-conditions/'),
              ),
            ]),
            const SizedBox(height: 24),

            // 🌟 SECTION: Danger Zone
            _buildSectionTitle('section_danger_zone'.tr(), isDanger: true),
            _buildSection([
              _buildTile(
                icon: Icons.logout,
                title: 'logout'.tr(),
                subtitle: 'logout_sub'.tr(),
                isDestructive: true,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isGuest', false);
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthWrapper(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
              _buildTile(
                icon: CupertinoIcons.delete_solid,
                title: 'delete_account'.tr(),
                subtitle: 'irreversible_action'.tr(),
                isDestructive: true,
                onTap: () => _deleteAccount(context),
              ),
            ]),
            const SizedBox(height: 40),

            // 🌟 App Version Footer
            Center(
              child: Text(
                "PrepCivic v1.0.0",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDanger ? Colors.red.shade400 : Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : AppTheme.primaryBlue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppTheme.primaryBlue,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
