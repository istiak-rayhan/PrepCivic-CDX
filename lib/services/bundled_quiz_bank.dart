import 'package:flutter/services.dart';
import '../models/question_model.dart';
import 'database_service.dart';
import 'question_csv.dart';

class BundledQuizBank {
  static const files = {
    'republique_french_only.csv': 'republique',
    'histoire_french_only.csv': 'histoire',
    'institutions_french_only.csv': 'institutions',
    'situations_french_only.csv': 'situations',
    'societe_french_only.csv': 'societe',
    'droits_devoirs_final_clean.csv': 'valeurs',
  };

  static List<QuestionModel> parse(String csv, String filename, String module) {
    final rows = QuestionCsv.parse(csv);
    final questions = <QuestionModel>[];
    String? text;
    String? level;
    var rowId = 0;
    var options = <String>[];
    var correct = <int>[];
    void finish() {
      if (text != null && options.length >= 2 && correct.length == 1) {
        questions.add(
          QuestionModel(
            id: '$filename:$rowId',
            questionText: text,
            options: List.of(options),
            correctAnswerIndex: correct.single,
            level: level,
            module: module,
          ),
        );
      }
    }

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;
      final type = row[0].trim().toLowerCase();
      if (type == 'question') {
        finish();
        text = row[1].trim();
        level = row.length > 4 ? row[4] : null;
        rowId = i;
        options = [];
        correct = [];
      } else if (type == 'answer' && text != null) {
        if (row.length > 3 &&
            ['1', '1.0', 'true'].contains(row[3].trim().toLowerCase())) {
          correct.add(options.length);
        }
        options.add(row[1].trim());
      }
    }
    finish();
    return DatabaseService.uniqueQuestions(questions);
  }

  static Future<List<QuestionModel>> load({AssetBundle? bundle}) async {
    final questions = <QuestionModel>[];
    for (final file in files.entries) {
      final csv = await (bundle ?? rootBundle).loadString(
        'assets/mock_test/${file.key}',
      );
      questions.addAll(parse(csv, file.key, file.value));
    }
    return DatabaseService.uniqueQuestions(questions);
  }
}
