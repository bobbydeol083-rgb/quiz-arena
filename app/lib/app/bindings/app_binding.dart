import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/utils/badge_service.dart';
import '../core/values/app_config.dart';
import '../data/providers/api_service.dart';
import '../data/providers/local_question_bank.dart';
import '../data/providers/socket_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/quiz_repository.dart';
import '../data/repositories/pack_repository.dart';
import '../data/repositories/social_repository.dart';
import '../modules/duel/controllers/realtime_controller.dart';

/// Root dependency graph, registered once at app start.
/// Order matters: providers -> services -> repositories.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final box = GetStorage();

    // Restore the API base override before the ApiService is built.
    AppConfig.overrideBase = box.read<String>(AppConfig.kApiBase);

    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<LocalQuestionBank>(LocalQuestionBank(), permanent: true);
    Get.put<SocketService>(SocketService(), permanent: true);
    Get.put<BadgeService>(BadgeService(), permanent: true);
    // NOTE: ThemeController is registered in main() before runApp so the
    // root widget can observe it from the first frame.

    Get.put<AuthRepository>(
      AuthRepository(api: Get.find<ApiService>()),
      permanent: true,
    );
    Get.put<ProgressRepository>(
      ProgressRepository(badges: Get.find<BadgeService>()),
      permanent: true,
    );
    Get.put<QuizRepository>(
      QuizRepository(
        api: Get.find<ApiService>(),
        bank: Get.find<LocalQuestionBank>(),
        auth: Get.find<AuthRepository>(),
      ),
      permanent: true,
    );
    Get.put<LeaderboardRepository>(
      LeaderboardRepository(
        api: Get.find<ApiService>(),
        auth: Get.find<AuthRepository>(),
      ),
      permanent: true,
    );
    Get.put<SocialRepository>(
      SocialRepository(api: Get.find<ApiService>()),
      permanent: true,
    );
    Get.put<PackRepository>(
      PackRepository(api: Get.find<ApiService>()),
      permanent: true,
    );
    Get.put<RealtimeController>(
      RealtimeController(
        socket: Get.find<SocketService>(),
        auth: Get.find<AuthRepository>(),
      ),
      permanent: true,
    );
  }
}
