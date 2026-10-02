import 'package:get/get.dart';
import 'package:quiz_arena/app/modules/leaderboard/controllers/leaderboard_controller.dart';

class LeaderboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeaderboardController>(
      () => LeaderboardController(
        repo: Get.find(),
        auth: Get.find(),
      ),
    );
  }
}
