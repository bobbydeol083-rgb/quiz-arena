import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/modules/splash/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager put (NOT lazyPut): SplashView never touches `controller` in
    // build(), so a lazy registration would never instantiate and onReady
    // (the boot sequence that routes off the splash) would never run —
    // leaving the app stuck on the splash screen forever.
    Get.put(SplashController(auth: Get.find<AuthRepository>()));
  }
}
