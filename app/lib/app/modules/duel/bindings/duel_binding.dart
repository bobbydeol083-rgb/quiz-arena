import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/modules/duel/controllers/duel_controller.dart';

class DuelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DuelController(socket: Get.find<SocketService>()));
  }
}
