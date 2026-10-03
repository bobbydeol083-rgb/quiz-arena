import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/contest_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';

import '../controllers/contest_controller.dart';
import '../controllers/contest_play_controller.dart';

class ContestBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ContestRepository>()) {
      Get.lazyPut<ContestRepository>(
        () => ContestRepository(api: Get.find<ApiService>()),
      );
    }
    Get.lazyPut<ContestController>(
      () => ContestController(repo: Get.find<ContestRepository>()),
    );
  }
}

class ContestDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ContestRepository>()) {
      Get.lazyPut<ContestRepository>(
        () => ContestRepository(api: Get.find<ApiService>()),
      );
    }
    final id = Get.parameters['id'] ?? '';
    Get.lazyPut<ContestPlayController>(
      () => ContestPlayController(
        repo: Get.find<ContestRepository>(),
        auth: Get.find<AuthRepository>(),
        ledger: Get.find<CoinLedger>(),
        contestId: id,
      ),
    );
  }
}
