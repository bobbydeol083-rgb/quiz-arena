/// A single quiz question.
///
/// The backend NEVER sends [answerIndex] (server-side grading); the bundled
/// offline bank includes it so the app can grade locally.
class Question {
  final String id;
  final String category;
  final String difficulty; // easy | medium | hard
  final String question;
  final List<String> options; // always 4
  final int? answerIndex; // null when fetched from the API
  final String? explanation;

  const Question({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    this.answerIndex,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List?)?.map((e) => '$e').toList() ?? [];
    while (opts.length < 4) {
      opts.add('—');
    }
    return Question(
      id: '${json['id']}',
      category: '${json['category'] ?? ''}',
      difficulty: '${json['difficulty'] ?? 'easy'}',
      question: '${json['question']}',
      options: opts.take(4).toList(),
      answerIndex: (json['answerIndex'] as num?)?.toInt(),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'difficulty': difficulty,
        'question': question,
        'options': options,
        if (answerIndex != null) 'answerIndex': answerIndex,
        if (explanation != null) 'explanation': explanation,
      };
}

/// One answered question, sent to POST /api/quiz/submit.
class AnswerPayload {
  final String questionId;
  final int selectedIndex; // -1 when unanswered / timed out
  final int timeMs;

  const AnswerPayload({
    required this.questionId,
    required this.selectedIndex,
    required this.timeMs,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'timeMs': timeMs,
      };
}

/// Questions fetched for a game, plus whether they came from the offline bank.
class QuestionPack {
  final List<Question> questions;
  final bool offline;

  const QuestionPack({required this.questions, required this.offline});
}
