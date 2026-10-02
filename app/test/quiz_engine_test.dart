import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_arena/app/core/utils/quiz_engine.dart';
import 'package:quiz_arena/app/data/models/models.dart';

Question _q(String id, String difficulty, int answer) => Question(
      id: id,
      category: 'science',
      difficulty: difficulty,
      question: 'Question $id?',
      options: const ['A', 'B', 'C', 'D'],
      answerIndex: answer,
    );

void main() {
  group('QuizEngine.scoreForAnswer', () {
    test('wrong answer scores 0', () {
      expect(
        QuizEngine.scoreForAnswer(
            correct: false, timeMs: 1000, streak: 5, difficulty: 'hard'),
        0,
      );
    });

    test('harder difficulty scores more than easy', () {
      final easy = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 10000, streak: 0, difficulty: 'easy');
      final hard = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 10000, streak: 0, difficulty: 'hard');
      expect(hard, greaterThan(easy));
      expect(easy, greaterThanOrEqualTo(100)); // base 100 + speed bonus
    });

    test('faster answers earn a bigger speed bonus', () {
      final fast = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 1000, streak: 0, difficulty: 'easy');
      final slow = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 19000, streak: 0, difficulty: 'easy');
      expect(fast, greaterThan(slow));
    });

    test('streak bonus grows and caps at +100', () {
      final s1 = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 10000, streak: 1, difficulty: 'easy');
      final s5 = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 10000, streak: 5, difficulty: 'easy');
      final s50 = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 10000, streak: 50, difficulty: 'easy');
      final s500 = QuizEngine.scoreForAnswer(
          correct: true, timeMs: 10000, streak: 500, difficulty: 'easy');
      expect(s5, greaterThan(s1));
      expect(s50, greaterThan(s5));
      expect(s500, s50); // capped
    });
  });

  group('QuizEngine.gradeOffline', () {
    final questions = [
      _q('q1', 'easy', 0),
      _q('q2', 'medium', 2),
      _q('q3', 'hard', 1),
    ];

    test('grades 2/3 with correct math', () {
      final answers = [
        const AnswerPayload(questionId: 'q1', selectedIndex: 0, timeMs: 2000),
        const AnswerPayload(questionId: 'q2', selectedIndex: 2, timeMs: 3000),
        const AnswerPayload(questionId: 'q3', selectedIndex: 0, timeMs: 4000),
      ];
      final r = QuizEngine.gradeOffline(
        questions: questions,
        answers: answers,
        mode: 'solo',
        categoryId: 'science',
        difficulty: 'easy',
        previousXp: 50,
      );
      expect(r.correct, 2);
      expect(r.total, 3);
      expect(r.score, greaterThan(0));
      expect(r.xpEarned, r.score ~/ 10);
      expect(r.accuracy, closeTo(2 / 3, 0.001));
      expect(r.bestStreak, 2);
      expect(r.fastestAnswerMs, 2000);
      expect(r.levelUp, isFalse); // 50 xp + small gain stays level 1
    });

    test('perfect game earns the win bonus coins and streak', () {
      final answers = [
        const AnswerPayload(questionId: 'q1', selectedIndex: 0, timeMs: 1000),
        const AnswerPayload(questionId: 'q2', selectedIndex: 2, timeMs: 1000),
        const AnswerPayload(questionId: 'q3', selectedIndex: 1, timeMs: 1000),
      ];
      final r = QuizEngine.gradeOffline(
        questions: questions,
        answers: answers,
        mode: 'solo',
        previousXp: 0,
        previousStreak: 2,
      );
      expect(r.isPerfect, true);
      expect(r.coinsEarned, 3 * 5 + 25);
      expect(r.streak, 3); // previousStreak + 1
    });

    test('level-up is detected across the threshold', () {
      final answers = [
        const AnswerPayload(questionId: 'q1', selectedIndex: 0, timeMs: 500),
      ];
      final r = QuizEngine.gradeOffline(
        questions: questions.take(1).toList(),
        answers: answers,
        mode: 'solo',
        previousXp: 95, // 5 xp away from level 2
      );
      expect(r.levelUp, true);
      expect(r.newLevel, 2);
    });

    test('unanswered questions score nothing and break streaks', () {
      final answers = [
        const AnswerPayload(questionId: 'q1', selectedIndex: -1, timeMs: 20000),
      ];
      final r = QuizEngine.gradeOffline(
        questions: questions.take(1).toList(),
        answers: answers,
        mode: 'solo',
        previousXp: 0,
      );
      expect(r.correct, 0);
      expect(r.score, 0);
      expect(r.bestStreak, 0);
    });
  });
}
