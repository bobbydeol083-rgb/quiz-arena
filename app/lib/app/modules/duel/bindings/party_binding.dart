import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/modules/duel/controllers/party_controller.dart';

class PartyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PartyController(socket: Get.find<SocketService>()));
  }
}
