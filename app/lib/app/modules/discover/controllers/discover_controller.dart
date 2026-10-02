import 'package:get/get.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/leaderboard_repository.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';

/// Discover tab: search quizzes by category and browse top players.
class DiscoverController extends GetxController {
  final QuizRepository quizRepo;
  final LeaderboardRepository leaderboardRepo;

  DiscoverController({
    required this.quizRepo,
    required this.leaderboardRepo,
  });

  /// 0 = Quizzes, 1 = Players.
  final RxInt tab = 0.obs;
  final RxString query = ''.obs;
  final RxBool isLoading = true.obs;
  final RxList<QuizCategory> categories = <QuizCategory>[].obs;
  final RxList<LeaderboardEntry> players = <LeaderboardEntry>[].obs;
  final RxBool offline = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        quizRepo.getCategories(),
        leaderboardRepo.get(limit: 20),
      ]);
      categories.value = results[0] as List<QuizCategory>;
      players.value = (results[1] as LeaderboardResponse).entries;
      offline.value = quizRepo.offline.value;
    } finally {
      isLoading.value = false;
    }
  }

  void setTab(int value) => tab.value = value.clamp(0, 1);
  void setQuery(String value) => query.value = value;

  List<QuizCategory> get filteredCategories {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return categories;
    return categories
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  List<LeaderboardEntry> get filteredPlayers {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return players;
    return players
        .where((p) => p.username.toLowerCase().contains(q))
        .toList();
  }
}
