import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_arena/app/core/utils/level_config.dart';

void main() {
  group('LevelConfig.levelForXp', () {
    test('starts at level 1 with 0 xp', () {
      expect(LevelConfig.levelForXp(0), 1);
      expect(LevelConfig.levelForXp(-50), 1);
    });

    test('level boundaries match thresholds', () {
      expect(LevelConfig.levelForXp(99), 1);
      expect(LevelConfig.levelForXp(100), 2);
      expect(LevelConfig.levelForXp(249), 2);
      expect(LevelConfig.levelForXp(250), 3);
      expect(LevelConfig.levelForXp(450), 4);
      expect(LevelConfig.levelForXp(1000), 6);
      expect(LevelConfig.levelForXp(11000), 16);
      expect(LevelConfig.levelForXp(999999), LevelConfig.maxLevel);
    });

    test('xpForLevel returns the threshold to reach a level', () {
      expect(LevelConfig.xpForLevel(1), 0);
      expect(LevelConfig.xpForLevel(2), 100);
      expect(LevelConfig.xpForLevel(6), 1000);
    });
  });

  group('LevelConfig.progress', () {
    test('is 0 at the start of a level and approaches 1 at the end', () {
      expect(LevelConfig.progress(0), 0.0);
      expect(LevelConfig.progress(100), 0.0); // start of level 2
      final mid = LevelConfig.progress(175); // halfway 100 -> 250
      expect(mid, closeTo(0.5, 0.001));
      expect(LevelConfig.progress(249), greaterThan(0.99));
    });

    test('is 1.0 at max level', () {
      expect(LevelConfig.progress(999999), 1.0);
    });

    test('xpToNext counts down to the next threshold', () {
      expect(LevelConfig.xpToNext(0), 100);
      expect(LevelConfig.xpToNext(90), 10);
      expect(LevelConfig.xpToNext(999999), 0);
    });
  });

  group('LevelConfig.tierForLevel', () {
    test('Bronze -> Silver -> Gold -> Platinum -> Diamond', () {
      expect(LevelConfig.tierForLevel(1), 'Bronze');
      expect(LevelConfig.tierForLevel(2), 'Bronze');
      expect(LevelConfig.tierForLevel(3), 'Silver');
      expect(LevelConfig.tierForLevel(5), 'Silver');
      expect(LevelConfig.tierForLevel(6), 'Gold');
      expect(LevelConfig.tierForLevel(8), 'Gold');
      expect(LevelConfig.tierForLevel(9), 'Platinum');
      expect(LevelConfig.tierForLevel(12), 'Platinum');
      expect(LevelConfig.tierForLevel(13), 'Diamond');
      expect(LevelConfig.tierForLevel(16), 'Diamond');
    });
  });
}
