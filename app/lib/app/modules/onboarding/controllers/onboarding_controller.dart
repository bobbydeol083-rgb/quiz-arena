import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:quiz_arena/app/core/values/app_config.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Three-page onboarding carousel. Skipping or finishing the last page
/// persists the onboarded flag and routes to auth.
class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt page = 0.obs;

  void onPageChanged(int index) => page.value = index;

  void next() {
    if (page.value < 2) {
      pageController.nextPage(
        duration: AppDurations.page,
        curve: Curves.easeOutCubic,
      );
    } else {
      finish();
    }
  }

  void skip() => finish();

  Future<void> finish() async {
    await GetStorage().write(AppConfig.kOnboarded, true);
    Get.offNamed(Routes.auth);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
