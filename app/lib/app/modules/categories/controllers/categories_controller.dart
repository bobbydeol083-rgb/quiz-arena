import 'package:get/get.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';

/// Category picker grid.
class CategoriesController extends GetxController {
  final QuizRepository quizRepo;

  CategoriesController({required this.quizRepo});

  final RxBool isLoading = true.obs;
  final RxList<QuizCategory> categories = <QuizCategory>[].obs;
  final RxBool offline = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      categories.value = await quizRepo.getCategories();
      offline.value = quizRepo.offline.value;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAll() => load();
}
