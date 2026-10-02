import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/level_config.dart';
import '../../../core/utils/quiz_engine.dart';
import '../../../core/values/app_config.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/api_service.dart';
import '../../../data/providers/socket_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../routes/app_routes.dart';

/// Game modes supported by the quiz player.
enum QuizMode { solo, blitz, marathon, daily, duel, party }

extension QuizModeX on QuizMode {
  String get apiValue => name;

  String get title {
    switch (this) {
      case QuizMode.solo:
        return 'Solo Quiz';
      case QuizMode.blitz:
        return 'Blitz';
      case QuizMode.marathon:
        return 'Marathon';
      case QuizMode.daily:
        return 'Daily Challenge';
      case QuizMode.duel:
        return 'Duel';
      case QuizMode.party:
        return 'Party Room';
    }
  }

  String get subtitle {
    switch (this) {
      case QuizMode.solo:
        return '10 questions · your pace';
      case QuizMode.blitz:
        return '60 seconds · as many as you can';
      case QuizMode.marathon:
        return 'Endless · 3 lives · ramping difficulty';
      case QuizMode.daily:
        return 'One fixed set per day';
      case QuizMode.duel:
        return 'Realtime 1v1 battle';
      case QuizMode.party:
        return 'Room battle with friends';
    }
  }

  String get emoji {
    switch (this) {
      case QuizMode.solo:
        return '🎯';
      case QuizMode.blitz:
        return '⚡';
      case QuizMode.marathon:
        return '🏃';
      case QuizMode.daily:
        return '📅';
      case QuizMode.duel:
        return '⚔️';
      case QuizMode.party:
        return '🎉';
    }
  }
}

/// Arguments for [Routes.quiz].
class QuizArgs {
  final QuizMode mode;
  final String? categoryId;
  final String? difficulty; // easy | medium | hard
  final List<Question>? questions; // pre-fetched (duel / party)
  final String? roomId;
  final String? opponentName;
  final String? opponentId;
  /// Set when playing an installed game pack: questions are custom, so the
  /// game is always graded locally (the server never saw these questions).
  final String? packId;

  QuizArgs({
    required this.mode,
    this.categoryId,
    this.difficulty,
    this.questions,
    this.roomId,
    this.opponentName,
    this.opponentId,
    this.packId,
  });
}

/// The quiz game engine controller.
///
/// Lifecycle: [startGame] loads questions -> per-question countdown ->
/// [selectOption] reveals -> auto-advance -> [completeGame] grades +
/// persists -> navigates to [Routes.results].
///
/// Scoring delegates to [QuizEngine]. Works fully offline: when the API is
/// unreachable the bundled bank is used and grading happens locally.
class QuizController extends GetxController {
  final QuizRepository quizRepo;
  final AuthRepository auth;
  final ProgressRepository progressRepo;
  final SocketService socket;
  final QuizArgs? _injectedArgs;

  QuizController({
    required this.quizRepo,
    required this.auth,
    required this.progressRepo,
    required this.socket,
    QuizArgs? args,
  }) : _injectedArgs = args;

  // ---- Configuration ------------------------------------------------------
  late final QuizMode mode;
  String? categoryId;
  String? difficulty;
  String? roomId;
  String? packId;

  int get questionTimeMs {
    switch (mode) {
      case QuizMode.blitz:
        return 20000; // generous per-question; the 60s total is the limit
      case QuizMode.marathon:
      case QuizMode.duel:
      case QuizMode.party:
        return AppConfig.marathonQuestionSeconds * 1000;
      case QuizMode.solo:
      case QuizMode.daily:
        return AppConfig.soloQuestionSeconds * 1000;
    }
  }

  int get questionCount {
    switch (mode) {
      case QuizMode.blitz:
        return 40;
      case QuizMode.marathon:
        return 40;
      case QuizMode.solo:
      case QuizMode.daily:
        return AppConfig.soloQuestionCount;
      case QuizMode.duel:
      case QuizMode.party:
        return 10;
    }
  }

  bool get isRealtime => mode == QuizMode.duel || mode == QuizMode.party;

