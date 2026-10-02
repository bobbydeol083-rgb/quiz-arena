import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';

class QuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => QuizController(
        quizRepo: Get.find<QuizRepository>(),
        auth: Get.find<AuthRepository>(),
        progressRepo: Get.find<ProgressRepository>(),
        socket: Get.find<SocketService>(),
      ),
    );
  }
}
