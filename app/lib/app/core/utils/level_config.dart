import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// XP / level math for QuizArena.
///
/// Levels are 1-based. [_thresholds[i]] is the cumulative XP required to
/// reach level `i + 1`.
class LevelConfig {
  LevelConfig._();

  static const List<int> _thresholds = [
    0, // level 1
    100, // level 2
    250, // level 3
    450, // level 4
    700, // level 5
    1000, // level 6
    1400, // level 7
    1900, // level 8
    2500, // level 9
    3200, // level 10
    4000, // level 11
    5000, // level 12
    6200, // level 13
    7600, // level 14
    9200, // level 15
    11000, // level 16
  ];

  static int get maxLevel => _thresholds.length;

  /// Level for a given total XP (1-based, clamped to [1, maxLevel]).
  static int levelForXp(int xp) {
    if (xp < 0) xp = 0;
    var level = 1;
    for (var i = 1; i < _thresholds.length; i++) {
      if (xp >= _thresholds[i]) {
        level = i + 1;
      } else {
        break;
      }
    }
    return level;
  }

  /// Cumulative XP required to *reach* [level].
  static int xpForLevel(int level) {
    final l = level.clamp(1, maxLevel);
    return _thresholds[l - 1];
  }

  /// Cumulative XP required to reach the level after [level].
  /// Returns the current threshold when already at max level.
  static int xpForNextLevel(int level) {
    final l = level.clamp(1, maxLevel);
    if (l >= maxLevel) return _thresholds.last;
    return _thresholds[l];
  }

  /// Progress within the current level, 0.0 - 1.0.
  static double progress(int xp) {
    final level = levelForXp(xp);
    final current = xpForLevel(level);
    final next = xpForNextLevel(level);
    if (next <= current) return 1.0;
    return ((xp - current) / (next - current)).clamp(0.0, 1.0);
  }

  /// XP still needed to reach the next level (0 at max level).
  static int xpToNext(int xp) {
    final level = levelForXp(xp);
    if (level >= maxLevel) return 0;
    return xpForNextLevel(level) - xp;
  }

  /// Tier name for a level: Bronze -> Silver -> Gold -> Platinum -> Diamond.
  static String tierForLevel(int level) {
    if (level >= 13) return 'Diamond';
    if (level >= 9) return 'Platinum';
    if (level >= 6) return 'Gold';
    if (level >= 3) return 'Silver';
    return 'Bronze';
  }

  static Color tierColorForLevel(int level) =>
      AppColors.tierColor(tierForLevel(level));
}
