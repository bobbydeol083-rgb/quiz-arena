import '../../core/utils/badge_service.dart';

/// An earned (or locked) badge shown on the profile.
class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String colorHex;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.colorHex,
    this.unlocked = false,
    this.unlockedAt,
  });

  /// Build the full badge shelf from definitions + the unlocked id set.
  static List<Badge> shelf(Set<String> unlockedIds) => BadgeRules.all
      .map((d) => Badge(
            id: d.id,
            name: d.name,
            description: d.description,
            emoji: d.emoji,
            colorHex: d.colorHex,
            unlocked: unlockedIds.contains(d.id),
          ))
      .toList();
}
