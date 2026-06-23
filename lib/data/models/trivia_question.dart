import 'dart:math';

class TriviaQuestion {
  final String category;
  final String question;
  final String correctAnswer;
  final List<String> allAnswers;

  TriviaQuestion({
    required this.category,
    required this.question,
    required this.correctAnswer,
    required List<String> incorrectAnswers,
  }) : allAnswers = _shuffle([correctAnswer, ...incorrectAnswers]);

  static List<String> _shuffle(List<String> list) {
    final copy = List<String>.from(list);
    copy.shuffle(Random());
    return copy;
  }

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      category: _decodeHtml(json['category'] as String? ?? ''),
      question: _decodeHtml(json['question'] as String? ?? ''),
      correctAnswer: _decodeHtml(json['correct_answer'] as String? ?? ''),
      incorrectAnswers: (json['incorrect_answers'] as List<dynamic>)
          .map((e) => _decodeHtml(e as String))
          .toList(),
    );
  }

  static String _decodeHtml(String text) => text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&eacute;', 'é')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&aacute;', 'á');
}
