import 'package:get/get.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';
import 'package:quiz_arena/app/modules/home/controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        quizRepo: Get.find<QuizRepository>(),
        auth: Get.find<AuthRepository>(),
        progressRepo: Get.find<ProgressRepository>(),
      ),
    );
  }
}
