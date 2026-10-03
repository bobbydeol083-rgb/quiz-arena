import 'package:get/get.dart';

import '../../core/utils/quiz_engine.dart';
import '../models/models.dart';
import '../providers/api_service.dart';
import '../providers/local_question_bank.dart';
import 'auth_repository.dart';

/// Questions + quiz submission with graceful offline fallback.
///
/// [offline] reflects the *last* fetch: views show the "Offline demo" chip
/// when true. The app never throws to the UI for connectivity problems —
/// it falls back to the bundled bank and local grading.
class QuizRepository {
  final ApiService api;
  final LocalQuestionBank bank;
  final AuthRepository auth;

  /// True when the last question fetch / submit used the offline path.
  final RxBool offline = false.obs;

  QuizRepository({
    required this.api,
    required this.bank,
    required this.auth,
  });

  Future<List<QuizCategory>> getCategories() async {
    try {
      final list = await api.categories();
      if (list.isEmpty) return QuizCategory.localDefaults();
      offline.value = false;
      return list.map(QuizCategory.fromJson).toList();
    } on ApiException catch (e) {
      // Any backend failure (not just network loss) falls back to the
      // bundled bank — the home screen must never break on API errors.
      offline.value = e.isNetworkError;
      return QuizCategory.localDefaults();
    }
  }

  Future<QuestionPack> getQuestions({
    String? categoryId,
    String? difficulty,
    int count = 10,
    String mode = 'solo',
  }) async {
    // Daily challenge is a deterministic set — identical for every player
    // on a given day, even offline.
    if (mode == 'daily') {
      final questions = await bank.dailySet(count: count);
      offline.value = false;
      return QuestionPack(questions: questions, offline: false);
    }

    try {
      final list = await api.questions(
        category: categoryId,
        difficulty: difficulty,
        count: count,
      );
      offline.value = false;
      if (list.isEmpty) throw const ApiException('Empty question set');
      return QuestionPack(
        questions: list.map(Question.fromJson).toList(),
        offline: false,
      );
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      offline.value = true;
      final questions = await bank.pick(
        categoryId: categoryId,
        difficulty: difficulty,
        count: count,
      );
      return QuestionPack(questions: questions, offline: true);
    }
  }

  Future<QuizSubmitResult> submitQuiz({
    required String mode,
    String? categoryId,
    String? difficulty,
    required List<AnswerPayload> answers,
    required DateTime startedAt,
    required List<Question> questions,
  }) async {
    try {
      final json = await api.submitQuiz(
        mode: mode,
        category: categoryId,
        difficulty: difficulty,
        answers: answers.map((a) => a.toJson()).toList(),
        startedAt: startedAt.toIso8601String(),
      );
      offline.value = false;
      return QuizSubmitResult.fromJson(json);
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      offline.value = true;
      final user = auth.currentUser.value;
      return QuizEngine.gradeOffline(
        questions: questions,
        answers: answers,
        mode: mode,
        categoryId: categoryId,
        difficulty: difficulty,
        previousXp: user?.xp ?? 0,
        previousStreak: user?.streak ?? 0,
      );
    }
  }
}
