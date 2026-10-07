import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkIfGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuest') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // SCENARIO 1: NOT LOGGED INTO FIREBASE
        if (!authSnapshot.hasData) {
          return FutureBuilder<bool>(
            future: _checkIfGuest(),
            builder: (context, guestSnapshot) {
              if (guestSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // If they clicked "Free" previously, send to app as free user
              if (guestSnapshot.data == true) {
                return const MainScreen(userPackage: 'free');
              }
              // Otherwise, start from the very beginning (Intro/Splash)
              return const OnboardingScreen();
            },
          );
        }

        // Account profiles are presentation data; RevenueCat determines access.
        return FutureBuilder<String>(
          key: ValueKey(authSnapshot.data!.uid),
          future: PurchaseService.currentTier(),
          builder: (context, tierSnapshot) {
            if (tierSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return MainScreen(userPackage: tierSnapshot.data ?? 'free');
          },
        );
      },
    );
  }
}
