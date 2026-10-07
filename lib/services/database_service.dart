import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/question_model.dart';
import 'question_text.dart';

class DatabaseService {
  static List<QuestionModel> uniqueQuestions(List<QuestionModel> questions) {
    final seen = <String>{};
    return questions.where((q) {
      final text = q.questionText?.trim() ?? '';
      return text.isNotEmpty &&
          q.options.length >= 2 &&
          q.correctAnswerIndex >= 0 &&
          q.correctAnswerIndex < q.options.length &&
          seen.add(QuestionText.key(text));
    }).toList();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<QuestionModel> _parseQuestions(QuerySnapshot snapshot) {
    final questions = <QuestionModel>[];
    for (final doc in snapshot.docs) {
      try {
        questions.add(
          QuestionModel.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        );
      } catch (error) {
        debugPrint('Skipping malformed question ${doc.id}: $error');
      }
    }
    return uniqueQuestions(questions);
  }

  // 1. Fetch questions for a specific module (Used for Category Practice if needed)
  Future<List<QuestionModel>> getQuestionsForModule(String moduleName) async {
    try {
      print("Fetching questions for module: $moduleName");

      QuerySnapshot snapshot = await _db
          .collection('questions')
          .where('module', isEqualTo: moduleName)
          .get()
          .timeout(const Duration(seconds: 20));

      print("Found ${snapshot.docs.length} questions.");

      return _parseQuestions(snapshot);
    } catch (e) {
      print("Error fetching questions: $e");
      return [];
    }
  }

  // 2. Fetch ALL questions for the Mock Test (Mixed Pool)
  Future<List<QuestionModel>> getAllQuestions() async {
    // Changed name to match QuizScreen call
    try {
      print("🚀 Fetching all questions for mixed Mock Test...");

      // Fetch the entire collection from Firestore
      QuerySnapshot snapshot = await _db
          .collection('questions')
          .get()
          .timeout(const Duration(seconds: 20));

      if (snapshot.docs.isEmpty) {
        print("⚠️ Warning: Firestore 'questions' collection is empty!");
        return [];
      }

      print("✅ Total pool size from Cloud: ${snapshot.docs.length} questions.");

      return _parseQuestions(snapshot);
    } catch (e) {
      print("❌ Error fetching all questions: $e");
      return [];
    }
  }

  // 3. Save the score to the user's Firebase profile
  Future<void> saveQuizScore(
    String moduleName,
    int score,
    int totalQuestions,
  ) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Saves to: users -> [User ID] -> mock_scores -> [Random Doc ID]
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('mock_scores')
            .add({
              'module': moduleName,
              'score': score,
              'total': totalQuestions,
              'timestamp': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 15));
        print("✅ Score saved successfully to Firebase!");
      } else {
        print("❌ Error: No user logged in. Cannot save score.");
      }
    } catch (e) {
      print("❌ Error saving score: $e");
    }
  }
}
