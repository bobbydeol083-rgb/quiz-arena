import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/modules/auth/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController(auth: Get.find<AuthRepository>()));
  }
}
