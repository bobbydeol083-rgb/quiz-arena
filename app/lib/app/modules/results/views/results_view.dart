import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/utils/badge_service.dart';
import 'package:quiz_arena/app/core/utils/formatters.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/modules/results/controllers/results_controller.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Post-game results: confetti, score, duel banner, stat grid, XP bar,
/// level-up banner, badges earned, and replay/home actions.
class ResultsView extends GetView<ResultsController> {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final r = controller.result;
    if (r == null) return const SizedBox.shrink();

    final userXp = controller.auth.currentUser.value?.xp ?? r.xpEarned;
    // Duels are won/lost on score, not accuracy — prefer the duel verdict.
    final won = r.duelWon ?? r.isWin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ArenaBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: AppInsets.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const Text(
                      '🏆',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 84),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      won ? 'Victory!' : 'Good battle!',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.displaySmall,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: CountUpText(
                        value: r.score,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: AppColors.adaptivePrimary,
                        ),
                      ),
                    ),
                    if (r.duelWon != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        child: Row(
                          children: [
                            Text(
                              r.duelWon! ? '⚔️' : '💔',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                r.duelWon!
                                    ? 'You won the duel vs ${r.opponentName ?? 'your rival'}!'
                                    : '${r.opponentName ?? 'Your rival'} takes this one',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.adaptivePrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.5,
                      children: [
                        _statCard('Correct', '${r.correct}/${r.total}'),
                        _statCard(
                            'Accuracy', Formatters.percent(r.accuracy)),
                        _statCard('Best streak', 'x${r.bestStreak}'),
                        _statCard('Coins', '+${r.coinsEarned}'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XpProgressBar(xp: userXp, fromXp: controller.fromXp),
                    if (r.levelUp) ...[
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎉',
                                style: TextStyle(fontSize: 26)),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'LEVEL UP → LV ${r.newLevel}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Badges earned',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    r.newBadges.isEmpty
                        ? Text(
                            'No badges this time — keep playing!',
                            style: TextStyle(
                              color: AppColors.adaptiveMuted,
                              fontSize: 14,
                            ),
                          )
                        : SizedBox(
                            height: 132,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: r.newBadges.length,
                              separatorBuilder: (_, __) => const SizedBox(
                                  width: AppSpacing.md),
                              itemBuilder: (context, i) {
                                final def =
                                    BadgeRules.byId(r.newBadges[i]);
                                if (def == null) {
                                  return const SizedBox.shrink();
                                }
                                return FadeSlideIn(
                                  index: i,
                                  child: GlassCard(
                                    width: 150,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          def.emoji,
                                          style: const TextStyle(
                                              fontSize: 36),
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.xs),
                                        Text(
                                          def.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _badgeColor(
                                                def.colorHex),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: AppSpacing.xxl),
                    GradientButton(
                      label: 'Play Again',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Get.offNamed(Routes.modes),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GhostButton(
                      label: 'Home',
                      icon: Icons.home_rounded,
                      onPressed: () => Get.offNamed(Routes.home),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller.confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              gravity: 0.2,
              colors: const [
                AppColors.violet,
                AppColors.cyan,
                AppColors.gold,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.adaptivePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.adaptiveMuted,
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(String hex) {
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (v == null) return AppColors.violet;
    return Color(0xFF000000 | v);
  }
}
