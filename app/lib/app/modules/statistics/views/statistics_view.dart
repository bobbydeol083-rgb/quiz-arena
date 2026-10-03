import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';

import '../controllers/statistics_controller.dart';

/// Statistics dashboard — Elite Quiz UI: rounded app bar, white cards with
/// soft shadow, pie charts with legends, icon tiles.
class StatisticsView extends GetView<StatisticsController> {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = controller.progress.progress.value;
    final coins = controller.auth.currentUser.value?.coins ?? 0;
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: const EliteAppBar(title: 'Statistics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Question Details'),
            const SizedBox(height: 8),
            EliteCard(
              child: Row(
                children: [
                  ElitePieChart(
                    fractions: [
                      controller.accuracy,
                      1 - controller.accuracy,
                    ],
                    colors: const [
                      Color(0xFF62A9CD),
                      Color(0xFF8C4593),
                    ],
                    size: 82,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${p.totalAnswered}',
                            style: eliteText(
                                size: 18, weight: FontWeight.bold)),
                        Text('Total',
                            style: eliteText(
                                size: 12,
                                color: EliteTheme.primaryText.withValues(
                                    alpha: 0.7))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        EliteLegendRow(
                          dot: const Color(0xFF62A9CD),
                          label: 'Correct',
                          value: '${p.totalCorrect}',
                        ),
                        EliteLegendRow(
                          dot: const Color(0xFF8C4593),
                          label: 'Incorrect',
                          value: '${p.totalAnswered - p.totalCorrect}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Battle Statistics'),
            const SizedBox(height: 8),
            EliteCard(
              child: Row(
                children: [
                  ElitePieChart(
                    fractions: [
                      controller.winRate,
                      1 - controller.winRate,
                    ],
                    colors: const [
                      Color(0xFF90C88A),
                      Color(0xFFF79478),
                    ],
                    size: 82,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${p.duelsWon}',
                            style: eliteText(
                                size: 18, weight: FontWeight.bold)),
                        Text('Won',
                            style: eliteText(
                                size: 12,
                                color: EliteTheme.primaryText.withValues(
                                    alpha: 0.7))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        EliteLegendRow(
                          dot: const Color(0xFF90C88A),
                          label: 'Won',
                          value: '${p.duelsWon}',
                        ),
                        EliteLegendRow(
                          dot: const Color(0xFFF79478),
                          label: 'Lost',
                          value: '${p.totalQuizzes - p.wins}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Overview'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _tile(EliteAssets.score, '${p.totalQuizzes}',
                    'quizzes played'),
                _tile(EliteAssets.correct, '${p.totalCorrect}',
                    'correct answers'),
                _tile(EliteAssets.badges, 'x${p.bestStreak}',
                    'best streak'),
                _tile(EliteAssets.dailyQuiz, '${p.dailyStreak}d',
                    'daily streak'),
                _tile(EliteAssets.versus, '${p.duelsWon}', 'duels won'),
                _tile(EliteAssets.coin, '$coins', 'coin balance'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: eliteText(size: 18, weight: FontWeight.bold));
  }

  Widget _tile(String icon, String value, String label) {
    return EliteCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(icon, width: 30, height: 30),
          const SizedBox(height: 6),
          Text(value,
              style:
                  eliteText(size: 22, weight: FontWeight.bold)),
          Text(label,
              style: eliteText(
                  size: 13,
                  color:
                      EliteTheme.primaryText.withValues(alpha: 0.7)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
