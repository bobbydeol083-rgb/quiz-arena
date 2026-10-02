import 'package:get/get.dart';
import 'package:quiz_arena/app/data/repositories/leaderboard_repository.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';
import 'package:quiz_arena/app/modules/discover/controllers/discover_controller.dart';

class DiscoverBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiscoverController>(
      () => DiscoverController(
        quizRepo: Get.find<QuizRepository>(),
        leaderboardRepo: Get.find<LeaderboardRepository>(),
      ),
    );
  }
}
