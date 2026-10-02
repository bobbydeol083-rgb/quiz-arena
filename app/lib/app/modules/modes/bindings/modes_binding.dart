import 'package:get/get.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/modules/modes/controllers/modes_controller.dart';

class ModesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ModesController>(
      () => ModesController(
        progressRepo: Get.find<ProgressRepository>(),
      ),
    );
  }
}
