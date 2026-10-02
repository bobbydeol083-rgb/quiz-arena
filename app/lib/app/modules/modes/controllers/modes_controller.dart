import 'package:get/get.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Mode picker: launches each [QuizMode] with the right destination.
class ModesController extends GetxController {
  final ProgressRepository progressRepo;

  ModesController({required this.progressRepo});

  List<QuizMode> get modes => QuizMode.values;

  int get dailyStreak => progressRepo.progress.value.dailyStreak;

  PlayerProgress get progress => progressRepo.progress.value;

  void playMode(QuizMode mode) {
    switch (mode) {
      case QuizMode.solo:
        Get.toNamed(Routes.categories);
      case QuizMode.blitz:
        Get.toNamed(
          Routes.quiz,
          arguments: QuizArgs(mode: QuizMode.blitz),
        );
      case QuizMode.marathon:
        Get.toNamed(
          Routes.quiz,
          arguments: QuizArgs(mode: QuizMode.marathon),
        );
      case QuizMode.daily:
        Get.toNamed(
          Routes.quiz,
          arguments: QuizArgs(mode: QuizMode.daily),
        );
      case QuizMode.duel:
        Get.toNamed(Routes.duel);
      case QuizMode.party:
        Get.toNamed(Routes.party);
    }
  }
}
