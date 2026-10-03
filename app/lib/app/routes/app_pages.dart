import 'package:get/get.dart';

import 'app_routes.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/categories/bindings/categories_binding.dart';
import '../modules/categories/views/categories_view.dart';
import '../modules/discover/bindings/discover_binding.dart';
import '../modules/discover/views/discover_view.dart';
import '../modules/duel/bindings/duel_binding.dart';
import '../modules/duel/bindings/party_binding.dart';
import '../modules/duel/views/duel_view.dart';
import '../modules/duel/views/party_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/leaderboard/bindings/leaderboard_binding.dart';
import '../modules/leaderboard/views/leaderboard_view.dart';
import '../modules/modes/bindings/modes_binding.dart';
import '../modules/modes/views/modes_view.dart';
import '../modules/nearby/bindings/nearby_binding.dart';
import '../modules/nearby/views/nearby_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/quiz/bindings/quiz_binding.dart';
import '../modules/quiz/views/quiz_view.dart';
import '../modules/results/bindings/results_binding.dart';
import '../modules/results/views/results_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/packs/bindings/packs_binding.dart';
import '../modules/packs/views/packs_view.dart';
import '../modules/packs/views/pack_editor_view.dart';
import '../modules/bluff/bindings/bluff_binding.dart';
import '../modules/bluff/views/bluff_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/rewards/bindings/rewards_binding.dart';
import '../modules/rewards/views/daily_reward_view.dart';
import '../modules/rewards/views/refer_earn_view.dart';
import '../modules/zones/bindings/zones_binding.dart';
import '../modules/zones/views/true_false_view.dart';
import '../modules/zones/views/exam_view.dart';
import '../modules/statistics/bindings/statistics_binding.dart';
import '../modules/statistics/views/statistics_view.dart';
import '../modules/wallet/views/wallet_view.dart';
import '../modules/bookmarks/views/bookmarks_view.dart';

/// Named route table. Every page uses the signature Arena transition
/// (fade + scale + slight slide); the four bottom-nav tabs use the faster
/// tab variant so tab switches feel instant.
class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      customTransition: ArenaTabTransition(),
      transitionDuration: const Duration(milliseconds: 180),
    ),
    GetPage(
      name: Routes.discover,
      page: () => const DiscoverView(),
      binding: DiscoverBinding(),
      customTransition: ArenaTabTransition(),
      transitionDuration: const Duration(milliseconds: 180),
    ),
    GetPage(
      name: Routes.leaderboard,
      page: () => const LeaderboardView(),
      binding: LeaderboardBinding(),
      customTransition: ArenaTabTransition(),
      transitionDuration: const Duration(milliseconds: 180),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      customTransition: ArenaTabTransition(),
      transitionDuration: const Duration(milliseconds: 180),
    ),
    GetPage(
      name: Routes.categories,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.modes,
      page: () => const ModesView(),
      binding: ModesBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.quiz,
      page: () => const QuizView(),
      binding: QuizBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.results,
      page: () => const ResultsView(),
      binding: ResultsBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.duel,
      page: () => const DuelView(),
      binding: DuelBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.party,
      page: () => const PartyView(),
      binding: PartyBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.nearby,
      page: () => const NearbyView(),
      binding: NearbyBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.packs,
      page: () => const PacksView(),
      binding: PacksBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.packEditor,
      page: () => const PackEditorView(),
      binding: PackEditorBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.bluff,
      page: () => const BluffView(),
      binding: BluffBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.dailyReward,
      page: () => const DailyRewardView(),
      binding: DailyRewardBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.referEarn,
      page: () => const ReferEarnView(),
      binding: ReferEarnBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.trueFalse,
      page: () => const TrueFalseView(),
      binding: TrueFalseBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.exam,
      page: () => const ExamView(),
      binding: ExamBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.statistics,
      page: () => const StatisticsView(),
      binding: StatisticsBinding(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.wallet,
      page: () => const WalletView(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.bookmarks,
      page: () => const BookmarksView(),
      customTransition: ArenaPageTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  ];
}
