import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import '../controllers/bluff_controller.dart';

class BluffBinding extends Bindings {
  @override
  void dependencies() {
    // Eager put: the phase machine must be listening from the moment the
    // route opens (bluff:start can precede the first frame).
    Get.put(
      BluffController(
        socket: Get.find<SocketService>(),
        auth: Get.find<AuthRepository>(),
      ),
    );
  }
}
