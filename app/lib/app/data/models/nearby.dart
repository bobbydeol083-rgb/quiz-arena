/// A nearby online player (GET /api/players/nearby).
class NearbyPlayer {
  final String id;
  final String username;
  final String? avatar;
  final int xp;
  final int level;
  final double distanceM;
  final bool online;

  const NearbyPlayer({
    required this.id,
    required this.username,
    this.avatar,
    this.xp = 0,
    this.level = 1,
    this.distanceM = 0,
    this.online = true,
  });

  factory NearbyPlayer.fromJson(Map<String, dynamic> json) => NearbyPlayer(
        id: '${json['id'] ?? json['_id'] ?? ''}',
        username: '${json['username'] ?? 'Player'}',
        avatar: json['avatar'] as String?,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        distanceM: (json['distanceM'] as num?)?.toDouble() ?? 0,
        online: json['online'] != false,
      );
}
