import 'package:flutter/widgets.dart';

/// Authenticated player profile.
class AppUser {
  final String id;
  final String username;
  final String email;
  final String? avatar;
  final int xp;
  final int level;
  final int coins;
  final int streak;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    this.streak = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: '${json['id'] ?? json['_id'] ?? ''}',
        username: '${json['username'] ?? 'Player'}',
        email: '${json['email'] ?? ''}',
        avatar: json['avatar'] as String?,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        streak: _streakCount(json['streak']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'avatar': avatar,
        'xp': xp,
        'level': level,
        'coins': coins,
        'streak': streak,
      };

  AppUser copyWith({
    String? id,
    String? username,
    String? email,
    String? avatar,
    int? xp,
    int? level,
    int? coins,
    int? streak,
  }) =>
      AppUser(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        coins: coins ?? this.coins,
        streak: streak ?? this.streak,
      );

  /// Lightweight display name initials for avatar fallbacks.
  String get initials {
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  /// A local demo profile used when the backend is unreachable.
  factory AppUser.demo() => const AppUser(
        id: 'local-demo',
        username: 'Guest Player',
        email: 'guest@local',
        xp: 0,
        level: 1,
        coins: 100,
        streak: 0,
      );
}

/// The API returns streak as `{count, lastPlayedAt}`; accept a plain number
/// too so offline/alternate payloads keep working.
int _streakCount(dynamic v) {
  if (v is num) return v.toInt();
  if (v is Map) return (v['count'] as num?)?.toInt() ?? 0;
  return 0;
}
