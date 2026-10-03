import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';

import '../controllers/contest_play_controller.dart';

/// Contest detail — Elite Quiz UI: rounded app bar, white cards, pink
/// option containers, EliteButton CTAs.
class ContestDetailView extends GetView<ContestPlayController> {
  const ContestDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: EliteAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: EliteTheme.primaryText),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasResult) return _result(context);
        if (controller.hasJoined) return _play(context);
        return _detail(context);
      }),
    );
  }

  // ---- Detail ---------------------------------------------------------------

  Widget _detail(BuildContext context) {
    final d = controller.detail;
    final prizes = (d['prizes'] as List?) ?? [];
    final phase = '${d['phase'] ?? ''}';
    final myEntry = d['myEntry'] as Map?;
    final submitted = (myEntry?['submitted'] as bool?) ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          Text('${d['name'] ?? ''}',
                              style: eliteText(
                                  size: 18,
                                  weight: FontWeight.bold)),
                          Text(
                            '${d['questionCount'] ?? 0} questions',
                            style: eliteText(
                                size: 13,
                                color: EliteTheme.primaryText.withValues(
                                    alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ('${d['description'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('${d['description']}',
                      style: eliteText(size: 15)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (prizes.isNotEmpty) ...[
            Text('Prize pool',
                style:
                    eliteText(size: 18, weight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (final p in prizes)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          _rankBadge(
                              (p['rank'] as num?)?.toInt() ?? 0),
                          const SizedBox(width: 10),
                          Text('Rank ${p['rank']}',
                              style: eliteText(
                                  size: 16,
                                  weight: FontWeight.bold)),
                          const Spacer(),
                          SvgPicture.asset(EliteAssets.coin,
                              width: 20, height: 20),
                          const SizedBox(width: 4),
                          Text('${p['coins']}',
                              style: eliteText(
                                  size: 16,
                                  weight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Leaderboard',
              style: eliteText(size: 18, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          _leaderboardCard(),
          const SizedBox(height: 20),
          if (controller.error.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(controller.error.value,
                  style: eliteText(
                      size: 13, color: EliteTheme.wrong),
                  textAlign: TextAlign.center),
            ),
          if (phase == 'live' && !submitted)
            Obx(() => EliteButton(
                  title: controller.joining.value
                      ? 'Joining…'
                      : (d['entryFee'] as num?)?.toInt() != 0
                          ? 'Join contest · ${d['entryFee']} coins'
                          : 'Join contest · free',
                  onTap: controller.joining.value
                      ? () {}
                      : controller.join,
                ))
          else if (submitted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('You already played this contest.',
                    style: eliteText(size: 15)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  phase == 'upcoming'
                      ? 'Starts ${d['startDate'] ?? ''}'
                      : 'This contest has ended.',
                  style: eliteText(size: 15),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank) {
    final asset = rank == 1
        ? EliteAssets.rank1
        : rank == 2
            ? EliteAssets.rank2
            : rank == 3
                ? EliteAssets.rank3
                : EliteAssets.rank4;
    return SvgPicture.asset(asset, width: 32, height: 32);
  }

  Widget _leaderboardCard() {
    return Obx(() {
      final lb = controller.leaderboard;
      if (lb.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text('No scores yet — be the first!',
                style: eliteText(size: 15)),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            for (final e in lb.take(10))
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${e['rank']}',
                          style: eliteText(
                              size: 16,
                              weight: FontWeight.w800)),
                    ),
                    Expanded(
                      child: Text('${e['username'] ?? '?'}',
                          style: eliteText(size: 15)),
                    ),
                    Text('${e['score']} pts',
                        style: eliteText(
                            size: 16, weight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  // ---- Play -------------------------------------------------------------------

  Widget _play(BuildContext context) {
    final q = controller.questions[controller.index.value];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: controller.answers.length /
                      controller.questions.length,
                  backgroundColor: Colors.white,
                  color: EliteTheme.primary,
                  minHeight: 8,
                ),
              )),
          const SizedBox(height: 8),
          Obx(() => Text(
                'Question ${controller.index.value + 1}/${controller.questions.length}',
                style: eliteText(
                    size: 14,
                    color: EliteTheme.primaryText
                        .withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(q.question,
                        style: eliteText(
                            size: 18,
                            weight: FontWeight.w600,
                            color: EliteTheme.primaryText)),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(q.options.length, (oi) {
                    final selected =
                        controller.answers[controller.index.value] ==
                            oi;
                    return _ContestOption(
                      text: q.options[oi],
                      selected: selected,
                      onTap: () => controller.select(oi),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: EliteButton(
                  title: 'Back',
                  onTap: controller.prev,
                  backgroundColor: Colors.white,
                  titleColor: EliteTheme.primary,
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => EliteButton(
                      title: controller.index.value + 1 >=
                              controller.questions.length
                          ? 'Submit'
                          : 'Next',
                      onTap: controller.submitting.value
                          ? () {}
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---- Result -------------------------------------------------------------------

  Widget _result(BuildContext context) {
    final r = controller.result;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _rankBadge((r['rank'] as num?)?.toInt() ?? 99),
          const SizedBox(height: 20),
          Text('Contest complete!',
              style: eliteText(size: 22, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() => Text(
                'Rank #${controller.result['rank']} · ${controller.result['score']} pts',
                style:
                    eliteText(size: 24, weight: FontWeight.w800),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: 8),
          Text(
            '${r['correctAnswers']}/${r['total']} correct',
            style: eliteText(size: 15),
          ),
          const SizedBox(height: 32),
          EliteButton(
            title: 'Back to contests',
            onTap: Get.back,
            backgroundColor: Colors.white,
            titleColor: EliteTheme.primary,
            elevation: 0,
          ),
        ],
      ),
    );
  }
}

/// Elite option container with press scale animation.
class _ContestOption extends StatefulWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ContestOption({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ContestOption> createState() => _ContestOptionState();
}

class _ContestOptionState extends State<_ContestOption> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.selected
                ? EliteTheme.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: eliteText(
              size: 20,
              color: widget.selected
                  ? Colors.white
                  : EliteTheme.primaryText,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
