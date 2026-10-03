import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/contest_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';

/// Contest detail + join + play + submit flow.
class ContestPlayController extends GetxController {
  final ContestRepository repo;
  final AuthRepository auth;
  final CoinLedger ledger;
  final String contestId;

  ContestPlayController({
    required this.repo,
    required this.auth,
    required this.ledger,
    required this.contestId,
  });

  final RxBool loading = true.obs;
  final RxString error = ''.obs;
  final RxMap<String, dynamic> detail = <String, dynamic>{}.obs;

  // Play state.
  final RxList<ContestQuestion> questions = <ContestQuestion>[].obs;
  final RxInt index = 0.obs;
  final RxMap<int, int> answers = <int, int>{}.obs;
  final RxBool joining = false.obs;
  final RxBool submitting = false.obs;
  final RxMap<String, dynamic> result = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> leaderboard =
      <Map<String, dynamic>>[].obs;

  bool get hasJoined => questions.isNotEmpty;
  bool get hasResult => result.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      detail.assignAll(await repo.detail(contestId));
      leaderboard.assignAll(await repo.leaderboard(contestId));
    } on ApiException catch (e) {
      error.value = e.isNetworkError
          ? 'You\u2019re offline — contests need a connection.'
          : e.message;
    } finally {
      loading.value = false;
    }
  }

  Future<void> join() async {
    if (joining.value || hasJoined) return;
    joining.value = true;
    error.value = '';
    try {
      final res = await repo.join(contestId);
      questions.assignAll(res.questions);
      index.value = 0;
      answers.clear();
      // Sync the coin balance after the entry fee debit.
      final user = auth.currentUser.value;
      if (user != null) {
        auth.currentUser.value = user.copyWith(coins: res.coins);
      }
      final fee = (detail['entryFee'] as num?)?.toInt() ?? 0;
      if (fee > 0) {
        await ledger.record(-fee, 'Contest entry: ${detail['name'] ?? ''}');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 402) {
        error.value = 'Not enough coins for the entry fee.';
      } else if (e.statusCode == 409) {
        error.value = e.message;
        await load(); // refresh played state
      } else {
        error.value = e.isNetworkError ? 'You\u2019re offline.' : e.message;
      }
    } finally {
      joining.value = false;
    }
  }

  void select(int optionIndex) {
    if (hasResult || submitting.value) return;
    answers[index.value] = optionIndex;
  }

  void next() {
    if (index.value + 1 < questions.length) index.value++;
  }

  void prev() {
    if (index.value > 0) index.value--;
  }

  Future<void> submit() async {
    if (submitting.value || hasResult) return;
    submitting.value = true;
    error.value = '';
    try {
      final payload = List<int>.generate(
        questions.length,
        (i) => answers[i] ?? -1,
      );
      final res = await repo.submit(contestId, payload);
      result.assignAll(res);
      await load(); // refresh leaderboard + my entry
    } on ApiException catch (e) {
      error.value = e.isNetworkError ? 'You\u2019re offline.' : e.message;
    } finally {
      submitting.value = false;
    }
  }
}
