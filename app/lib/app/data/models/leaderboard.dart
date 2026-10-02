import 'user.dart';

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatar;
  final int points;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatar,
    required this.points,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: '${user['id'] ?? user['_id'] ?? ''}',
      username: '${user['username'] ?? 'Player'}',
      avatar: user['avatar'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardResponse {
  final List<LeaderboardEntry> entries;
  final int? meRank;
  final int mePoints;
  final bool offline;

  const LeaderboardResponse({
    required this.entries,
    this.meRank,
    this.mePoints = 0,
    this.offline = false,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List? ?? [])
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final me = json['me'] as Map<String, dynamic>?;
    return LeaderboardResponse(
      entries: entries,
      meRank: (me?['rank'] as num?)?.toInt(),
      mePoints: (me?['points'] as num?)?.toInt() ?? 0,
    );
  }

  /// Offline placeholder built from the local profile.
  factory LeaderboardResponse.offlineDemo(AppUser me) => LeaderboardResponse(
        entries: const [],
        meRank: 1,
        mePoints: me.xp,
        offline: true,
      );
}
