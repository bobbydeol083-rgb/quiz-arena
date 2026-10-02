import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/pack_repository.dart';
import '../controllers/pack_editor_controller.dart';
import '../controllers/packs_controller.dart';

class PacksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PacksController(packs: Get.find<PackRepository>()),
    );
  }
}

class PackEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PackEditorController(packs: Get.find<PackRepository>()),
    );
  }
}
