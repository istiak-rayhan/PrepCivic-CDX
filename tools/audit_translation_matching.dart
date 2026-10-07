import 'dart:convert';
import 'dart:io';
import '../lib/services/question_csv.dart';
import '../lib/services/question_text.dart';

void main() {
  final report = <String, dynamic>{};
  for (final file in Directory('assets/fr').listSync().whereType<File>()) {
    if (!file.path.endsWith('.csv')) continue;
    final name = file.uri.pathSegments.last;
    final rows = QuestionCsv.parse(file.readAsStringSync());
    final category = <String, dynamic>{};
    for (final lang in ['bn', 'ar', 'ur', 'ps', 'en']) {
      final index = QuestionCsv.translationIndex(
        File('assets/$lang/$name').readAsStringSync(),
      );
      var currentKey = '';
      final missingQuestions = <String>[];
      var missingOptions = 0;
      for (final row in rows.skip(1)) {
        if (row.length < 2) continue;
        if (row[0] == 'question') {
          currentKey = QuestionText.sourceKey(row[1]);
          if (index[currentKey]?['question'] == null)
            missingQuestions.add(row[1]);
        } else if (row[0] == 'answer') {
          if (index[currentKey]?['answer:${QuestionText.sourceKey(row[1])}'] ==
              null)
            missingOptions++;
        }
      }
      category[lang] = {
        'missing_question_count': missingQuestions.length,
        'missing_options': missingOptions,
        'missing_questions': missingQuestions,
      };
    }
    report[name] = category;
  }
  File(
    'TRANSLATION_MATCH_AUDIT.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  for (final category in report.entries) {
    for (final lang in (category.value as Map<String, dynamic>).entries) {
      final data = lang.value as Map<String, dynamic>;
      if (data['missing_question_count'] != 0 || data['missing_options'] != 0) {
        print(
          '${category.key} ${lang.key}: ${data['missing_question_count']} questions, ${data['missing_options']} options missing',
        );
      }
    }
  }
}
