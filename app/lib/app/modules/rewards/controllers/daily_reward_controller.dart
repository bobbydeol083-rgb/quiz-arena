import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/rewards_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';

/// Daily scratch-card reward state machine.
class DailyRewardController extends GetxController {
  final RewardsRepository rewards;
  final AuthRepository auth;
  final CoinLedger ledger;

  DailyRewardController({
    required this.rewards,
    required this.auth,
    required this.ledger,
  });

  final RxBool checking = true.obs;
  final RxBool canClaim = false.obs;
  final RxBool claiming = false.obs;
  final RxInt awarded = 0.obs;
  final RxBool revealed = false.obs;
  final RxString error = ''.obs;
  final RxList<int> tiers = <int>[].obs;

  /// Local mirror of the last claim date (yyyy-MM-dd) for instant UI.
  String get _todayKey =>
      DateTime.now().toIso8601String().substring(0, 10);

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    checking.value = true;
    error.value = '';
    try {
      // Probe claimability: the server is authoritative. We ask for the
      // referral info (cheap) — no, instead we just try a dry state via
      // local mirror first, then confirm on claim.
      final box = GetStorage();
      final lastLocal = box.read<String>('daily_claim_local');
      canClaim.value = lastLocal != _todayKey;
    } finally {
      checking.value = false;
    }
  }

  /// Called when the scratch threshold is reached.
  Future<void> claim() async {
    if (claiming.value || revealed.value) return;
    claiming.value = true;
    error.value = '';
    try {
      final res = await rewards.claimDaily();
      final amount = (res['awarded'] as num?)?.toInt() ?? 0;
      awarded.value = amount;
      tiers.assignAll(
          ((res['tiers'] as List?)?.map((e) => (e as num).toInt()) ?? [10, 20, 30, 50, 100]).toList());
      await auth.addCoins(amount);
      await ledger.record(amount, 'Daily scratch reward');
      await GetStorage().write('daily_claim_local', _todayKey);
      canClaim.value = false;
      revealed.value = true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Already claimed (server won the race or another device claimed).
        await GetStorage().write('daily_claim_local', _todayKey);
        canClaim.value = false;
        error.value = 'Already claimed — come back tomorrow!';
      } else if (e.isNetworkError) {
        error.value = 'You\u2019re offline — connect to claim your reward.';
      } else {
        error.value = e.message;
      }
    } finally {
      claiming.value = false;
    }
  }
}
