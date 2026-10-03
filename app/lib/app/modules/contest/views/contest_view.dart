import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/data/repositories/contest_repository.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

import '../controllers/contest_controller.dart';

/// Contest lobby — Elite Quiz UI: rounded app bar, white cards, pink
/// phase accents.
class ContestView extends GetView<ContestController> {
  const ContestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: const EliteAppBar(title: 'Contests'),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty &&
            controller.contests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.error.value,
                      style: eliteText(size: 15),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  EliteButton(
                      title: 'Retry', onTap: controller.load),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: _list(context),
        );
      }),
    );
  }

  Widget _list(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.live.isNotEmpty) ...[
            _sectionTitle('Live now'),
            ...controller.live.map(_card),
          ],
          if (controller.upcoming.isNotEmpty) ...[
            _sectionTitle('Upcoming'),
            ...controller.upcoming.map(_card),
          ],
          if (controller.ended.isNotEmpty) ...[
            _sectionTitle('Ended'),
            ...controller.ended.map(_card),
          ],
          if (controller.contests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No contests yet — check back soon!',
                    style: eliteText(size: 15)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(title,
            style: eliteText(size: 18, weight: FontWeight.bold)),
      );

  Widget _card(ContestCard c) {
    final phaseColor = c.phase == 'live'
        ? EliteTheme.hurry
        : c.phase == 'upcoming'
            ? const Color(0xFFF5A623)
            : EliteTheme.primaryText.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Get.toNamed('${Routes.contest}/${c.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EliteTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(EliteAssets.versus,
                    width: 30, height: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.name,
                              style: eliteText(
                                  size: 16,
                                  weight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (c.played)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: EliteTheme.correct
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('played',
                                style: eliteText(
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: EliteTheme.correct)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.questionCount} questions · ${c.participants} players · ${c.prizePool} coins prize pool',
                      style: eliteText(
                          size: 12,
                          color: EliteTheme.primaryText.withValues(
                              alpha: 0.7)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: phaseColor),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.phase.toUpperCase(),
                          style: eliteText(
                              size: 11,
                              weight: FontWeight.bold,
                              color: phaseColor),
                        ),
                        if (c.entryFee > 0) ...[
                          const SizedBox(width: 8),
                          SvgPicture.asset(EliteAssets.coin,
                              width: 14, height: 14),
                          const SizedBox(width: 2),
                          Text('${c.entryFee} entry',
                              style: eliteText(
                                  size: 12,
                                  color: EliteTheme.primaryText
                                      .withValues(alpha: 0.7))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: EliteTheme.primaryText),
            ],
          ),
        ),
      ),
    );
  }
}
