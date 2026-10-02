/// Result of POST /api/quiz/submit (or offline grading).
class QuizSubmitResult {
  final int score;
  final int correct;
  final int total;
  final int xpEarned;
  final int coinsEarned;
  final List<String> newBadges; // badge ids unlocked by this game
  final bool levelUp;
  final int newLevel;
  final int streak; // daily/quiz win streak after this game
  final int bestStreak; // best answer streak inside this game
  final int fastestAnswerMs;
  final double accuracy; // 0.0 - 1.0
  final String mode;
  final String? categoryId;
  final String? difficulty;

  /// Duel extras (set locally after grading — not part of the API payload).
  final bool? duelWon;
  final String? opponentName;
  final int? opponentScore;

  const QuizSubmitResult({
    required this.score,
    required this.correct,
    required this.total,
    required this.xpEarned,
    required this.coinsEarned,
    required this.newBadges,
    required this.levelUp,
    required this.newLevel,
    required this.streak,
    required this.bestStreak,
    required this.fastestAnswerMs,
    required this.accuracy,
    required this.mode,
    this.categoryId,
    this.difficulty,
    this.duelWon,
    this.opponentName,
    this.opponentScore,
  });

  factory QuizSubmitResult.fromJson(Map<String, dynamic> json) =>
      QuizSubmitResult(
        score: (json['score'] as num?)?.toInt() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
        coinsEarned: (json['coinsEarned'] as num?)?.toInt() ?? 0,
        newBadges: (json['newBadges'] as List?)
                ?.map((e) => '$e')
                .toList() ??
            const [],
        levelUp: json['levelUp'] == true,
        newLevel: (json['newLevel'] as num?)?.toInt() ?? 1,
        streak: _streakCount(json['streak']),
        bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
        fastestAnswerMs: (json['fastestAnswerMs'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        mode: '${json['mode'] ?? 'solo'}',
        categoryId: json['categoryId'] as String?,
        difficulty: json['difficulty'] as String?,
      );

  bool get isWin => total > 0 && accuracy >= 0.6;
  bool get isPerfect => total > 0 && correct == total;

  QuizSubmitResult copyWith({
    int? score,
    int? correct,
    int? total,
    int? xpEarned,
    int? coinsEarned,
    List<String>? newBadges,
    bool? levelUp,
    int? newLevel,
    int? streak,
    int? bestStreak,
    int? fastestAnswerMs,
    double? accuracy,
    String? mode,
    String? categoryId,
    String? difficulty,
    bool? duelWon,
    String? opponentName,
    int? opponentScore,
  }) =>
      QuizSubmitResult(
        score: score ?? this.score,
        correct: correct ?? this.correct,
        total: total ?? this.total,
        xpEarned: xpEarned ?? this.xpEarned,
        coinsEarned: coinsEarned ?? this.coinsEarned,
        newBadges: newBadges ?? this.newBadges,
        levelUp: levelUp ?? this.levelUp,
        newLevel: newLevel ?? this.newLevel,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        fastestAnswerMs: fastestAnswerMs ?? this.fastestAnswerMs,
        accuracy: accuracy ?? this.accuracy,
        mode: mode ?? this.mode,
        categoryId: categoryId ?? this.categoryId,
        difficulty: difficulty ?? this.difficulty,
        duelWon: duelWon ?? this.duelWon,
        opponentName: opponentName ?? this.opponentName,
        opponentScore: opponentScore ?? this.opponentScore,
      );
}

/// The API returns streak as `{count, lastPlayedAt}`; accept a plain number
/// too so offline/alternate payloads keep working.
int _streakCount(dynamic v) {
  if (v is num) return v.toInt();
  if (v is Map) return (v['count'] as num?)?.toInt() ?? 0;
  return 0;
}
