import 'package:csv/csv.dart';
import 'question_text.dart';

class QuestionCsv {
  static List<List<String>> parse(String text) =>
      const CsvToListConverter(shouldParseNumbers: false)
          .convert(
            text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
            eol: '\n',
          )
          .map((row) => row.map((cell) => cell.toString().trim()).toList())
          .where((row) => row.isNotEmpty && row.any((cell) => cell.isNotEmpty))
          .toList();

  /// Some translation files omit blocks. Matching by row would attach every
  /// subsequent translation to a different question. Index by content instead.
  static Map<String, Map<String, String>> translationIndex(String csv) {
    final result = <String, Map<String, String>>{};
    Map<String, String>? current;
    for (final row in parse(csv).skip(1)) {
      if (row.length < 2) continue;
      final type = row[0].toLowerCase();
      if (type == 'question') {
        final key = QuestionText.sourceKey(row[1]);
        current = result.putIfAbsent(key, () => {});
        current['question'] = row[1];
      } else if (type == 'answer' && current != null) {
        current['answer:${QuestionText.sourceKey(row[1])}'] = row[1];
      }
    }
    return result;
  }
}
