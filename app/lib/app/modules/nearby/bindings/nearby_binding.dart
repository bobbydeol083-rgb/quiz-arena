import 'package:get/get.dart';
import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/data/repositories/social_repository.dart';

import '../controllers/nearby_controller.dart';

class NearbyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NearbyController>(
      () => NearbyController(
        social: Get.find<SocialRepository>(),
        socket: Get.find<SocketService>(),
      ),
    );
  }
}
