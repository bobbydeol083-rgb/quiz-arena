import 'package:get/get.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';
import 'package:quiz_arena/app/modules/categories/controllers/categories_controller.dart';

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoriesController>(
      () => CategoriesController(
        quizRepo: Get.find<QuizRepository>(),
      ),
    );
  }
}
