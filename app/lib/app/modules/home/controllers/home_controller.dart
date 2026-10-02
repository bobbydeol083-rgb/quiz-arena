import 'package:get/get.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';

/// Home tab: greeting, XP card, quick modes, categories, social banners.
class HomeController extends GetxController {
  final QuizRepository quizRepo;
  final AuthRepository auth;
  final ProgressRepository progressRepo;

  HomeController({
    required this.quizRepo,
    required this.auth,
    required this.progressRepo,
  });

  final RxBool isLoading = true.obs;
  final RxList<QuizCategory> categories = <QuizCategory>[].obs;
  final RxBool offline = false.obs;

  AppUser? get user => auth.currentUser.value;
  PlayerProgress get progress => progressRepo.progress.value;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

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
