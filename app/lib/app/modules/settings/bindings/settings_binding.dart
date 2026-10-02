import 'package:get/get.dart';
import 'package:quiz_arena/app/core/utils/theme_controller.dart';
import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';

import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        auth: Get.find<AuthRepository>(),
        api: Get.find<ApiService>(),
        theme: Get.find<ThemeController>(),
        progressRepo: Get.find<ProgressRepository>(),
      ),
    );
  }
}
