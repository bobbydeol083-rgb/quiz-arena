import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/utils/badge_service.dart';
import '../../core/values/app_config.dart';
import '../models/models.dart';

/// Persists [PlayerProgress], records finished games, and evaluates badge
/// unlocks. Works fully offline — everything lives in GetStorage.
class ProgressRepository extends GetxService {
  final GetStorage box;
  final BadgeService badges;

  final Rx<PlayerProgress> progress = const PlayerProgress().obs;

  ProgressRepository({required this.badges, GetStorage? box})
      : box = box ?? GetStorage();

  @override
  void onInit() {
    super.onInit();
    final stored = box.read<Map>(AppConfig.kProgress);
    if (stored != null) {
      progress.value =
          PlayerProgress.fromJson(Map<String, dynamic>.from(stored));
    }
  }

  Future<void> _save() =>
      box.write(AppConfig.kProgress, progress.value.toJson());

  /// Record a finished game. Returns the badge ids unlocked by this game.
  Future<List<String>> recordGame(QuizSubmitResult result) async {
    final p = progress.value;
    final categories = Set<String>.from(p.categoriesPlayed);
    if (result.categoryId != null && result.categoryId!.isNotEmpty) {
      categories.add(result.categoryId!);
    }

    var updated = p.copyWith(
      totalQuizzes: p.totalQuizzes + 1,
      wins: p.wins + (result.isWin ? 1 : 0),
      totalAnswered: p.totalAnswered + result.total,
      totalCorrect: p.totalCorrect + result.correct,
      bestStreak: result.bestStreak > p.bestStreak
          ? result.bestStreak
          : p.bestStreak,
      perfectGames:
          p.perfectGames + (result.isPerfect && result.total >= 5 ? 1 : 0),
      fastestAnswerMs: _minPositive(p.fastestAnswerMs, result.fastestAnswerMs),
      categoriesPlayed: categories,
    );

    if (result.mode == 'marathon' && result.total > p.marathonBest) {
      updated = updated.copyWith(marathonBest: result.total);
    }
    if (result.mode == 'duel' && result.isWin) {
      updated = updated.copyWith(duelsWon: p.duelsWon + 1);
    }
    if (result.mode == 'daily') {
      updated = _applyDailyStreak(updated);
    }

    progress.value = updated;
    await _save();
    return badges.evaluate(updated);
  }

  PlayerProgress _applyDailyStreak(PlayerProgress p) {
    final now = DateTime.now();
    final today = _dayKey(now);
    if (p.lastDailyDate == today) return p; // already counted today
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    final streak = p.lastDailyDate == yesterday ? p.dailyStreak + 1 : 1;
    return p.copyWith(dailyStreak: streak, lastDailyDate: today);
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _minPositive(int a, int b) {
    if (a <= 0) return b;
    if (b <= 0) return a;
    return a < b ? a : b;
  }

  Future<void> reset() async {
    progress.value = const PlayerProgress();
    await box.remove(AppConfig.kProgress);
    await badges.reset();
  }
}
