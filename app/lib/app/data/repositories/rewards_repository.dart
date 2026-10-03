import 'package:quiz_arena/app/data/providers/api_service.dart';

/// Daily scratch rewards + refer & earn, backed by /api/rewards.
class RewardsRepository {
  final ApiService api;

  RewardsRepository({required this.api});

  /// Claim today's scratch reward. Returns {awarded, coins, tiers}.
  /// Throws [ApiException] with statusCode 409 when already claimed.
  Future<Map<String, dynamic>> claimDaily() async {
    final json = await api.postJson('/rewards/daily-claim', body: {});
    return Map<String, dynamic>.from(json as Map);
  }

  /// Referral code, count and earnings for the current user.
  Future<Map<String, dynamic>> referralInfo() async {
    final json = await api.getJson('/rewards/referral');
    return Map<String, dynamic>.from(json as Map);
  }
}
