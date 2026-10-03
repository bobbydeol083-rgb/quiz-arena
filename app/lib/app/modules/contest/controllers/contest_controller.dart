import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/contest_repository.dart';

/// Contest lobby: live / upcoming / ended contests.
class ContestController extends GetxController {
  final ContestRepository repo;

  ContestController({required this.repo});

  final RxBool loading = true.obs;
  final RxList<ContestCard> contests = <ContestCard>[].obs;
  final RxString error = ''.obs;

  List<ContestCard> get live =>
      contests.where((c) => c.phase == 'live').toList();
  List<ContestCard> get upcoming =>
      contests.where((c) => c.phase == 'upcoming').toList();
  List<ContestCard> get ended =>
      contests.where((c) => c.phase == 'ended').toList();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      contests.assignAll(await repo.list());
    } on ApiException catch (e) {
      error.value = e.isNetworkError
          ? 'You\u2019re offline — contests need a connection.'
          : e.message;
    } finally {
      loading.value = false;
    }
  }
}
