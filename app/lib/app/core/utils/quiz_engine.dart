import '../../data/models/question.dart';
import '../../data/models/result.dart';
import 'level_config.dart';

/// Pure scoring/grading logic shared by online + offline flows.
///
/// Scoring per correct answer:
///   base 100 x difficulty multiplier (easy 1.0 / medium 1.5 / hard 2.0)
///   + speed bonus up to +50 (faster = more)
///   + streak bonus +10 per current streak, capped at +100
///
/// XP earned = score ~/ 10. Coins = correct answers x 5 (+25 win bonus).
class QuizEngine {
  QuizEngine._();

  static double difficultyMultiplier(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'medium':
        return 1.5;
      case 'hard':
        return 2.0;
      case 'easy':
      default:
        return 1.0;
    }
  }

  static int scoreForAnswer({
    required bool correct,
    required int timeMs,
    required int streak,
    required String difficulty,
    int questionTimeLimitMs = 20000,
  }) {
    if (!correct) return 0;
    final base = 100 * difficultyMultiplier(difficulty);
    final speedRatio =
        (1.0 - (timeMs / questionTimeLimitMs)).clamp(0.0, 1.0);
    final speedBonus = (50 * speedRatio).round();
    final streakBonus = (10 * streak).clamp(0, 100);
    return base.round() + speedBonus + streakBonus;
  }

  /// Grades a finished quiz locally (offline fallback path).
  static QuizSubmitResult gradeOffline({
    required List<Question> questions,
    required List<AnswerPayload> answers,
    required String mode,
    String? categoryId,
    String? difficulty,
    required int previousXp,
    int previousStreak = 0,
  }) {
    final byId = {for (final q in questions) q.id: q};
    var score = 0;
    var correct = 0;
    var streak = 0;
    var bestStreak = 0;
    var fastestMs = 0;

    for (final a in answers) {
      final q = byId[a.questionId];
      if (q == null) continue;
      final isCorrect =
          q.answerIndex != null && a.selectedIndex == q.answerIndex;
      if (isCorrect) {
        correct++;
        streak++;
        if (streak > bestStreak) bestStreak = streak;
        if (fastestMs == 0 || a.timeMs < fastestMs) fastestMs = a.timeMs;
        score += scoreForAnswer(
          correct: true,
          timeMs: a.timeMs,
          streak: streak,
          difficulty: q.difficulty,
        );
      } else {
        streak = 0;
      }
    }

    final total = questions.length;
    final xpEarned = score ~/ 10;
    final coinsEarned = correct * 5 + (correct == total && total > 0 ? 25 : 0);
    final newXp = previousXp + xpEarned;
    final leveledUp =
        LevelConfig.levelForXp(newXp) > LevelConfig.levelForXp(previousXp);
    final newStreak = correct == total && total > 0 ? previousStreak + 1 : 0;

    return QuizSubmitResult(
      score: score,
      correct: correct,
      total: total,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      newBadges: const [],
      levelUp: leveledUp,
      newLevel: LevelConfig.levelForXp(newXp),
      streak: newStreak,
      bestStreak: bestStreak,
      fastestAnswerMs: fastestMs,
      accuracy: total == 0 ? 0 : correct / total,
      mode: mode,
      categoryId: categoryId,
      difficulty: difficulty,
    );
  }
}
