import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';
import 'bundled_quiz_bank.dart';
import 'database_helper.dart';
import 'database_service.dart';
import 'purchase_service.dart';

class QuizAccess {
  final String tier;
  final bool hasTakenFreeMock;
  final int bonusMocks;
  const QuizAccess(
    this.tier, {
    this.hasTakenFreeMock = false,
    this.bonusMocks = 0,
  });
  bool get needsPremium =>
      tier == 'free' && hasTakenFreeMock && bonusMocks <= 0;
}

abstract class QuizRepository {
  const QuizRepository();
  Future<QuizAccess> access(bool isMock);
  Future<List<QuestionModel>> questions(bool isMock, String topic);
  Future<void> record(
    bool isMock,
    String topic,
    QuizAccess access,
    int score,
    int total,
  );
}

class LocalQuizRepository extends QuizRepository {
  const LocalQuizRepository();
  static Future<List<QuestionModel>>? _bank;
  static String usedKey(String? uid) =>
      uid == null ? 'guest_free_mock_used' : 'mock_used_$uid';
  static String bonusKey(String uid) => 'mock_bonus_$uid';

  @override
  Future<QuizAccess> access(bool isMock) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final tier = await PurchaseService.currentTier();
    if (!isMock || tier != 'free') return QuizAccess(tier);
    final prefs = await SharedPreferences.getInstance();
    var used = prefs.getBool(usedKey(uid)) ?? false;
    var bonus = uid == null ? 0 : prefs.getInt(bonusKey(uid)) ?? 0;
    if (uid != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 5));
        final data = snapshot.data();
        used = used || data?['has_taken_free_mock'] == true;
        bonus = (data?['bonus_mocks'] as num?)?.toInt() ?? bonus;
        await prefs.setBool(usedKey(uid), used);
        await prefs.setInt(bonusKey(uid), bonus);
      } catch (error) {
        debugPrint(
          'Mock access: using account-scoped local attempt state: $error',
        );
      }
    }
    return QuizAccess(tier, hasTakenFreeMock: used, bonusMocks: bonus);
  }

  @override
  Future<List<QuestionModel>> questions(bool isMock, String topic) async {
    if (!isMock)
      return DatabaseService().getQuestionsForModule(topic.toLowerCase());
    try {
      // These are the exact six mock-bank CSVs already shipped in the app.
      // They do not depend on guest permission to the Firestore collection.
      final bank = await (_bank ??= BundledQuizBank.load());
      debugPrint('Mock bank: loaded ${bank.length} distinct bundled questions');
      return List.of(bank);
    } catch (error) {
      _bank = null;
      rethrow;
    }
  }

  @override
  Future<void> record(
    bool isMock,
    String topic,
    QuizAccess access,
    int score,
    int total,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    if (isMock && access.tier == 'free') {
      await prefs.setBool(usedKey(uid), true);
      if (uid != null && access.hasTakenFreeMock) {
        await prefs.setInt(
          bonusKey(uid),
          (access.bonusMocks - 1).clamp(0, 1000000),
        );
      }
    }
    await DatabaseHelper.instance.saveResult(
      score,
      total,
      isMock ? 'mock' : topic,
    );
    await DatabaseService().saveQuizScore(topic, score, total);
    if (uid != null && isMock && access.tier == 'free') {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(
              access.hasTakenFreeMock
                  ? {'bonus_mocks': FieldValue.increment(-1)}
                  : {'has_taken_free_mock': true},
              SetOptions(merge: true),
            )
            .timeout(const Duration(seconds: 10));
      } catch (error) {
        debugPrint('Mock attempt retained locally; cloud sync failed: $error');
      }
    }
  }
}
