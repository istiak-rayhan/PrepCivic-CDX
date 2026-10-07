import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 ADDED FOR AUTO-LOGIN
import 'package:shared_preferences/shared_preferences.dart'; // 🌟 ADDED FOR GUEST CHECK

import '../../auth_wrapper.dart';
import '../../services/database_helper.dart';
import '../main_screen.dart'; // 🌟 ADDED FOR DIRECT ROUTING

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Fade-in animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 2. Start the initialization process
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      print("🚀 Splash: Initializing Database...");
      await DatabaseHelper.instance.database;
      print("✅ Splash: Database Ready.");
    } catch (e) {
      print("❌ Splash: Database Error: $e");
    }

    int elapsed = stopwatch.elapsedMilliseconds;
    int remaining = 3000 - elapsed;

    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    // ==========================================================
    // 🌟 PRODUCTION-GRADE AUTO-LOGIN LOGIC
    // ==========================================================
    User? user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    bool isGuest = prefs.getBool('isGuest') ?? false;

    // 🌟 FIX 1: Async Gap Warning Solved
    if (!mounted) return;

    if (user != null) {
      print("✅ Auto-Login Success: Routing to MainScreen");
      Navigator.pushReplacement(
        context,
        // 🌟 FIX 2: Added the required 'userPackage' parameter
        MaterialPageRoute(
          builder: (context) => const MainScreen(userPackage: 'citizenship'),
        ),
      );
    } else if (isGuest) {
      print("✅ Guest Session Found: Routing to MainScreen (Free)");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(userPackage: 'free'),
        ),
      );
    } else {
      print("🔒 No Session Found: Routing to AuthWrapper");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
    // ==========================================================
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 120, color: Colors.blue.shade900),
              const SizedBox(height: 20),
              Text(
                "PrepCivic",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Réussissez votre naturalisation",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
