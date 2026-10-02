import 'package:confetti/confetti.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Results screen state. The [QuizSubmitResult] arrives as [Get.arguments]
/// (see [QuizController.completeGame]); if it is missing we bail to home.
class ResultsController extends GetxController {
  final AuthRepository auth;

  ResultsController({required this.auth});

  QuizSubmitResult? result;
  late final ConfettiController confetti;

  /// XP the player had *before* this game, so the XP bar can sweep forward.
  int fromXp = 0;

  @override
  void onInit() {
    super.onInit();
    confetti = ConfettiController(duration: const Duration(seconds: 3));
    final args = Get.arguments;
    if (args is QuizSubmitResult) result = args;
  }

  @override
  void onReady() {
    super.onReady();
    final r = result;
    if (r == null) {
      Get.offNamed(Routes.home);
      return;
    }
    final u = auth.currentUser.value;
    fromXp = ((u?.xp ?? r.xpEarned) - r.xpEarned).clamp(0, 1 << 30);
    if (r.isWin) confetti.play();
  }

  @override
  void onClose() {
    confetti.dispose();
    super.onClose();
  }
}
