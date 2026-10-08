import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/session_repository.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  final SessionRepository sessions;
  final Widget Function(BuildContext, String)? mainBuilder;
  final WidgetBuilder? onboardingBuilder;
  final WidgetBuilder? loginBuilder;
  const AuthWrapper({
    super.key,
    this.sessions = const FirebaseSessionRepository(),
    this.mainBuilder,
    this.onboardingBuilder,
    this.loginBuilder,
  });
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

enum _Destination { loading, onboarding, login, main, error }

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<SessionIdentity?>? _subscription;
  SessionIdentity? _identity;
  int _generation = 0;
  String _tier = 'free';
  _Destination _destination = _Destination.loading;

  @override
  void initState() {
    super.initState();
    _subscription = widget.sessions.identities.listen(
      (identity) {
        _identity = identity;
        _resolve(identity);
      },
      onError: (Object error) {
        _generation++;
        if (mounted) setState(() => _destination = _Destination.error);
      },
    );
  }

  Future<void> _resolve(SessionIdentity? identity) async {
    final generation = ++_generation;
    setState(() => _destination = _Destination.loading);
    try {
      var destination = _Destination.main;
      var tier = 'free';
      if (identity != null && !identity.emailVerified) {
        destination = _Destination.login;
      } else if (identity == null && !await widget.sessions.isGuest()) {
        destination = _Destination.onboarding;
      } else {
        // Both returning accounts and guests can own RevenueCat purchases.
        tier = await widget.sessions.tier();
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _tier = tier;
        _destination = destination;
      });
    } catch (error) {
      debugPrint('Session restoration failed: $error');
      if (mounted && generation == _generation) {
        setState(() => _destination = _Destination.error);
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_destination) {
    _Destination.loading => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    _Destination.onboarding =>
      widget.onboardingBuilder?.call(context) ?? const OnboardingScreen(),
    _Destination.login =>
      widget.loginBuilder?.call(context) ?? const LoginScreen(),
    _Destination.main =>
      widget.mainBuilder?.call(context, _tier) ??
          MainScreen(userPackage: _tier),
    _Destination.error => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('session_load_error'.tr(), textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _resolve(_identity),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    ),
  };
}
