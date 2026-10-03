import 'dart:async';

import 'package:get/get.dart';

import 'package:quiz_arena/app/data/models/question.dart';
import 'package:quiz_arena/app/data/models/result.dart';
import 'package:quiz_arena/app/data/providers/local_question_bank.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';

/// Timed exam: 20 questions, 20 minutes, graded at the end.
class ExamController extends GetxController {
  final LocalQuestionBank bank;
  final AuthRepository auth;
  final ProgressRepository progress;
  final CoinLedger ledger;

  ExamController({
    required this.bank,
    required this.auth,
    required this.progress,
    required this.ledger,
  });

  static const int questionCount = 20;
  static const int totalSeconds = 20 * 60;

  final RxList<Question> questions = <Question>[].obs;
  final RxInt index = 0.obs;
  final RxMap<int, int> answers = <int, int>{}.obs; // qIndex -> optionIndex
  final RxInt secondsLeft = totalSeconds.obs;
  final RxBool finished = false.obs;
  final RxBool loading = true.obs;

  Timer? _timer;

  int get correctCount {
    var n = 0;
    for (final e in answers.entries) {
      if (questions[e.key].answerIndex == e.value) n++;
    }
    return n;
  }

  double get accuracy =>
      questions.isEmpty ? 0 : correctCount / questions.length;

  String get grade {
    final a = accuracy;
    if (a >= 0.9) return 'A+';
    if (a >= 0.8) return 'A';
    if (a >= 0.7) return 'B';
    if (a >= 0.6) return 'C';
    if (a >= 0.5) return 'D';
    return 'F';
  }

  String get timeLabel {
    final m = secondsLeft.value ~/ 60;
    final s = secondsLeft.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    _start();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _start() async {
    loading.value = true;
    try {
      final qs = await bank.pick(count: questionCount);
      questions.assignAll(qs);
      index.value = 0;
      answers.clear();
      finished.value = false;
      secondsLeft.value = totalSeconds;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft.value <= 1) {
          t.cancel();
          finish();
        } else {
          secondsLeft.value--;
        }
      });
    } finally {
      loading.value = false;
    }
  }

  void select(int optionIndex) {
    if (finished.value) return;
    answers[index.value] = optionIndex;
  }

  void next() {
    if (index.value + 1 < questions.length) index.value++;
  }

  void prev() {
    if (index.value > 0) index.value--;
  }

  void jumpTo(int i) {
    if (i >= 0 && i < questions.length) index.value = i;
  }

  Future<void> finish() async {
    if (finished.value) return;
    _timer?.cancel();
    finished.value = true;
    final correct = correctCount;
    final xp = correct * 10;
    final coins = (correct * 2);
    await auth.addCoins(coins);
    if (coins > 0) await ledger.record(coins, 'Exam completed');
    await progress.recordGame(QuizSubmitResult(
      score: correct * 10,
      correct: correct,
      total: questions.length,
      xpEarned: xp,
      coinsEarned: 0,
      newBadges: const [],
      levelUp: false,
      newLevel: 1,
      streak: 0,
      bestStreak: 0,
      fastestAnswerMs: 0,
      accuracy: accuracy,
      mode: 'exam',
    ));
  }

  Future<void> retake() => _start();
}
