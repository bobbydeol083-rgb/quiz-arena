import 'package:get/get.dart';

import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/providers/socket_service.dart';

/// Duel lobby: pick a category and find a realtime 1v1 match.
class DuelController extends GetxController {
  final SocketService socket;

  DuelController({required this.socket});

  final RxString selectedCategory = 'science'.obs;
  final RxBool searching = false.obs;
  final List<QuizCategory> categories = QuizCategory.localDefaults();

  String get categoryName {
    for (final c in categories) {
      if (c.id == selectedCategory.value) return c.name;
    }
    return selectedCategory.value;
  }

  void startMatchmaking() {
    if (!socket.isConnected) {
      Get.snackbar(
        'Offline',
        'Connect to the backend to find a live opponent.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    socket.joinMatchmaking(selectedCategory.value);
    searching.value = true;
  }

  void cancel() {
    socket.leaveMatchmaking();
    searching.value = false;
  }

  @override
  void onClose() {
    if (searching.value) socket.leaveMatchmaking();
    super.onClose();
  }
}
