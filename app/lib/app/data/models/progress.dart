/// Long-lived local gameplay stats. Feeds BadgeService unlock rules and
/// the profile stats tab. Persisted in GetStorage by ProgressRepository.
class PlayerProgress {
  final int totalQuizzes;
  final int wins;
  final int totalAnswered;
  final int totalCorrect;
  final int bestStreak;
  final int perfectGames;
  final int fastestAnswerMs;
  final int marathonBest;
  final int duelsWon;
  final int dailyStreak;
  final String? lastDailyDate; // yyyy-MM-dd
  final Set<String> categoriesPlayed;

  const PlayerProgress({
    this.totalQuizzes = 0,
    this.wins = 0,
    this.totalAnswered = 0,
    this.totalCorrect = 0,
    this.bestStreak = 0,
    this.perfectGames = 0,
    this.fastestAnswerMs = 0,
    this.marathonBest = 0,
    this.duelsWon = 0,
    this.dailyStreak = 0,
    this.lastDailyDate,
    this.categoriesPlayed = const {},
  });

  factory PlayerProgress.fromJson(Map<String, dynamic> json) => PlayerProgress(
        totalQuizzes: (json['totalQuizzes'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        totalAnswered: (json['totalAnswered'] as num?)?.toInt() ?? 0,
        totalCorrect: (json['totalCorrect'] as num?)?.toInt() ?? 0,
        bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
        perfectGames: (json['perfectGames'] as num?)?.toInt() ?? 0,
        fastestAnswerMs: (json['fastestAnswerMs'] as num?)?.toInt() ?? 0,
        marathonBest: (json['marathonBest'] as num?)?.toInt() ?? 0,
        duelsWon: (json['duelsWon'] as num?)?.toInt() ?? 0,
        dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
        lastDailyDate: json['lastDailyDate'] as String?,
        categoriesPlayed:
            (json['categoriesPlayed'] as List?)?.map((e) => '$e').toSet() ??
                const {},
      );

  Map<String, dynamic> toJson() => {
        'totalQuizzes': totalQuizzes,
        'wins': wins,
        'totalAnswered': totalAnswered,
        'totalCorrect': totalCorrect,
        'bestStreak': bestStreak,
        'perfectGames': perfectGames,
        'fastestAnswerMs': fastestAnswerMs,
        'marathonBest': marathonBest,
        'duelsWon': duelsWon,
        'dailyStreak': dailyStreak,
        'lastDailyDate': lastDailyDate,
        'categoriesPlayed': categoriesPlayed.toList(),
      };

  double get accuracy =>
      totalAnswered == 0 ? 0 : totalCorrect / totalAnswered;

  PlayerProgress copyWith({
    int? totalQuizzes,
    int? wins,
    int? totalAnswered,
    int? totalCorrect,
    int? bestStreak,
    int? perfectGames,
    int? fastestAnswerMs,
    int? marathonBest,
    int? duelsWon,
    int? dailyStreak,
    String? lastDailyDate,
    Set<String>? categoriesPlayed,
  }) =>
      PlayerProgress(
        totalQuizzes: totalQuizzes ?? this.totalQuizzes,
        wins: wins ?? this.wins,
        totalAnswered: totalAnswered ?? this.totalAnswered,
        bestStreak: bestStreak ?? this.bestStreak,
        perfectGames: perfectGames ?? this.perfectGames,
        fastestAnswerMs: fastestAnswerMs ?? this.fastestAnswerMs,
        marathonBest: marathonBest ?? this.marathonBest,
        duelsWon: duelsWon ?? this.duelsWon,
        dailyStreak: dailyStreak ?? this.dailyStreak,
        lastDailyDate: lastDailyDate ?? this.lastDailyDate,
        categoriesPlayed: categoriesPlayed ?? this.categoriesPlayed,
      );
}
