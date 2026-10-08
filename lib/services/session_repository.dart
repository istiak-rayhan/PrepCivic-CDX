import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'purchase_service.dart';

class SessionIdentity {
  final String uid;
  final bool emailVerified;
  const SessionIdentity(this.uid, {required this.emailVerified});
}

abstract class SessionRepository {
  const SessionRepository();
  Stream<SessionIdentity?> get identities;
  Future<bool> isGuest();
  Future<String> tier();
}

class FirebaseSessionRepository extends SessionRepository {
  const FirebaseSessionRepository();
  @override
  Stream<SessionIdentity?> get identities =>
      FirebaseAuth.instance.authStateChanges().map(
        (user) => user == null
            ? null
            : SessionIdentity(user.uid, emailVerified: user.emailVerified),
      );
  @override
  Future<bool> isGuest() async =>
      (await SharedPreferences.getInstance()).getBool('isGuest') ?? false;
  @override
  Future<String> tier() => PurchaseService.currentTier();
}
