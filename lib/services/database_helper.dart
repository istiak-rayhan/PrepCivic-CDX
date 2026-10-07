import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'question_csv.dart';
import 'question_text.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static final _databases = <String, Database>{};
  static final _opening = <String, Future<Database>>{};

  DatabaseHelper._init();

  Future<Database> get database async {
    return _databaseFor(FirebaseAuth.instance.currentUser?.uid);
  }

  // A bounded digest avoids separators and filesystem limits for long UIDs.
  static String filenameFor(String? uid) => uid == null
      ? 'prep_civic_guest_v2.db'
      : 'prep_civic_user_${sha256.convert(utf8.encode(uid))}.db';

  Future<Database> _databaseFor(String? uid) async {
    final name = filenameFor(uid);
    if (_databases[name] != null) return _databases[name]!;
    final opening = _opening[name] ??= _initDatabase(name);
    try {
      return _databases[name] = await opening;
    } finally {
      _opening.remove(name);
    }
  }

  Future<void> deleteLocalAccount(String uid) async {
    final name = filenameFor(uid);
    final pending = _opening[name];
    if (pending != null) await pending;
    await _databases.remove(name)?.close();
    await deleteDatabase(join(await getDatabasesPath(), name));
  }

  Future<Database> _initDatabase(String name) async {
    final dbPath = await getDatabasesPath();
    // The original, unattributed prep_civic_v10.db is retained untouched.
    // It cannot safely be assigned to whichever account signs in next.
    final path = join(dbPath, name);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.delete('options');
          await _seedDatabase(db);
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash_id TEXT UNIQUE,
        category TEXT,
        level TEXT,
        text_fr TEXT,
        text_bn TEXT,
        text_ar TEXT,
        text_ur TEXT,
        text_ps TEXT,
        text_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_hash TEXT,
        text_fr TEXT,
        text_bn TEXT,
        text_ar TEXT,
        text_ur TEXT,
        text_ps TEXT,
        text_en TEXT,
        is_correct INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        score INTEGER,
        total_questions INTEGER,
        test_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_hash TEXT UNIQUE,
        times_seen INTEGER DEFAULT 0,
        times_correct INTEGER DEFAULT 0,
        is_mastered INTEGER DEFAULT 0
      )
    ''');

    await _seedDatabase(db);
  }

  // 🌟 THE CROSS-DEVICE SYNC ENGINE 🌟
  Future<void> syncFromFirebase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = await _databaseFor(user.uid);

    try {
      var progressSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .get()
          .timeout(const Duration(seconds: 10));

      for (var doc in progressSnap.docs) {
        var data = doc.data();
        await db.rawUpdate(
          '''UPDATE user_progress SET
          times_seen = MAX(times_seen, ?),
          times_correct = MAX(times_correct, ?),
          is_mastered = MAX(is_mastered, ?)
          WHERE question_hash = ?''',
          [
            data['times_seen'] ?? 0,
            data['times_correct'] ?? 0,
            data['is_mastered'] ?? 0,
            doc.id,
          ],
        );
      }

      var resultsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('results')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      if (resultsSnap.docs.isNotEmpty) {
        for (var doc in resultsSnap.docs) {
          var data = doc.data();
          final existing = await db.query(
            'results',
            where:
                'date = ? AND score = ? AND total_questions = ? AND test_type = ?',
            whereArgs: [
              data['date'],
              data['score'],
              data['total_questions'],
              data['test_type'],
            ],
          );
          if (existing.isNotEmpty) continue;
          await db.insert('results', {
            'date': data['date'],
            'score': data['score'],
            'total_questions': data['total_questions'],
            'test_type': data['test_type'],
          });
        }
      }
    } catch (e) {
      print("Firebase Sync Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getQuestionsByCategory(
    String category,
    String userPackage,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'category = ?',
      whereArgs: [category],
    );

    List<Map<String, dynamic>> fullData = [];
    for (var q in result) {
      var qMap = Map<String, dynamic>.from(q);
      qMap['options'] = await db.query(
        'options',
        where: 'question_hash = ?',
        whereArgs: [q['hash_id']],
      );
      fullData.add(qMap);
    }
    return fullData;
  }

  Future<List<Map<String, dynamic>>> getSmartTenQuestions(
    String category, {
    Set<String> excludeHashes = const {},
  }) async {
    final db = await instance.database;
    final exclusion = excludeHashes.isEmpty
        ? ''
        : 'AND q.hash_id NOT IN (${List.filled(excludeHashes.length, '?').join(',')})';
    Future<List<Map<String, Object?>>> select(
      String clause,
      List<Object?> args,
    ) => db.rawQuery('''SELECT q.* FROM questions q
          JOIN user_progress p ON q.hash_id = p.question_hash
          WHERE q.category = ? AND p.is_mastered = 0
          AND q.id IN (SELECT MIN(id) FROM questions WHERE category = ?
            GROUP BY LOWER(TRIM(text_fr)))
          $clause
          ORDER BY p.times_seen ASC, RANDOM() LIMIT 10''', args);
    var result = await select(exclusion, [
      category,
      category,
      ...excludeHashes,
    ]);
    // Once a full pass is complete, allow intentional spaced repetition.
    if (result.isEmpty && excludeHashes.isNotEmpty) {
      result = await select('', [category, category]);
    }
    final fullData = <Map<String, dynamic>>[];
    for (final q in result) {
      final qMap = Map<String, dynamic>.from(q);
      qMap['options'] = await db.query(
        'options',
        where: 'question_hash = ?',
        whereArgs: [q['hash_id']],
      );
      fullData.add(qMap);
    }
    return fullData;
  }

  Future<List<Map<String, dynamic>>> getFixedTenQuestions(
    String category,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where:
          'category = ? AND id IN (SELECT MIN(id) FROM questions WHERE category = ? GROUP BY LOWER(TRIM(text_fr)))',
      whereArgs: [category, category],
      orderBy: 'id ASC',
      limit: 10,
    );

    List<Map<String, dynamic>> fullData = [];
    for (var q in result) {
      var qMap = Map<String, dynamic>.from(q);
      qMap['options'] = await db.query(
        'options',
        where: 'question_hash = ?',
        whereArgs: [q['hash_id']],
      );
      fullData.add(qMap);
    }
    return fullData;
  }

  Future<void> updateQuestionProgress(String hashId, bool isCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    final db = await _databaseFor(user?.uid);
    final progress = await db.transaction<Map<String, int>?>((txn) async {
      final rows = await txn.query(
        'user_progress',
        where: 'question_hash = ?',
        whereArgs: [hashId],
      );
      if (rows.isEmpty) return null;
      final seen = (rows.first['times_seen'] as int) + 1;
      final correct =
          (rows.first['times_correct'] as int) + (isCorrect ? 1 : 0);
      final values = {
        'times_seen': seen,
        'times_correct': correct,
        'is_mastered': correct >= 3 ? 1 : 0,
      };
      await txn.update(
        'user_progress',
        values,
        where: 'question_hash = ?',
        whereArgs: [hashId],
      );
      return values;
    });
    if (progress != null) {
      final seen = progress['times_seen']!;
      final correct = progress['times_correct']!;
      final mastered = progress['is_mastered']!;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('progress')
              .doc(hashId)
              .set({
                'times_seen': seen,
                'times_correct': correct,
                'is_mastered': mastered,
                'last_updated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(const Duration(seconds: 10));
        } catch (error) {
          debugPrint('Progress saved locally; cloud sync failed: $error');
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryMasteryStats() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        q.category, 
        COUNT(q.id) as total_questions, 
        SUM(p.is_mastered) as mastered_questions
      FROM questions q
      JOIN user_progress p ON q.hash_id = p.question_hash
      WHERE q.id IN (
        SELECT MIN(id) FROM questions GROUP BY category, LOWER(TRIM(text_fr))
      )
      GROUP BY q.category
    ''');
    return result;
  }

  Future<int> saveResult(int score, int total, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    final db = await _databaseFor(user?.uid);
    String dateStr = DateTime.now().toIso8601String();

    int localId = await db.insert('results', {
      'date': dateStr,
      'score': score,
      'total_questions': total,
      'test_type': type,
    });

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('results')
            .add({
              'date': dateStr,
              'score': score,
              'total_questions': total,
              'test_type': type,
            })
            .timeout(const Duration(seconds: 10));
      } catch (error) {
        debugPrint('Result saved locally; cloud sync failed: $error');
      }
    }

    return localId;
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await instance.database;
    return await db.query('results', orderBy: 'id DESC');
  }

  // --- SEEDER ---
  Future<void> _seedDatabase(Database db) async {
    final categories = {
      'q_republic.csv': 'La République',
      'q_history.csv': 'Histoire',
      'q_values.csv': 'Valeurs',
      'q_situations.csv': 'Situations',
      'q_society.csv': 'Société',
      'q_institutions.csv': 'Institutions',
    };

    // 🌟 ADDED 'en' TO THE PARSING QUEUE
    final languages = ['ar', 'bn', 'ps', 'ur', 'en'];

    for (var entry in categories.entries) {
      try {
        final frData = await rootBundle.loadString('assets/fr/${entry.key}');
        List<List<String>> frRows = QuestionCsv.parse(frData);

        final translationsByLanguage =
            <String, Map<String, Map<String, String>>>{};
        for (String lang in languages) {
          try {
            final langData = await rootBundle.loadString(
              'assets/$lang/${entry.key}',
            );
            translationsByLanguage[lang] = QuestionCsv.translationIndex(
              langData,
            );
          } catch (e) {
            print("⚠️ Translation missing for $lang in ${entry.key}");
          }
        }

        String currentQuestionHash = "";
        String currentSourceKey = "";

        for (var i = 1; i < frRows.length; i++) {
          var row = frRows[i];
          if (row.length < 2) continue;
          String type = row[0].toLowerCase();

          if (type.contains('question')) {
            currentSourceKey = QuestionText.sourceKey(row[1]);
          }
          final translations = <String, String>{};
          for (final lang in languages) {
            final block = translationsByLanguage[lang]?[currentSourceKey];
            final key = type.contains('question')
                ? 'question'
                : 'answer:${QuestionText.sourceKey(row[1])}';
            final translated = block?[key];
            if (translated != null) translations['text_$lang'] = translated;
          }

          if (type.contains('question')) {
            currentQuestionHash = "${entry.key}_$i";

            Map<String, dynamic> insertData = {
              'hash_id': currentQuestionHash,
              'category': entry.value,
              'level': row.length > 4 ? row[4] : 'lvl1',
              'text_fr': QuestionText.french(row[1]),
            };
            for (final lang in languages) {
              insertData['text_$lang'] = translations['text_$lang'];
            }

            final existing = await db.query(
              'questions',
              where: 'hash_id = ?',
              whereArgs: [currentQuestionHash],
            );
            if (existing.isEmpty) {
              await db.insert('questions', insertData);
            } else {
              await db.update(
                'questions',
                insertData,
                where: 'hash_id = ?',
                whereArgs: [currentQuestionHash],
              );
            }
            await db.insert('user_progress', {
              'question_hash': currentQuestionHash,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          } else if (type.contains('answer')) {
            String rawCorr = row.length > 3 ? row[3].toLowerCase() : '0';
            int isCorr =
                (rawCorr == '1' || rawCorr == '1.0' || rawCorr == 'true')
                ? 1
                : 0;

            Map<String, dynamic> optInsertData = {
              'question_hash': currentQuestionHash,
              'text_fr': QuestionText.french(row[1]),
              'is_correct': isCorr,
            };
            optInsertData.addAll(translations);

            await db.insert('options', optInsertData);
          }
        }
      } catch (e) {
        debugPrint("Error seeding ${entry.key}: $e");
        rethrow;
      }
    }
  }
}
