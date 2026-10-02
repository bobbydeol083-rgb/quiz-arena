/// Party room info (POST /api/rooms -> {code}).
class RoomInfo {
  final String code;
  final String? roomId;
  final String mode;
  final String? category;

  const RoomInfo({
    required this.code,
    this.roomId,
    required this.mode,
    this.category,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) => RoomInfo(
        code: '${json['code']}',
        roomId: json['roomId'] as String?,
        mode: '${json['mode'] ?? 'party'}',
        category: json['category'] as String?,
      );
}

/// A player currently inside a party room (socket `room:state` payload).
class RoomPlayer {
  final String userId;
  final String username;
  final String? avatar;
  final bool isHost;
  final int score;

  const RoomPlayer({
    required this.userId,
    required this.username,
    this.avatar,
    this.isHost = false,
    this.score = 0,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> json) => RoomPlayer(
        userId: '${json['userId'] ?? json['id'] ?? ''}',
        username: '${json['username'] ?? 'Player'}',
        avatar: json['avatar'] as String?,
        isHost: json['isHost'] == true,
        score: (json['score'] as num?)?.toInt() ?? 0,
      );
}
