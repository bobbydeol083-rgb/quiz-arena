import 'package:get/get.dart';
import 'package:quiz_arena/app/modules/profile/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        auth: Get.find(),
        progressRepo: Get.find(),
        badgeService: Get.find(),
      ),
    );
  }
}
