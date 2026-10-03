import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';

import '../controllers/statistics_controller.dart';

class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatisticsController>(
      () => StatisticsController(
        progress: Get.find<ProgressRepository>(),
        auth: Get.find<AuthRepository>(),
      ),
    );
  }
}