  // ---- Reactive state -------------------------------------------------------
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxList<Question> questions = <Question>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxInt selectedIndex = (-1).obs;
  final RxBool revealed = false.obs;
  final RxBool wasCorrect = false.obs;
  final RxInt timeLeftMs = 0.obs;
  final RxInt blitzLeftMs = 0.obs;
  final RxInt score = 0.obs;
  final RxInt streak = 0.obs;
  final RxInt correctCount = 0.obs;
  final RxInt lives = 3.obs;
  final RxBool isOffline = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isFinished = false.obs;

  // Duel / party live state.
  final RxInt opponentScore = 0.obs;
  final RxString opponentName = ''.obs;

  /// Realtime: the local player answered everything and is waiting for the
  /// server's `game:end` (which grades + persists rewards for everyone).
  final RxBool waitingForOpponent = false.obs;

  // ---- Internals ---------------------------------------------------------------
  Timer? _ticker;
  bool _active = true;
  bool _advancing = false;
  DateTime? _questionStartedAt;
  DateTime? _gameStartedAt;
  final List<AnswerPayload> _answers = [];
  int _fastestMs = 0;
  int _bestStreak = 0;

  /// Raw `game:end` payload from the server; the single source of truth for
  /// realtime results (the server already graded + persisted rewards).
  Map<String, dynamic>? _realtimeEndPayload;

  Question get currentQuestion => questions[currentIndex.value];
  int get totalQuestions => questions.length;
  double get timeProgress =>
      (timeLeftMs.value / questionTimeMs).clamp(0.0, 1.0);
  int get secondsLeft => (timeLeftMs.value / 1000).ceil();
  int get blitzSecondsLeft => (blitzLeftMs.value / 1000).ceil();

  /// Null when the backend hid the answer (online grading) — the UI then
  /// shows a neutral "locked in" reveal instead of correct/wrong colors.
  bool get isAnswerKnown => currentQuestion.answerIndex != null;

  double get accuracy =>
      _answers.isEmpty ? 0 : correctCount.value / _answers.length;

  @override
  void onInit() {
    super.onInit();
    final args = _injectedArgs ?? _readArgs();
    mode = args.mode;
    categoryId = args.categoryId;
    difficulty = args.difficulty;
    roomId = args.roomId;
    packId = args.packId;
    opponentName.value = args.opponentName ?? '';
    lives.value = AppConfig.marathonLives;
    if (isRealtime) _attachSocketListeners();
    startGame(preloaded: args.questions);
  }

  QuizArgs _readArgs() {
    final a = Get.arguments;
    if (a is QuizArgs) return a;
    return QuizArgs(mode: QuizMode.solo);
  }

  // ---- Game flow ---------------------------------------------------------------

