import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/providers/local_question_bank.dart';
import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';
import 'package:quiz_arena/app/core/utils/badge_service.dart';
import 'package:quiz_arena/app/core/utils/quiz_engine.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';

/// Offline-only fake: questions come from the seed list, grading is local.
class _FakeQuizRepo extends QuizRepository {
  final List<Question> seed;

  _FakeQuizRepo({required this.seed, required AuthRepository auth})
      : super(
          api: ApiService(baseUrl: 'http://127.0.0.1:1'),
          bank: LocalQuestionBank(),
          auth: auth,
        );

  @override
  Future<QuestionPack> getQuestions({
    String? categoryId,
    String? difficulty,
    int count = 10,
    String mode = 'solo',
  }) async {
    offline.value = true;
    return QuestionPack(questions: seed.take(count).toList(), offline: true);
  }

  @override
  Future<QuizSubmitResult> submitQuiz({
    required String mode,
    String? categoryId,
    String? difficulty,
    required List<AnswerPayload> answers,
    required DateTime startedAt,
    required List<Question> questions,
  }) async {
    return QuizEngine.gradeOffline(
      questions: questions,
      answers: answers,
      mode: mode,
      categoryId: categoryId,
      difficulty: difficulty,
      previousXp: 0,
    );
  }
}

List<Question> _seedQuestions() => [
      const Question(
        id: 'q1',
        category: 'science',
        difficulty: 'easy',
        question: 'Q1?',
        options: ['A', 'B', 'C', 'D'],
        answerIndex: 0,
      ),
      const Question(
        id: 'q2',
        category: 'science',
        difficulty: 'hard',
        question: 'Q2?',
        options: ['A', 'B', 'C', 'D'],
        answerIndex: 2,
      ),
      const Question(
        id: 'q3',
        category: 'science',
        difficulty: 'medium',
        question: 'Q3?',
        options: ['A', 'B', 'C', 'D'],
        answerIndex: 1,
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Make GetStorage.init() work in tests (path_provider has no real
    // implementation under flutter_test).
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/quiz_arena_test';
      }
      return null;
    });
    await GetStorage.init();
    Get.testMode = true;
  });

  tearDown(() => Get.reset());

  QuizController _controller() {
    final auth = AuthRepository(
      api: ApiService(baseUrl: 'http://127.0.0.1:1'),
    );
    auth.currentUser.value = AppUser.demo();
    final c = QuizController(
      quizRepo: _FakeQuizRepo(seed: _seedQuestions(), auth: auth),
      auth: auth,
      progressRepo: ProgressRepository(badges: BadgeService()),
      socket: SocketService(),
      args: QuizArgs(
        mode: QuizMode.solo,
        categoryId: 'science',
        difficulty: 'easy',
      ),
    );
    // Run the real GetX lifecycle: onInit assigns mode/config from args.
    Get.put(c);
    return c;
  }

  group('QuizController', () {
    test('loads questions and starts the first question', () async {
      final c = _controller();
      await c.startGame();
      expect(c.isLoading.value, false);
      expect(c.error.value, isEmpty);
      expect(c.questions.length, 3);
      expect(c.currentIndex.value, 0);
      expect(c.timeLeftMs.value, greaterThan(0));
      expect(c.isOffline.value, true);
      c.onClose();
    });

    test('correct answer: score/streak grow, reveal shows', () async {
      final c = _controller();
      await c.startGame();
      final before = c.score.value;
      c.selectOption(0); // q1 answerIndex == 0
      expect(c.revealed.value, true);
      expect(c.wasCorrect.value, true);
      expect(c.selectedIndex.value, 0);
      expect(c.streak.value, 1);
      expect(c.correctCount.value, 1);
      expect(c.score.value, greaterThan(before));
      c.onClose();
    });

    test('wrong answer: streak resets, no score', () async {
      final c = _controller();
      await c.startGame();
      c.selectOption(3); // q1 answerIndex == 0 -> wrong
      expect(c.revealed.value, true);
      expect(c.wasCorrect.value, false);
      expect(c.streak.value, 0);
      expect(c.score.value, 0);
      expect(c.correctCount.value, 0);
      c.onClose();
    });

    test('streak builds across questions then resets on a miss', () async {
      final c = _controller();
      await c.startGame();
      c.selectOption(0); // q1 correct -> streak 1
      expect(c.streak.value, 1);
      await Future.delayed(const Duration(milliseconds: 1600)); // reveal beat
      expect(c.currentIndex.value, 1);
      c.selectOption(2); // q2 answerIndex == 2 -> correct, streak 2
      expect(c.streak.value, 2);
      await Future.delayed(const Duration(milliseconds: 1600));
      expect(c.currentIndex.value, 2);
      c.selectOption(0); // q3 answerIndex == 1 -> wrong, streak 0
      expect(c.streak.value, 0);
      expect(c.wasCorrect.value, false);
      c.onClose();
    });

    test('completeGame grades the answers and returns a result', () async {
      final c = _controller();
      await c.startGame();
      c.selectOption(0); // q1 correct
      await Future.delayed(const Duration(milliseconds: 1600));
      c.selectOption(2); // q2 correct
      final result = await c.completeGame();
      expect(result, isNotNull);
      expect(result!.correct, 2);
      expect(result.total, 3);
      expect(result.score, greaterThan(0));
      expect(result.xpEarned, result.score ~/ 10);
      expect(result.accuracy, closeTo(2 / 3, 0.001));
      expect(c.isFinished.value, true);
      c.onClose();
    });

    test('selectOption is ignored after reveal', () async {
      final c = _controller();
      await c.startGame();
      c.selectOption(0);
      final scoreAfterFirst = c.score.value;
      c.selectOption(1); // second tap must be ignored
      expect(c.selectedIndex.value, 0);
      expect(c.score.value, scoreAfterFirst);
      c.onClose();
    });
  });
}
