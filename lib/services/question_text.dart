/// Handles legacy bilingual CSV cells without repeating the French prompt.
class QuestionText {
  static int _outerParenthesis(String text) {
    if (!text.endsWith(')')) return -1;
    var depth = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      if (text[i] == ')') depth++;
      if (text[i] == '(' && --depth == 0) return i;
    }
    return -1;
  }

  static String french(String text) {
    return text
        .split('[')
        .first
        .trim()
        .replaceFirst(RegExp(r'\s*[।]?\s*\?\)\s*$'), '')
        .trim();
  }

  static String translation(String raw, String frenchText) {
    var text = raw.trim();
    if (text.isEmpty) return '';
    final bracket = text.indexOf('[');
    if (bracket >= 0 && text.endsWith(']')) {
      text = text.substring(bracket + 1, text.length - 1).trim();
    } else {
      final opening = _outerParenthesis(text);
      final cleanFrench = french(frenchText);
      if (opening >= cleanFrench.length &&
          cleanFrench.isNotEmpty &&
          text.startsWith(cleanFrench)) {
        text = text.substring(opening + 1, text.length - 1).trim();
        return text == cleanFrench ? '' : text;
      }
      // Arabic/Bengali/Urdu/Pashto files wrap the translation in parentheses.
      // Start at the first non-Latin character so punctuation differences in
      // the legacy French prefix cannot cause the whole prefix to be repeated.
      final script = RegExp(
        r'[\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff\u0980-\u09ff]',
      ).firstMatch(text);
      if (script != null && script.start > 0) {
        if (opening >= 0 && opening < script.start) {
          text = text.substring(opening + 1, text.length - 1).trim();
        }
      }
    }
    return text == frenchText.trim() ? '' : text;
  }

  static String key(String text) => french(
    text,
  ).toLowerCase().replaceAll('’', "'").replaceAll(RegExp(r'\s+'), ' ');

  /// Match bilingual CSV blocks by their French prefix, never by file row.
  static String sourceKey(String raw) {
    var text = raw.split('[').first;
    final script = RegExp(
      r'[\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff\u0980-\u09ff]',
    ).firstMatch(text);
    if (script != null) {
      final opening = _outerParenthesis(text.trim());
      text = text.substring(
        0,
        opening >= 0 && opening < script.start ? opening : script.start,
      );
    }
    final repeatedNumber = RegExp(r'^\s*(\d+)\s*\(\1\)\s*$').firstMatch(text);
    if (repeatedNumber != null) text = repeatedNumber.group(1)!;
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9à-ÿ]'), '');
  }
}