  /// Loads questions (pre-fetched, API, or offline bank) and starts Q1.
  Future<void> startGame({List<Question>? preloaded}) async {
    isLoading.value = true;
    error.value = '';
    _resetRunState();
    _gameStartedAt = DateTime.now();
    try {
      late QuestionPack pack;
      if (preloaded != null && preloaded.isNotEmpty) {
        pack = QuestionPack(questions: preloaded, offline: false);
      } else if (mode == QuizMode.marathon) {
        // Difficulty ramps: easy -> medium -> hard buckets.
        pack = await quizRepo.getQuestions(
          categoryId: categoryId,
          count: questionCount,
          mode: mode.apiValue,
        );
        if (pack.offline) {
          final mixed = await quizRepo.bank.pick(
            categoryId: categoryId,
            difficulties: const ['easy', 'medium', 'hard'],
            count: questionCount,
          );
          pack = QuestionPack(questions: mixed, offline: true);
        }
      } else {
        pack = await quizRepo.getQuestions(
          categoryId: categoryId,
          difficulty: difficulty,
          count: questionCount,
          mode: mode.apiValue,
        );
      }
      if (pack.questions.isEmpty) {
        throw const ApiException('No questions available.');
      }
      questions.assignAll(pack.questions);
      isOffline.value = pack.offline;
      _startQuestion();
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = 'Something went wrong: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() => startGame();

  void _resetRunState() {
    _active = true;
    _advancing = false;
    currentIndex.value = 0;
    score.value = 0;
    streak.value = 0;
    correctCount.value = 0;
    lives.value = AppConfig.marathonLives;
    blitzLeftMs.value = 0;
    isFinished.value = false;
    opponentScore.value = 0;
    _answers.clear();
    _fastestMs = 0;
    _bestStreak = 0;
    waitingForOpponent.value = false;
    _realtimeEndPayload = null;
    _ticker?.cancel();
  }

  void _startQuestion() {
    if (!_active || isFinished.value) return;
    selectedIndex.value = -1;
    revealed.value = false;
    wasCorrect.value = false;
    _advancing = false;
    timeLeftMs.value = questionTimeMs;
    _questionStartedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_active) {
        t.cancel();
        return;
      }
      timeLeftMs.value -= 100;
      if (mode == QuizMode.blitz) {
        blitzLeftMs.value -= 100;
        if (blitzLeftMs.value <= 0) {
          t.cancel();
          finishAndShowResults();
          return;
        }
      }
      if (timeLeftMs.value <= 0) {
        t.cancel();
        _onTimeout();
      }
    });
    if (mode == QuizMode.blitz && blitzLeftMs.value <= 0) {
      blitzLeftMs.value = AppConfig.blitzTotalSeconds * 1000;
    }
  }

  void _onTimeout() {
    if (revealed.value || isFinished.value) return;
    _reveal(selected: -1, timedOut: true);
  }

  /// Player taps an option.
  void selectOption(int index) {
    if (revealed.value || isFinished.value || isLoading.value) return;
    if (index < 0 || index >= currentQuestion.options.length) return;
    _reveal(selected: index, timedOut: false);
  }

  void _reveal({required int selected, required bool timedOut}) {
    _ticker?.cancel();
    selectedIndex.value = selected;
    revealed.value = true;

    final q = currentQuestion;
    final timeMs = _questionStartedAt == null
        ? questionTimeMs
        : DateTime.now().difference(_questionStartedAt!).inMilliseconds;
    final correct =
        !timedOut && q.answerIndex != null && selected == q.answerIndex;
    wasCorrect.value = correct;

    if (correct) {
      final gained = QuizEngine.scoreForAnswer(
        correct: true,
        timeMs: timeMs,
        streak: streak.value + 1,
        difficulty: q.difficulty,
        questionTimeLimitMs: questionTimeMs,
      );
      score.value += gained;
      streak.value += 1;
      if (streak.value > _bestStreak) _bestStreak = streak.value;
      correctCount.value += 1;
      if (_fastestMs == 0 || timeMs < _fastestMs) _fastestMs = timeMs;
    } else {
      streak.value = 0;
      if (mode == QuizMode.marathon) {
        lives.value -= 1;
      }
    }

    _answers.add(AnswerPayload(
      questionId: q.id,
      selectedIndex: selected,
      timeMs: timeMs.clamp(0, questionTimeMs),
    ));

    if (isRealtime) {
      socket.sendAnswer(q.id, selected);
    }

    // Brief reveal beat, then advance (snappier in blitz).
    final beat =
        mode == QuizMode.blitz ? 800 : 1400;
    Future.delayed(Duration(milliseconds: beat), () {
      if (!_active || _advancing) return;
      _advancing = true;
      _advance();
    });
  }

  void _advance() {
    if (!_active || isFinished.value) return;
    if (mode == QuizMode.marathon && lives.value <= 0) {
      finishAndShowResults();
      return;
    }
    if (currentIndex.value + 1 >= questions.length) {
      if (isRealtime) {
        // Don't finish locally: the server ends the game for everyone at
        // once (grading + rewards) and emits game:end. Show the waiting
        // state until it arrives.
        _ticker?.cancel();
        waitingForOpponent.value = true;
        return;
      }
      finishAndShowResults();
      return;
    }
    currentIndex.value += 1;
    _startQuestion();
  }

  /// Skip ahead (blitz) / give up on the current question.
  void skipQuestion() {
    if (revealed.value || isFinished.value) return;
    _reveal(selected: -1, timedOut: true);
  }

  /// Finish early (blitz "done" button, quit flows call [quitQuiz]).
  Future<void> finishEarly() => finishAndShowResults();

  /// Grades, persists rewards + badges, then routes to the results screen.
  /// Returns the result (useful for tests); navigation is skipped in tests
  /// because this method itself never navigates — see [finishAndShowResults].
  Future<QuizSubmitResult?> completeGame() async {
    if (isFinished.value) return null;
    isFinished.value = true;
    _ticker?.cancel();
    waitingForOpponent.value = false;
    isSubmitting.value = true;
    try {
      final QuizSubmitResult result;
      if (isRealtime) {
        // The server graded, persisted GameResults and applied XP / coins /
        // badges / streak on game:end — a REST submit here would double-award.
        result = _buildRealtimeResult();
        // Keep the local progress counters in sync (server badges are
        // authoritative, so locally evaluated badges are not merged in).
        await progressRepo.recordGame(result);
      } else {
        final QuizSubmitResult rest;
        if (packId != null) {
          // Installed game pack: custom questions the server never saw —
          // always grade locally (works offline too).
          final user = auth.currentUser.value;
          rest = QuizEngine.gradeOffline(
            questions: List.unmodifiable(questions),
            answers: List.unmodifiable(_answers),
            mode: mode.apiValue,
            categoryId: categoryId,
            difficulty: difficulty,
            previousXp: user?.xp ?? 0,
            previousStreak: user?.streak ?? 0,
          );
        } else {
          rest = await quizRepo.submitQuiz(
            mode: mode.apiValue,
            categoryId: categoryId,
            difficulty: difficulty,
            answers: List.unmodifiable(_answers),
            startedAt: _gameStartedAt ?? DateTime.now(),
            questions: List.unmodifiable(questions),
          );
        }

        // Local badge evaluation (server may also return newBadges; merge).
        final localBadges = await progressRepo.recordGame(rest);
        result = rest.copyWith(
            newBadges: {...rest.newBadges, ...localBadges}.toList());
      }

      await auth.applyResult(result);
      isOffline.value = quizRepo.offline.value;
      return result;
    } on ApiException catch (e) {
      error.value = e.message;
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Builds the results object from the server's `game:end` payload:
  /// `{ roomId, reason, winner: {userId,username,avatar}?, scores: [{userId,
  /// score, correct, answered}], rewards: [{userId, xpEarned, coinsEarned,
  /// newBadges, levelUp, newLevel, streak: {count}}] }`.
  QuizSubmitResult _buildRealtimeResult() {
    final myId = '${auth.currentUser.value?.id ?? ''}';
    final end = _realtimeEndPayload ?? const <String, dynamic>{};

    List<Map<String, dynamic>> asMaps(dynamic v) {
      if (v is! List) return const [];
      return [
        for (final e in v)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    }

    final scores = asMaps(end['scores']);
    final rewards = asMaps(end['rewards']);

    Map<String, dynamic> myScore = const {};
    Map<String, dynamic> myReward = const {};
    Map<String, dynamic>? oppScore;
    for (final s in scores) {
      if ('${s['userId'] ?? ''}' == myId) {
        myScore = s;
      } else {
        oppScore ??= s;
      }
    }
    for (final r in rewards) {
      if ('${r['userId'] ?? ''}' == myId) {
        myReward = r;
        break;
      }
    }

    final winner = end['winner'] is Map
        ? Map<String, dynamic>.from(end['winner'] as Map)
        : null;
    final won = winner != null && '${winner['userId'] ?? ''}' == myId;

    final correct = (myScore['correct'] as num?)?.toInt() ?? 0;
    final answered = (myScore['answered'] as num?)?.toInt() ?? 0;
    final total = questions.isNotEmpty ? questions.length : answered;
    final gameScore = (myScore['score'] as num?)?.toInt() ?? 0;
    final oppGameScore =
        (oppScore?['score'] as num?)?.toInt() ?? opponentScore.value;

    String? oppName = opponentName.value.isEmpty ? null : opponentName.value;
    if (winner != null && '${winner['userId'] ?? ''}' != myId) {
      final wName = '${winner['username'] ?? ''}';
      if (wName.isNotEmpty) oppName = wName;
    }
    oppName ??= 'Opponent';

    final streakCount = (myReward['streak'] is Map)
        ? ((myReward['streak'] as Map)['count'] as num?)?.toInt() ?? 0
        : 0;

    return QuizSubmitResult(
      score: gameScore,
      correct: correct,
      total: total,
      xpEarned: (myReward['xpEarned'] as num?)?.toInt() ?? 0,
      coinsEarned: (myReward['coinsEarned'] as num?)?.toInt() ?? 0,
      newBadges: asStrings(myReward['newBadges']),
      levelUp: myReward['levelUp'] == true,
      newLevel: (myReward['newLevel'] as num?)?.toInt() ??
          LevelConfig.levelForXp(auth.currentUser.value?.xp ?? 0),
      streak: streakCount,
      bestStreak: _bestStreak,
      fastestAnswerMs: _fastestMs,
      accuracy: total > 0 ? correct / total : 0,
      mode: mode.apiValue,
      categoryId: categoryId,
      difficulty: 'mixed',
      duelWon: won,
      opponentName: oppName,
      opponentScore: oppGameScore,
    );
  }

  static List<String> asStrings(dynamic v) {
    if (v is! List) return const [];
    return [for (final e in v) '$e'];
  }

  /// [completeGame] + navigation to the results screen.
  Future<void> finishAndShowResults() async {
    final result = await completeGame();
    if (!_active) return;
    if (result == null) {
      Get.snackbar(
        'Could not finish the quiz',
        error.value.isEmpty ? 'Please try again.' : error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.offNamed(Routes.results, arguments: result);
  }

  Future<void> quitQuiz() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Quit quiz?'),
        content: const Text('Your progress in this game will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _active = false;
      _ticker?.cancel();
      if (isRealtime) socket.leaveRoom();
      Get.offNamed(Routes.home);
    }
  }

  // ---- Realtime (duel / party) ---------------------------------------------------

  void _attachSocketListeners() {
    socket.on(SocketEvents.gameScore, _onGameScore);
    socket.on(SocketEvents.gameEnd, _onGameEnd);
  }

  void _onGameEnd(dynamic data) {
    // The server's game:end is the single source of truth for realtime
    // results (it graded + persisted rewards for every player).
    if (data is Map) {
      _realtimeEndPayload = Map<String, dynamic>.from(data);
    }
    finishAndShowResults();
  }

  void _onGameScore(dynamic data) {
    try {
      final myId = '${auth.currentUser.value?.id ?? ''}';
      final List<Map<String, dynamic>> entries = [];
      if (data is Map && data['scores'] is List) {
        // Server shape: scores: [{userId, score, correct, answered}]
        for (final e in (data['scores'] as List)) {
          if (e is Map) entries.add(Map<String, dynamic>.from(e));
        }
      } else if (data is Map && data['scores'] is Map) {
        // Legacy map shape: scores: {userId: score}
        (data['scores'] as Map).forEach((k, v) {
          entries.add({
            'userId': '$k',
            'score': v is Map ? (v['score'] ?? 0) : v,
          });
        });
      } else {
        return;
      }
      for (final e in entries) {
        final uid = '${e['userId'] ?? ''}';
        final s = (e['score'] as num?)?.toInt() ?? 0;
        if (uid.isNotEmpty && uid == myId) {
          // Authoritative: the server owns realtime scoring.
          score.value = s;
        } else {
          opponentScore.value = s;
        }
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    _active = false;
    _ticker?.cancel();
    if (isRealtime) {
      socket.off(SocketEvents.gameScore);
      socket.off(SocketEvents.gameEnd);
      socket.leaveRoom();
    }
    super.onClose();
  }
}
