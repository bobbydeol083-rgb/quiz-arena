import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Named route constants. One source of truth — every `Get.toNamed` /
/// `Get.offNamed` in the app references these.
class Routes {
  Routes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String categories = '/categories';
  static const String modes = '/modes';
  static const String quiz = '/quiz';
  static const String results = '/results';
  static const String duel = '/duel';
  static const String party = '/party';
  static const String nearby = '/nearby';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// Bottom-nav tabs (order matters for the sliding indicator).
  static const List<String> tabs = [home, discover, leaderboard, profile];
}

/// Signature page transition: fade + slight scale + gentle slide.
/// Applied to every GetPage via `customTransition`.
class ArenaPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0.03),
          end: Offset.zero,
        ).animate(eased),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(eased),
          child: child,
        ),
      ),
    );
  }
}

/// Faster, subtler transition for bottom-tab switches.
class ArenaTabTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
