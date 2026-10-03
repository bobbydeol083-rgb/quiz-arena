import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';
import 'package:quiz_arena/app/data/models/result.dart';

/// A true/false statement from the bundled bank.
class TrueFalseStatement {
  final String statement;
  final bool answer;

  const TrueFalseStatement({required this.statement, required this.answer});

  factory TrueFalseStatement.fromJson(Map<String, dynamic> json) =>
      TrueFalseStatement(
        statement: '${json['statement'] ?? ''}',
        answer: json['answer'] == true,
      );
}

/// True/False speed zone: 10 statements, 10 seconds each.
class TrueFalseController extends GetxController {
  final AuthRepository auth;
  final ProgressRepository progress;
  final CoinLedger ledger;

  TrueFalseController({
    required this.auth,
    required this.progress,
    required this.ledger,
  });

  static const int roundSize = 10;
  static const int secondsPerStatement = 10;

  final RxList<TrueFalseStatement> statements = <TrueFalseStatement>[].obs;
  final RxInt index = 0.obs;
  final RxInt score = 0.obs;
  final RxInt streak = 0.obs;
  final RxInt secondsLeft = secondsPerStatement.obs;
  final RxBool finished = false.obs;
  final RxBool answered = false.obs;
  final RxBool lastCorrect = false.obs;
  final RxBool loading = true.obs;

  int _correctCount = 0;
  int _bestStreak = 0;

  Timer? _timer;

  TrueFalseStatement get current => statements[index.value];

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
      final raw = await rootBundle.loadString('assets/true_false.json');
      final list = (jsonDecode(raw) as List)
          .map((e) => TrueFalseStatement.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList()
        ..shuffle();
      statements.assignAll(list.take(roundSize));
      index.value = 0;
      score.value = 0;
      streak.value = 0;
      _correctCount = 0;
      _bestStreak = 0;
      finished.value = false;
      _beginStatement();
    } finally {
      loading.value = false;
    }
  }

  void _beginStatement() {
    answered.value = false;
    secondsLeft.value = secondsPerStatement;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft.value <= 1) {
        t.cancel();
        _answer(null); // timeout counts as wrong
      } else {
        secondsLeft.value--;
      }
    });
  }

  /// [value] true/false, or null on timeout.
  Future<void> _answer(bool? value) async {
    if (answered.value || finished.value) return;
    answered.value = true;
    _timer?.cancel();

    final correct = value != null && value == current.answer;
    lastCorrect.value = correct;
    if (correct) {
      _correctCount++;
      streak.value++;
      _bestStreak = _bestStreak > streak.value ? _bestStreak : streak.value;
      // 10 pts + streak bonus, capped.
      score.value += 10 + (streak.value - 1).clamp(0, 10);
    } else {
      streak.value = 0;
    }
    await Future.delayed(const Duration(milliseconds: 650));
    if (index.value + 1 >= statements.length) {
      await _finish();
    } else {
      index.value++;
      _beginStatement();
    }
  }

  void answerTrue() => _answer(true);
  void answerFalse() => _answer(false);

  Future<void> _finish() async {
    finished.value = true;
    final xp = score.value;
    final coins = (score.value / 10).floor();
    final correctCount = _correctCount;
    await auth.addCoins(coins);
    if (coins > 0) await ledger.record(coins, 'True/False zone');
    await progress.recordGame(QuizSubmitResult(
      score: score.value,
      correct: correctCount,
      total: statements.length,
      xpEarned: xp,
      coinsEarned: 0, // already credited above
      newBadges: const [],
      levelUp: false,
      newLevel: 1,
      streak: 0,
      bestStreak: _bestStreak,
      fastestAnswerMs: 0,
      accuracy:
          statements.isEmpty ? 0 : correctCount / statements.length,
      mode: 'true_false',
    ));
  }

  Future<void> playAgain() => _start();
}
