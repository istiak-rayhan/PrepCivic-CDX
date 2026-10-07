import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login_screen.dart'; // 🌟 ADDED IMPORT

class RegisterScreen extends StatefulWidget {
  final String? selectedPackage;

  const RegisterScreen({super.key, this.selectedPackage});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  bool isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('fill_all_fields'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invalid_email'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 🌟 NEW: SEND THE VERIFICATION EMAIL IMMEDIATELY
      await userCredential.user!.sendEmailVerification();

      String finalPackage = widget.selectedPackage ?? 'citizenship';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'role': 'student',
            'packageId': finalPackage,
            'createdAt': FieldValue.serverTimestamp(),
            'subscription_tier': 'free',
            'has_taken_free_mock': false,
            'share_count': 0,
            'bonus_mocks': 0,
          });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuest', false);

      // 🌟 SECURITY GATE: Sign them out so they MUST verify to get back in
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        setState(() => _isLoading = false);
        // Show success popup, then go back to login screen
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'verify_email_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('verify_email_sent_msg'.tr()),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close dialog
                  // 🌟 FIX: Safely route to Login Screen after successful registration
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'registration_failed'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade600],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Hero(
                tag: 'auth_icon',
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 90,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'register_title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (widget.selectedPackage != null)
                Text(
                  "${'package'.tr()}: ${widget.selectedPackage}",
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              const SizedBox(height: 30),

              _buildTextField(
                _nameController,
                'full_name'.tr(),
                Icons.person_outline,
                false,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _emailController,
                'email'.tr(),
                Icons.email_outlined,
                false,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _passwordController,
                'password'.tr(),
                Icons.lock_outline,
                true,
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _signUp,
                        child: Text(
                          'btn_register'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              TextButton(
                // 🌟 FIX: Explicitly route to Login instead of popping back to Package Selection
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  'already_account'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPassword,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: label.toLowerCase().contains('@') || label == 'email'.tr()
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
