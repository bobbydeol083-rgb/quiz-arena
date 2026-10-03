import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/contest_play_controller.dart';

/// Contest detail: prizes, join, play, results, leaderboard.
class ContestDetailView extends GetView<ContestPlayController> {
  const ContestDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArenaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: AppInsets.screen,
                child: Row(
                  children: [
                    ArenaIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: Get.back,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Obx(() => Text(
                            '${controller.detail['name'] ?? 'Contest'}',
                            style: text.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.hasResult) return _result(context, text);
                  if (controller.hasJoined) return _play(context, text);
                  return _detail(context, text);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Detail ---------------------------------------------------------------

  Widget _detail(BuildContext context, TextTheme text) {
    final d = controller.detail;
    final prizes = (d['prizes'] as List?) ?? [];
    final phase = '${d['phase'] ?? ''}';
    final myEntry = d['myEntry'] as Map?;
    final submitted = (myEntry?['submitted'] as bool?) ?? false;
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EliteAssets.svg(EliteAssets.versus, size: 44),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${d['name'] ?? ''}', style: text.titleLarge),
                          Text(
                            '${d['questionCount'] ?? 0} questions',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ('${d['description'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('${d['description']}',
                      style: text.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (prizes.isNotEmpty) ...[
            Text('Prize pool', style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Column(
                children: [
                  for (final p in prizes)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          _rankBadge(
                              context, (p['rank'] as num?)?.toInt() ?? 0),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Rank ${p['rank']}',
                              style: text.titleMedium),
                          const Spacer(),
                          EliteAssets.svg(EliteAssets.coin, size: 20),
                          const SizedBox(width: 4),
                          Text('${p['coins']}',
                              style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Leaderboard', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _leaderboardCard(context, text),
          const SizedBox(height: AppSpacing.lg),
          if (controller.error.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(controller.error.value,
                  style: text.bodySmall?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center),
            ),
          if (phase == 'live' && !submitted)
            Obx(() => GradientButton(
                  label: controller.joining.value
                      ? 'Joining…'
                      : (d['entryFee'] as num?)?.toInt() != 0
                          ? 'Join contest · ${d['entryFee']} coins'
                          : 'Join contest · free',
                  onPressed:
                      controller.joining.value ? null : controller.join,
                ))
          else if (submitted)
            GlassCard(
              child: Center(
                child: Text('You already played this contest.',
                    style: text.bodyMedium),
              ),
            )
          else
            GlassCard(
              child: Center(
                child: Text(
                  phase == 'upcoming'
                      ? 'Starts ${d['startDate'] ?? ''}'
                      : 'This contest has ended.',
                  style: text.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _rankBadge(BuildContext context, int rank) {
    final asset = rank == 1
        ? EliteAssets.rank1
        : rank == 2
            ? EliteAssets.rank2
            : rank == 3
                ? EliteAssets.rank3
                : EliteAssets.rank4;
    return EliteAssets.svg(asset, size: 32);
  }

  Widget _leaderboardCard(BuildContext context, TextTheme text) {
    return Obx(() {
      final lb = controller.leaderboard;
      if (lb.isEmpty) {
        return GlassCard(
          child: Center(
            child: Padding(
              padding: AppInsets.card,
              child: Text('No scores yet — be the first!',
                  style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryOf(context))),
            ),
          ),
        );
      }
      return GlassCard(
        child: Column(
          children: [
            for (final e in lb.take(10))
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${e['rank']}',
                          style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800)),
                    ),
                    Expanded(
                      child: Text('${e['username'] ?? '?'}',
                          style: text.bodyMedium),
                    ),
                    Text('${e['score']} pts',
                        style: text.titleMedium),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  // ---- Play -------------------------------------------------------------------

  Widget _play(BuildContext context, TextTheme text) {
    final q = controller.questions[controller.index.value];
    return Padding(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => LinearProgressIndicator(
                value: controller.answers.length /
                    controller.questions.length,
                backgroundColor: AppColors.borderOf(context),
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                minHeight: 8,
              )),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => Text(
                'Question ${controller.index.value + 1}/${controller.questions.length}',
                style: text.labelLarge?.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(child: Text(q.question, style: text.titleLarge)),
                  const SizedBox(height: AppSpacing.md),
                  ...List.generate(q.options.length, (oi) {
                    final selected =
                        controller.answers[controller.index.value] == oi;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => controller.select(oi),
                        child: Container(
                          padding: AppInsets.card,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.blue.withValues(alpha: 0.14)
                                : AppColors.softTintOf(context),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: selected
                                  ? AppColors.blue
                                  : AppColors.borderOf(context),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child:
                              Text(q.options[oi], style: text.titleMedium),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child:
                    GhostButton(label: 'Back', onPressed: controller.prev),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Obx(() => GradientButton(
                      label: controller.index.value + 1 >=
                              controller.questions.length
                          ? 'Submit'
                          : 'Next',
                      onPressed: controller.submitting.value
                          ? null
                          : () {
                              if (controller.index.value + 1 >=
                                  controller.questions.length) {
                                controller.submit();
                              } else {
                                controller.next();
                              }
                            },
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ---- Result -------------------------------------------------------------------

  Widget _result(BuildContext context, TextTheme text) {
    final r = controller.result;
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          _rankBadge(context, (r['rank'] as num?)?.toInt() ?? 99),
          const SizedBox(height: AppSpacing.lg),
          Text('Contest complete!', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => Text(
                'Rank #${controller.result['rank']} · ${controller.result['score']} pts',
                style: text.displaySmall,
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${r['correctAnswers']}/${r['total']} correct',
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GhostButton(label: 'Back to contests', onPressed: Get.back),
        ],
      ),
    );
  }
}
