import 'package:get/get.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/leaderboard_repository.dart';

/// Leaderboard state: scope tabs, ranked entries, own rank/points and
/// offline fallback flag. Data comes from [LeaderboardRepository], which
/// falls back to the local profile when the backend is unreachable.
class LeaderboardController extends GetxController {
  final LeaderboardRepository repo;
  final AuthRepository auth;

  LeaderboardController({required this.repo, required this.auth});

  final RxString scope = 'weekly'.obs;
  final RxList<LeaderboardEntry> entries = <LeaderboardEntry>[].obs;
  final RxInt meRank = (-1).obs;
  final RxInt mePoints = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool offline = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final res = await repo.get(scope: scope.value);
      entries.assignAll(res.entries);
      meRank.value = res.meRank ?? -1;
      mePoints.value = res.mePoints;
      offline.value = res.offline;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setScope(String s) async {
    if (s == scope.value) return;
    scope.value = s;
    await load();
  }

  Future<void> refresh() => load();
}
