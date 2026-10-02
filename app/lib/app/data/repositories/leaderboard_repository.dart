import '../models/models.dart';
import '../providers/api_service.dart';
import 'auth_repository.dart';

/// Leaderboard with offline fallback (local profile only).
class LeaderboardRepository {
  final ApiService api;
  final AuthRepository auth;

  LeaderboardRepository({required this.api, required this.auth});

  Future<LeaderboardResponse> get({
    String scope = 'weekly',
    int limit = 50,
  }) async {
    try {
      final json = await api.leaderboard(scope: scope, limit: limit);
      return LeaderboardResponse.fromJson(json);
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      final me = auth.currentUser.value ?? AppUser.demo();
      return LeaderboardResponse.offlineDemo(me);
    }
  }
}
