import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/modules/results/controllers/results_controller.dart';

class ResultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ResultsController(auth: Get.find<AuthRepository>()));
  }
}
