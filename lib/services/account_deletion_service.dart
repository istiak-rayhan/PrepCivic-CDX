import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AccountDeletionService {
  /// Authentication must succeed before any destructive step starts.
  static Future<void> run({
    required Future<void> Function() authenticate,
    required Future<void> Function() removeData,
    required Future<void> Function() removeIdentity,
  }) async {
    await authenticate();
    await removeData();
    await removeIdentity();
  }

  static Future<void> delete(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw StateError('No email account is signed in');
    }
    final profile = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    await run(
      authenticate: () async {
        await user
            .reauthenticateWithCredential(
              EmailAuthProvider.credential(
                email: user.email!,
                password: password,
              ),
            )
            .timeout(const Duration(seconds: 20));
      },
      removeData: () async {
        // Deleting a Firestore parent document does not delete subcollections.
        // These are all user-owned subcollections referenced by this app.
        for (final name in ['progress', 'results', 'mock_scores']) {
          while (true) {
            final page = await profile
                .collection(name)
                .limit(400)
                .get()
                .timeout(const Duration(seconds: 20));
            if (page.docs.isEmpty) break;
            final batch = FirebaseFirestore.instance.batch();
            for (final doc in page.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit().timeout(const Duration(seconds: 20));
          }
        }
        await DatabaseHelper.instance.deleteLocalAccount(user.uid);
        await profile.delete().timeout(const Duration(seconds: 20));
      },
      removeIdentity: () async {
        await user.delete().timeout(const Duration(seconds: 20));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGuest', false);
      },
    );
  }
}
