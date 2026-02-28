class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'correctIndex': correctIndex,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] as int,
    );
  }
}
