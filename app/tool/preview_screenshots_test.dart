// Preview golden screenshots — renders the REAL app screens with
// mock-driven controller state and writes PNGs (run with --update-goldens).
// Not a functional test; excluded from CI goldens.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/providers/local_question_bank.dart';
import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/pack_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/repositories/quiz_repository.dart';
import 'package:quiz_arena/app/core/utils/badge_service.dart';
import 'package:quiz_arena/app/modules/bluff/controllers/bluff_controller.dart';
import 'package:quiz_arena/app/modules/bluff/views/bluff_view.dart';
import 'package:quiz_arena/app/modules/bookmarks/views/bookmarks_view.dart';
import 'package:quiz_arena/app/modules/contest/controllers/contest_controller.dart';
import 'package:quiz_arena/app/modules/contest/controllers/contest_play_controller.dart';
import 'package:quiz_arena/app/modules/contest/views/contest_detail_view.dart';
import 'package:quiz_arena/app/modules/contest/views/contest_view.dart';
import 'package:quiz_arena/app/modules/home/controllers/home_controller.dart';
import 'package:quiz_arena/app/modules/home/views/home_view.dart';
import 'package:quiz_arena/app/modules/packs/controllers/pack_editor_controller.dart';
import 'package:quiz_arena/app/modules/packs/controllers/packs_controller.dart';
import 'package:quiz_arena/app/modules/packs/views/pack_editor_view.dart';
import 'package:quiz_arena/app/modules/packs/views/packs_view.dart';
import 'package:quiz_arena/app/modules/rewards/controllers/daily_reward_controller.dart';
import 'package:quiz_arena/app/modules/rewards/controllers/refer_earn_controller.dart';
import 'package:quiz_arena/app/modules/rewards/views/daily_reward_view.dart';
import 'package:quiz_arena/app/modules/rewards/views/refer_earn_view.dart';
import 'package:quiz_arena/app/modules/statistics/controllers/statistics_controller.dart';
import 'package:quiz_arena/app/modules/statistics/views/statistics_view.dart';
import 'package:quiz_arena/app/modules/wallet/views/wallet_view.dart';
import 'package:quiz_arena/app/modules/zones/controllers/exam_controller.dart';
import 'package:quiz_arena/app/modules/zones/controllers/true_false_controller.dart';
import 'package:quiz_arena/app/modules/zones/views/exam_view.dart';
import 'package:quiz_arena/app/modules/zones/views/true_false_view.dart';
import 'package:quiz_arena/app/data/repositories/bookmark_repository.dart';
import 'package:quiz_arena/app/data/repositories/contest_repository.dart';
import 'package:quiz_arena/app/data/repositories/rewards_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';

const _fontDir =
    '/home/hatch/sdks/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  final loader = FontLoader('Roboto')
    ..addFont(File('$_fontDir/Roboto-Regular.ttf')
        .readAsBytes()
        .then((b) => ByteData.sublistView(b)))
    ..addFont(File('$_fontDir/Roboto-Bold.ttf')
        .readAsBytes()
        .then((b) => ByteData.sublistView(b)));
  await loader.load();
}

/// Test-only replica of AppTheme.light(): identical colors, shapes and
/// spacing, but plain Roboto text (google_fonts can't fetch Inter/Sora
/// under flutter_test and throws). Layout and widgets are the real code.
ThemeData _theme() {
  const scheme = ColorScheme.light(
    primary: AppColors.blue,
    secondary: AppColors.sky,
    tertiary: AppColors.bubble,
    surface: AppColors.lightSurface,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.lightText,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBg,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.lightText),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.lightText),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.lightText),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightText),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightText),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.lightText),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.lightText),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightText),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.lightText,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.lightTextMuted),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightText,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}

void _deps() {
  final api = ApiService(baseUrl: 'http://127.0.0.1:1');
  Get.put<SocketService>(SocketService());
  final auth = AuthRepository(api: api);
  auth.currentUser.value = AppUser.demo();
  Get.put<AuthRepository>(auth);
  Get.put<PackRepository>(PackRepository(api: api));
}

BluffController _bluff() {
  final c = BluffController(
    socket: Get.find<SocketService>(),
    auth: Get.find<AuthRepository>(),
  );
  Get.put<BluffController>(c);
  c.totalRounds.value = 5;
  return c;
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: screen,
    ),
  );
  // Settle entrance animations without waiting on the 1s ticker forever.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _golden(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/preview_$name.png'),
  );
}

