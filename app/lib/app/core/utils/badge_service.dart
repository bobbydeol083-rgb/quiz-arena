import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/values/app_config.dart';
import '../../data/models/progress.dart';

/// Static definition of an unlockable badge.
class BadgeDef {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String colorHex;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.colorHex,
  });
}

/// Unlock rules live here so both the UI and unit tests share one source of
/// truth. [checkUnlocks] is pure (no storage) to keep it unit-testable; the
/// [BadgeService] wrapper handles persistence.
class BadgeRules {
  BadgeRules._();

  static const List<BadgeDef> all = [
    BadgeDef(
      id: 'first_win',
      name: 'First Blood',
      description: 'Win your first quiz',
      emoji: '🏆',
      colorHex: '#F5C044',
    ),
    BadgeDef(
      id: 'streak_3',
      name: 'On Fire',
      description: '3 correct answers in a row',
      emoji: '🔥',
      colorHex: '#F97316',
    ),
    BadgeDef(
      id: 'streak_7',
      name: 'Unstoppable',
      description: '7 correct answers in a row',
      emoji: '⚡',
      colorHex: '#22D3EE',
    ),
    BadgeDef(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Answer correctly in under 3 seconds',
      emoji: '⏱️',
      colorHex: '#34D399',
    ),
    BadgeDef(
      id: 'perfectionist',
      name: 'Perfectionist',
      description: 'Score 100% in a quiz (5+ questions)',
      emoji: '💯',
      colorHex: '#8B5CF6',
    ),
    BadgeDef(
      id: 'marathoner',
      name: 'Marathoner',
      description: 'Answer 25+ questions in one marathon run',
      emoji: '🏃',
      colorHex: '#60A5FA',
    ),
    BadgeDef(
      id: 'duelist',
      name: 'Duelist',
      description: 'Win your first 1v1 duel',
      emoji: '⚔️',
      colorHex: '#E879F9',
    ),
    BadgeDef(
      id: 'scholar',
      name: 'Scholar',
      description: 'Answer 100 questions in total',
      emoji: '📚',
      colorHex: '#FBBF24',
    ),
    BadgeDef(
      id: 'explorer',
      name: 'Explorer',
      description: 'Play quizzes in all 6 categories',
      emoji: '🧭',
      colorHex: '#34D399',
    ),
    BadgeDef(
      id: 'daily_3',
      name: 'Committed',
      description: 'Keep a 3-day daily challenge streak',
      emoji: '📅',
      colorHex: '#F87171',
    ),
  ];

  static BadgeDef? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Returns the ids of badges that [p] has earned but are not in
  /// [alreadyUnlocked].
  static List<String> checkUnlocks(PlayerProgress p, Set<String> alreadyUnlocked) {
    final earned = <String>[];

    void grant(String id, bool condition) {
      if (condition && !alreadyUnlocked.contains(id)) earned.add(id);
    }

    grant('first_win', p.wins >= 1);
    grant('streak_3', p.bestStreak >= 3);
    grant('streak_7', p.bestStreak >= 7);
    grant('speed_demon', p.fastestAnswerMs > 0 && p.fastestAnswerMs <= 3000);
    grant('perfectionist', p.perfectGames >= 1);
    grant('marathoner', p.marathonBest >= 25);
    grant('duelist', p.duelsWon >= 1);
    grant('scholar', p.totalAnswered >= 100);
    grant('explorer', p.categoriesPlayed.length >= 6);
    grant('daily_3', p.dailyStreak >= 3);

    return earned;
  }
}

/// GetX service that persists unlocked badges and evaluates new unlocks
/// after each game.
class BadgeService extends GetxService {
  final GetStorage _box;
  final RxSet<String> unlocked = <String>{}.obs;

  BadgeService({GetStorage? box}) : _box = box ?? GetStorage();

  @override
  void onInit() {
    super.onInit();
    final stored = _box.read<List>(AppConfig.kBadges);
    if (stored != null) {
      unlocked.addAll(stored.whereType<String>());
    }
  }

  /// Evaluate [progress] against the rules; newly unlocked badge ids are
  /// returned and persisted.
  List<String> evaluate(PlayerProgress progress) {
    final fresh = BadgeRules.checkUnlocks(progress, unlocked.toSet());
    if (fresh.isNotEmpty) {
      unlocked.addAll(fresh);
      _box.write(AppConfig.kBadges, unlocked.toList());
    }
    return fresh;
  }

  bool isUnlocked(String id) => unlocked.contains(id);

  Future<void> reset() async {
    unlocked.clear();
    await _box.remove(AppConfig.kBadges);
  }
}
