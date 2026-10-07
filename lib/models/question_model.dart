class QuestionModel {
  final String id;
  final String? questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String? level;
  final String? module;

  QuestionModel({
    required this.id,
    this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.level,
    this.module,
  });

  factory QuestionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return QuestionModel(
      id: id,
      questionText:
          data['questionText'] ?? data['text_fr'] ?? data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex:
          data['correctAnswerIndex'] ??
          data['correct_option_index'] ??
          data['correctOptionIndex'] ??
          0,
      level: data['level'], // Captures 'lvl1', 'lvl2', etc. from Firebase
      module: data['module'],
    );
  }
}
