import '../models/models.dart';
import '../providers/api_service.dart';

/// Nearby players + party rooms. Network failures surface as [ApiException]
/// so controllers can render offline/empty states — never a crash.
class SocialRepository {
  final ApiService api;

  SocialRepository({required this.api});

  /// Best-effort location heartbeat; network errors are swallowed because
  /// this must never interrupt gameplay.
  Future<void> postLocation({required double lng, required double lat}) async {
    try {
      await api.postLocation(lng, lat);
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
    }
  }

  Future<List<NearbyPlayer>> nearby({
    int maxDistance = 5000,
    int limit = 20,
  }) async {
    final list = await api.nearbyPlayers(
      maxDistance: maxDistance,
      limit: limit,
    );
    return list.map(NearbyPlayer.fromJson).toList();
  }

  Future<RoomInfo> createRoom({required String mode, String? category}) async {
    final json = await api.createRoom(mode: mode, category: category);
    return RoomInfo.fromJson(json);
  }
}
