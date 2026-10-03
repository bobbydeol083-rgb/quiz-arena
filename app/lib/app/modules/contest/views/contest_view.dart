import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/repositories/contest_repository.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

import '../controllers/contest_controller.dart';

/// Contest lobby: live, upcoming and ended prize contests.
class ContestView extends GetView<ContestController> {
  const ContestView({super.key});

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
                    EliteAssets.svg(EliteAssets.versus, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Contests', style: text.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error.value.isNotEmpty &&
                      controller.contests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: AppInsets.screen,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(controller.error.value,
                                style: text.bodyMedium,
                                textAlign: TextAlign.center),
                            const SizedBox(height: AppSpacing.md),
                            GradientButton(
                                label: 'Retry',
                                onPressed: controller.load),
                          ],
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: _list(context, text),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, TextTheme text) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.live.isNotEmpty) ...[
            _sectionTitle(text, '🔴 Live now'),
            ...controller.live.map((c) => _card(context, text, c)),
          ],
          if (controller.upcoming.isNotEmpty) ...[
            _sectionTitle(text, '⏳ Upcoming'),
            ...controller.upcoming.map((c) => _card(context, text, c)),
          ],
          if (controller.ended.isNotEmpty) ...[
            _sectionTitle(text, '🏁 Ended'),
            ...controller.ended.map((c) => _card(context, text, c)),
          ],
          if (controller.contests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text('No contests yet — check back soon!',
                    style: text.bodyMedium),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(TextTheme text, String title) => Padding(
        padding: const EdgeInsets.only(
            top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(title, style: text.titleMedium),
      );

  Widget _card(BuildContext context, TextTheme text, ContestCard c) {
    final phaseColor = c.phase == 'live'
        ? AppColors.error
        : c.phase == 'upcoming'
            ? AppColors.sun
            : AppColors.textSecondaryOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: () => Get.toNamed('${Routes.contest}/${c.id}'),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: EliteAssets.svg(EliteAssets.versus,
                  size: 30, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.name,
                            style: text.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (c.played)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successOf(context)
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text('played',
                              style: text.labelLarge?.copyWith(
                                  color:
                                      AppColors.successOf(context),
                                  fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.questionCount} questions · ${c.participants} players · ${c.prizePool} coins prize pool',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: phaseColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.phase.toUpperCase(),
                        style: text.labelLarge?.copyWith(
                            color: phaseColor, fontSize: 11),
                      ),
                      if (c.entryFee > 0) ...[
                        const SizedBox(width: 8),
                        EliteAssets.svg(EliteAssets.coin, size: 14),
                        const SizedBox(width: 2),
                        Text('${c.entryFee} entry',
                            style: text.bodySmall?.copyWith(
                              color:
                                  AppColors.textSecondaryOf(context),
                            )),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
