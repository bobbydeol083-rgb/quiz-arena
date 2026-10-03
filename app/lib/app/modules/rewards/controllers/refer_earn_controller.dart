import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/rewards_repository.dart';

/// Refer & earn state: my code, friends referred, coins earned.
class ReferEarnController extends GetxController {
  final RewardsRepository rewards;

  ReferEarnController({required this.rewards});

  final RxBool loading = true.obs;
  final RxString code = ''.obs;
  final RxInt referredCount = 0.obs;
  final RxInt earnedCoins = 0.obs;
  final RxInt referrerReward = 100.obs;
  final RxInt refereeReward = 50.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      final info = await rewards.referralInfo();
      code.value = '${info['code'] ?? ''}';
      referredCount.value = (info['referredCount'] as num?)?.toInt() ?? 0;
      earnedCoins.value = (info['earnedCoins'] as num?)?.toInt() ?? 0;
      referrerReward.value = (info['referrerReward'] as num?)?.toInt() ?? 100;
      refereeReward.value = (info['refereeReward'] as num?)?.toInt() ?? 50;
    } catch (e) {
      error.value = 'Could not load referral info. Check your connection.';
    } finally {
      loading.value = false;
    }
  }

  String get shareText =>
      'Join me on QuizArena and we both win coins! Use my code ${code.value} when you sign up. You get $refereeReward coins, I get $referrerReward. 🧠';
}