/// BluffController runs a 1s countdown ticker; close it explicitly so the
/// test framework's pending-timer invariant is satisfied.
void _closeBluff() {
  if (Get.isRegistered<BluffController>()) {
    Get.delete<BluffController>(force: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/quiz_arena_preview';
      }
      return null;
    });
    await GetStorage.init();
    await _loadFonts();
    // google_fonts can't fetch in tests (no network) — Elite widgets fall
    // back to the bundled test font instead of throwing.
    EliteTheme.useSystemFont = true;
    Get.testMode = true;
  });

  tearDown(() => Get.reset());

  testWidgets('preview: home', (tester) async {
    _deps();
    final api = ApiService(baseUrl: 'http://127.0.0.1:1');
    final auth = Get.find<AuthRepository>();
    auth.currentUser.value = const AppUser(
      id: 'local-demo',
      username: 'Boss',
      email: 'boss@example.com',
      xp: 1250,
      level: 4,
      coins: 350,
      streak: 6,
    );
    final quizRepo = QuizRepository(
      api: api,
      bank: LocalQuestionBank(),
      auth: auth,
    );
    final badges = BadgeService();
    Get.put<BadgeService>(badges);
    final progressRepo = ProgressRepository(badges: badges);
    Get.put<ProgressRepository>(progressRepo);
    final c = HomeController(
      quizRepo: quizRepo,
      auth: auth,
      progressRepo: progressRepo,
    );
    Get.put<HomeController>(c);
    await _pumpScreen(tester, const HomeView());
    // Network is unreachable in tests -> repo falls back to the bundled
    // bank and flags offline; hide the chip for a clean preview.
    c.offline.value = false;
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'home');
  });

  testWidgets('preview: bluff write phase', (tester) async {
    _deps();
    final c = _bluff();
    c.round.value = 2;
    c.question.value =
        "What animal's collective noun is 'a parliament'?";
    c.fakesIn.value = 2;
    c.fakesTotal.value = 4;
    c.writeEndsAt.value =
        DateTime.now().millisecondsSinceEpoch + 22000;
    c.phase.value = BluffPhase.write;
    await _pumpScreen(tester, const BluffView());
    await _golden(tester, 'bluff_write');
    _closeBluff();
  });

  testWidgets('preview: bluff vote phase', (tester) async {
    _deps();
    final c = _bluff();
    c.round.value = 2;
    c.options.assignAll(const [
      BluffOption(id: 'truth', text: 'Owls'),
      BluffOption(id: 'fake:u2', text: 'Crows'),
      BluffOption(id: 'fake:u3', text: 'Penguins'),
      BluffOption(id: 'fake:local-demo', text: 'Parrots'),
    ]);
    c.voteEndsAt.value =
        DateTime.now().millisecondsSinceEpoch + 14000;
    c.phase.value = BluffPhase.vote;
    await _pumpScreen(tester, const BluffView());
    await _golden(tester, 'bluff_vote');
    _closeBluff();
  });

  testWidgets('preview: bluff reveal phase', (tester) async {
    _deps();
    final c = _bluff();
    c.round.value = 2;
    c.correctOptionId.value = 'truth';
    c.options.assignAll(const [
      BluffOption(id: 'truth', text: 'Owls'),
      BluffOption(id: 'fake:u2', text: 'Crows', authorId: 'u2'),
      BluffOption(id: 'fake:u3', text: 'Penguins', authorId: 'u3'),
      BluffOption(id: 'fake:local-demo', text: 'Parrots', authorId: 'local-demo'),
    ]);
    c.deltas.assignAll(const [
      BluffDelta(userId: 'local-demo', delta: 100, votedTruth: false, fooled: 2),
      BluffDelta(userId: 'u2', delta: 150, votedTruth: true, fooled: 1),
      BluffDelta(userId: 'u3', delta: 50, votedTruth: false, fooled: 1),
    ]);
    c.scores.assignAll(const [
      BluffScore(userId: 'local-demo', score: 325, truths: 1, fooled: 3),
      BluffScore(userId: 'u2', score: 280, truths: 2, fooled: 1),
    ]);
    c.roast.value = 'The truth was RIGHT THERE and you walked past it.';
    c.phase.value = BluffPhase.reveal;
    await _pumpScreen(tester, const BluffView());
    await _golden(tester, 'bluff_reveal');
    _closeBluff();
  });

  testWidgets('preview: bluff final standings', (tester) async {
    _deps();
    final c = _bluff();
    c.round.value = 5;
    c.scores.assignAll(const [
      BluffScore(userId: 'local-demo', score: 640, truths: 3, fooled: 8),
      BluffScore(userId: 'u2', score: 510, truths: 4, fooled: 2),
      BluffScore(userId: 'u3', score: 220, truths: 1, fooled: 1),
    ]);
    c.titles.assignAll({
      'local-demo': 'Master Deceiver',
      'u2': 'Truth Hunter',
      'u3': 'Bluff Rookie',
    });
    c.winner.value = {'userId': 'local-demo', 'username': 'Boss'};
    c.phase.value = BluffPhase.done;
    await _pumpScreen(tester, const BluffView());
    await _golden(tester, 'bluff_done');
    _closeBluff();
  });

  testWidgets('preview: game packs browse', (tester) async {
    _deps();
    final c = PacksController(packs: Get.find<PackRepository>());
    Get.put<PacksController>(c);
    c.browsePacks.assignAll([
      const GamePack(
        id: 'p1',
        title: 'Desi Pop Culture',
        slug: 'p1',
        description: 'A community pack full of Fake Facts trivia.',
        label: 'Fake Facts',
        mode: 'bluff',
        questionCount: 12,
        authorName: 'quizfan',
        installs: 482,
        plays: 1204,
      ),
      const GamePack(
        id: 'p2',
        title: 'Weird Science',
        slug: 'p2',
        description: 'A community pack full of Weird Science trivia.',
        label: 'Weird Science',
        mode: 'quiz',
        questionCount: 20,
        authorName: 'labrat',
        installs: 351,
        plays: 980,
      ),
    ]);
    await _pumpScreen(tester, const PacksView());
    await _golden(tester, 'packs');
  });

  testWidgets('preview: pack editor', (tester) async {
    _deps();
    final c =
        PackEditorController(packs: Get.find<PackRepository>());
    Get.put<PackEditorController>(c);
    c.titleCtrl.text = 'Desi Pop Culture';
    c.labelCtrl.text = 'Fake Facts';
    c.mode.value = 'bluff';
    c.questions[0].question.text =
        "What animal's collective noun is 'a parliament'?";
    c.questions[0].options[0].text = 'Owls';
    c.questions[0].options[1].text = 'Crows';
    c.questions[0].options[2].text = 'Parrots';
    c.questions[0].options[3].text = 'Penguins';
    await _pumpScreen(tester, const PackEditorView());
    await _golden(tester, 'pack_editor');
  });

  // ---- Elite harvest previews --------------------------------------------

  ContestCard _mockContest(String id, String name, String phase,
      {int fee = 0, bool played = false}) {
    final now = DateTime.now();
    return ContestCard(
      id: id,
      name: name,
      description: 'Answer 10 questions. Top ranks split the prize pool.',
      image: '',
      startDate: now.subtract(const Duration(hours: 1)),
      endDate: now.add(const Duration(hours: 5)),
      entryFee: fee,
      phase: phase,
      prizePool: 500,
      prizeCount: 3,
      questionCount: 10,
      participants: 128,
      played: played,
    );
  }

  testWidgets('preview: contests lobby', (tester) async {
    _deps();
    final c = ContestController(
      repo: ContestRepository(api: ApiService(baseUrl: 'http://127.0.0.1:1')),
    );
    Get.put<ContestController>(c);
    await _pumpScreen(tester, const ContestView());
    c.contests.assignAll([
      _mockContest('1', 'Sunday Showdown', 'live', fee: 50),
      _mockContest('2', 'Morning Blitz', 'live', played: true),
      _mockContest('3', 'Diwali Mega Contest', 'upcoming', fee: 100),
      _mockContest('4', 'Friday Faceoff', 'ended', played: true),
    ]);
    c.loading.value = false;
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'contests');
  });

  testWidgets('preview: contest detail', (tester) async {
    _deps();
    final auth = Get.find<AuthRepository>();
    final c = ContestPlayController(
      repo: ContestRepository(api: ApiService(baseUrl: 'http://127.0.0.1:1')),
      auth: auth,
      ledger: CoinLedger(),
      contestId: '1',
    );
    Get.put<ContestPlayController>(c);
    await _pumpScreen(tester, const ContestDetailView());
    c.detail.assignAll({
      'name': 'Sunday Showdown',
      'description':
          'Ten questions, one winner takes the crown. Play once — make it count!',
      'questionCount': 10,
      'entryFee': 50,
      'phase': 'live',
      'startDate': '2026-10-05T09:00:00Z',
      'prizes': [
        {'rank': 1, 'coins': 300},
        {'rank': 2, 'coins': 150},
        {'rank': 3, 'coins': 50},
      ],
      'myEntry': null,
    });
    c.leaderboard.assignAll([
      {'rank': 1, 'username': 'QuizWhiz', 'score': 100},
      {'rank': 2, 'username': 'Boss', 'score': 90},
      {'rank': 3, 'username': 'TriviaTitan', 'score': 80},
    ]);
    c.loading.value = false;
    c.error.value = '';
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'contest_detail');
  });

  testWidgets('preview: daily scratch reward', (tester) async {
    _deps();
    final auth = Get.find<AuthRepository>();
    final c = DailyRewardController(
      rewards:
          RewardsRepository(api: ApiService(baseUrl: 'http://127.0.0.1:1')),
      auth: auth,
      ledger: CoinLedger(),
    );
    Get.put<DailyRewardController>(c);
    await _pumpScreen(tester, const DailyRewardView());
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'daily_reward');
  });

  testWidgets('preview: refer and earn', (tester) async {
    _deps();
    final c = ReferEarnController(
      rewards:
          RewardsRepository(api: ApiService(baseUrl: 'http://127.0.0.1:1')),
    );
    Get.put<ReferEarnController>(c);
    await _pumpScreen(tester, const ReferEarnView());
    c.code.value = 'BOSS42';
    c.referredCount.value = 3;
    c.earnedCoins.value = 300;
    c.loading.value = false;
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'refer_earn');
  });

  testWidgets('preview: true false zone', (tester) async {
    _deps();
    final auth = Get.find<AuthRepository>();
    final badges = BadgeService();
    Get.put<BadgeService>(badges);
    final progressRepo = ProgressRepository(badges: badges);
    Get.put<ProgressRepository>(progressRepo);
    final c = TrueFalseController(
      auth: auth,
      progress: progressRepo,
      ledger: CoinLedger(),
    );
    Get.put<TrueFalseController>(c);
    await _pumpScreen(tester, const TrueFalseView());
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'true_false');
    Get.delete<TrueFalseController>(force: true);
  });

  testWidgets('preview: exam mode', (tester) async {
    _deps();
    final auth = Get.find<AuthRepository>();
    final badges = BadgeService();
    Get.put<BadgeService>(badges);
    final progressRepo = ProgressRepository(badges: badges);
    Get.put<ProgressRepository>(progressRepo);
    final c = ExamController(
      bank: LocalQuestionBank(),
      auth: auth,
      progress: progressRepo,
      ledger: CoinLedger(),
    );
    Get.put<ExamController>(c);
    await _pumpScreen(tester, const ExamView());
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'exam');
    Get.delete<ExamController>(force: true);
  });

  testWidgets('preview: statistics', (tester) async {
    _deps();
    final auth = Get.find<AuthRepository>();
    auth.currentUser.value = const AppUser(
      id: 'local-demo',
      username: 'Boss',
      email: 'boss@example.com',
      xp: 2450,
      level: 6,
      coins: 820,
      streak: 12,
    );
    final badges = BadgeService();
    Get.put<BadgeService>(badges);
    final progressRepo = ProgressRepository(badges: badges);
    progressRepo.progress.value = const PlayerProgress(
      totalQuizzes: 48,
      wins: 31,
      totalAnswered: 512,
      totalCorrect: 389,
      bestStreak: 14,
      perfectGames: 6,
      duelsWon: 18,
      dailyStreak: 12,
    );
    Get.put<ProgressRepository>(progressRepo);
    final c = StatisticsController(
      progress: progressRepo,
      auth: auth,
    );
    Get.put<StatisticsController>(c);
    await _pumpScreen(tester, const StatisticsView());
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'statistics');
  });

  testWidgets('preview: wallet', (tester) async {
    _deps();
    final auth = Get.find<AuthRepository>();
    auth.currentUser.value = const AppUser(
      id: 'local-demo',
      username: 'Boss',
      email: 'boss@example.com',
      xp: 2450,
      level: 6,
      coins: 820,
      streak: 12,
    );
    final ledger = CoinLedger();
    Get.put<CoinLedger>(ledger);
    await ledger.record(100, 'Daily scratch reward');
    await ledger.record(50, 'True/False zone');
    await ledger.record(-50, 'Contest entry: Sunday Showdown');
    await _pumpScreen(tester, const WalletView());
    await tester.pump(const Duration(milliseconds: 800));
    await _golden(tester, 'wallet');
  });

  testWidgets('preview: bookmarks', (tester) async {
    _deps();
    final repo = BookmarkRepository();
    Get.put<BookmarkRepository>(repo);
    await repo.toggle(const Question(
      id: 'q1',
      category: 'Science',
      difficulty: 'medium',
      question: 'What is the chemical symbol for gold?',
      options: ['Au', 'Ag', 'Gd', 'Go'],
      answerIndex: 0,
      explanation: 'Au comes from the Latin aurum.',
    ));
    await repo.toggle(const Question(
      id: 'q2',
      category: 'History',
      difficulty: 'hard',
      question: 'In which year did the Berlin Wall fall?',
      options: ['1987', '1989', '1991', '1985'],
      answerIndex: 1,
    ));
    await _pumpScreen(tester, const BookmarksView());
    await tester.pump(const Duration(milliseconds: 400));
    await _golden(tester, 'bookmarks');
  });
}
