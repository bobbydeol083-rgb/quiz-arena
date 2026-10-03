import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/rewards_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';

import '../controllers/daily_reward_controller.dart';
import '../controllers/refer_earn_controller.dart';

class DailyRewardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RewardsRepository>()) {
      Get.lazyPut<RewardsRepository>(
        () => RewardsRepository(api: Get.find<ApiService>()),
      );
    }
    Get.lazyPut<DailyRewardController>(
      () => DailyRewardController(
        rewards: Get.find<RewardsRepository>(),
        auth: Get.find<AuthRepository>(),
        ledger: Get.find<CoinLedger>(),
      ),
    );
  }
}

class ReferEarnBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RewardsRepository>()) {
      Get.lazyPut<RewardsRepository>(
        () => RewardsRepository(api: Get.find<ApiService>()),
      );
    }
    Get.lazyPut<ReferEarnController>(
      () => ReferEarnController(rewards: Get.find<RewardsRepository>()),
    );
  }
}
