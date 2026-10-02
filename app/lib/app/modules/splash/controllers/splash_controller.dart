import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:quiz_arena/app/core/values/app_config.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Splash boot sequence: holds the logo animation for 2.4s, then routes
/// based on onboarding + session state.
class SplashController extends GetxController {
  final AuthRepository auth;

  SplashController({required this.auth});

  @override
  void onReady() {
    super.onReady();
    _boot();
  }

  Future<void> _boot() async {
    // Logo animation window.
    await Future.delayed(const Duration(milliseconds: 2400));

    if (GetStorage().read(AppConfig.kOnboarded) != true) {
      Get.offNamed(Routes.onboarding);
      return;
    }
    if (!auth.isLoggedIn) {
      Get.offNamed(Routes.auth);
      return;
    }
    Get.offNamed(Routes.home);
  }
}
