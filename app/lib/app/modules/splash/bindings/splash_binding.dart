import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/modules/splash/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashController(auth: Get.find<AuthRepository>()));
  }
}
