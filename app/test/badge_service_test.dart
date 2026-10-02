import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_arena/app/core/utils/badge_service.dart';
import 'package:quiz_arena/app/data/models/progress.dart';

PlayerProgress _p({
  int wins = 0,
  int bestStreak = 0,
  int fastestAnswerMs = 0,
  int perfectGames = 0,
  int marathonBest = 0,
  int duelsWon = 0,
  int totalAnswered = 0,
  Set<String> categoriesPlayed = const {},
  int dailyStreak = 0,
}) =>
    PlayerProgress(
      wins: wins,
      bestStreak: bestStreak,
      fastestAnswerMs: fastestAnswerMs,
      perfectGames: perfectGames,
      marathonBest: marathonBest,
      duelsWon: duelsWon,
      totalAnswered: totalAnswered,
      categoriesPlayed: categoriesPlayed,
      dailyStreak: dailyStreak,
    );

void main() {
  group('BadgeRules.checkUnlocks', () {
    test('empty progress unlocks nothing', () {
      expect(BadgeRules.checkUnlocks(_p(), {}), isEmpty);
    });

    test('first win unlocks first_win', () {
      expect(BadgeRules.checkUnlocks(_p(wins: 1), {}), contains('first_win'));
    });

    test('streak badges unlock at 3 and 7', () {
      expect(BadgeRules.checkUnlocks(_p(bestStreak: 3), {}),
          contains('streak_3'));
      final both = BadgeRules.checkUnlocks(_p(bestStreak: 7), {});
      expect(both, contains('streak_3'));
      expect(both, contains('streak_7'));
    });

    test('speed demon needs a sub-3s correct answer', () {
      expect(BadgeRules.checkUnlocks(_p(fastestAnswerMs: 2500), {}),
          contains('speed_demon'));
      expect(BadgeRules.checkUnlocks(_p(fastestAnswerMs: 3001), {}),
          isNot(contains('speed_demon')));
      expect(BadgeRules.checkUnlocks(_p(fastestAnswerMs: 0), {}),
          isNot(contains('speed_demon')));
    });

    test('perfectionist, marathoner, duelist', () {
      expect(BadgeRules.checkUnlocks(_p(perfectGames: 1), {}),
          contains('perfectionist'));
      expect(BadgeRules.checkUnlocks(_p(marathonBest: 25), {}),
          contains('marathoner'));
      expect(BadgeRules.checkUnlocks(_p(marathonBest: 24), {}),
          isNot(contains('marathoner')));
      expect(
          BadgeRules.checkUnlocks(_p(duelsWon: 1), {}), contains('duelist'));
    });

    test('scholar at 100 answers, explorer at 6 categories, daily_3', () {
      expect(BadgeRules.checkUnlocks(_p(totalAnswered: 100), {}),
          contains('scholar'));
      expect(
          BadgeRules.checkUnlocks(
              _p(categoriesPlayed: {'a', 'b', 'c', 'd', 'e', 'f'}), {}),
          contains('explorer'));
      expect(BadgeRules.checkUnlocks(_p(dailyStreak: 3), {}),
          contains('daily_3'));
    });

    test('already-unlocked badges are not returned again', () {
      final unlocked = {'first_win', 'streak_3'};
      expect(BadgeRules.checkUnlocks(_p(wins: 5, bestStreak: 9), unlocked),
          isNot(contains('first_win')));
      expect(BadgeRules.checkUnlocks(_p(wins: 5, bestStreak: 9), unlocked),
          contains('streak_7'));
    });

    test('all badge ids resolve to definitions', () {
      for (final id in [
        'first_win',
        'streak_3',
        'streak_7',
        'speed_demon',
        'perfectionist',
        'marathoner',
        'duelist',
        'scholar',
        'explorer',
        'daily_3',
      ]) {
        expect(BadgeRules.byId(id), isNotNull, reason: 'missing def: $id');
      }
    });
  });
}
