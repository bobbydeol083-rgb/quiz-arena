import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/bluff_controller.dart';

/// Bluff & Brain table: write-a-fake -> vote -> reveal -> final standings.
class BluffView extends GetView<BluffController> {
  const BluffView({super.key});

  /// Short display id that never throws, however short the id is.
  static String _shortId(String id, [int len = 4]) =>
      id.length <= len ? id : '${id.substring(0, len)}…';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: ArenaBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(text),
              Expanded(
                child: Obx(() {
                  switch (controller.phase.value) {
                    case BluffPhase.write:
                      return _writePhase(text);
                    case BluffPhase.vote:
                      return _votePhase(text);
                    case BluffPhase.reveal:
                      return _revealPhase(text);
                    case BluffPhase.done:
                      return _donePhase(text);
                    case BluffPhase.lobby:
                      return _lobby(text);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(TextTheme text) {
    return Padding(
      padding: AppInsets.screen,
      child: Row(
        children: [
          ArenaIconButton(
            icon: Icons.close_rounded,
            onPressed: controller.leave,
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎭 Bluff & Brain', style: text.titleLarge),
              Obx(
                () => Text(
                  controller.totalRounds.value > 0
                      ? 'Round ${controller.round.value} of ${controller.totalRounds.value}'
                      : 'Getting the table ready…',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondaryOf(Get.context!),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Obx(() => _scoreChip(text)),
        ],
      ),
    );
  }

  Widget _scoreChip(TextTheme text) {
    final my = controller.scores
        .firstWhereOrNull((s) => s.userId == controller.myId);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        '${my?.score ?? 0} pts',
        style: text.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _lobby(TextTheme text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PulsingDot(color: AppColors.violet, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text('Shuffling the lies…', style: text.titleMedium),
        ],
      ),
    );
  }

  // ---- write phase ----------------------------------------------------------

  Widget _writePhase(TextTheme text) {
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _phaseBanner(text, '✍️', 'Write a believable FAKE answer',
              'Fool your friends. The real answer stays hidden.'),
          const SizedBox(height: AppSpacing.md),
          Obx(() => TimerRing(
                progress: controller.writeProgress(),
                secondsLeft: controller.writeSecondsLeft(),
              )),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Padding(
              padding: AppInsets.card,
              child: Text(
                controller.question.value,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => controller.myFake.value != null
                ? GlassCard(
                    child: Padding(
                      padding: AppInsets.card,
                      child: Column(
                        children: [
                          Text('Your bluff is in:',
                              style: text.bodySmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            controller.myFake.value!,
                            style: text.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${controller.fakesIn.value}/${controller.fakesTotal.value} bluffs in…',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.textSecondaryOf(
                                  Get.context!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      TextField(
                        controller: controller.fakeCtrl,
                        maxLength: 120,
                        decoration: InputDecoration(
                          hintText:
                              'Invent a fake answer… make it believable',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GradientButton(
                        label: 'Submit bluff',
                        onPressed: controller.submitFake,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _powerupBar(text, const ['double_agent', 'speed_run', 'swap']),
        ],
      ),
    );
  }

  // ---- vote phase -----------------------------------------------------------

  Widget _votePhase(TextTheme text) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _phaseBanner(text, '🗳️', 'Which one is TRUE?',
              'One of these is real. The rest are your friends\' lies.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => TimerRing(
              progress: controller.voteProgress(),
              secondsLeft: controller.voteSecondsLeft(),
            )),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Obx(
            () => ListView.builder(
              padding: AppInsets.screen,
              itemCount: controller.options.length,
              itemBuilder: (_, i) {
                final opt = controller.options[i];
                final eliminated =
                    controller.eliminated.contains(opt.id);
                final mine = controller.myVote.value == opt.id;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Opacity(
                    opacity: eliminated ? 0.35 : 1,
                    child: GestureDetector(
                      onTap: eliminated
                          ? null
                          : () => controller.vote(opt.id),
                      child: GlassCard(
                        child: Padding(
                          padding: AppInsets.card,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  eliminated
                                      ? '❌ ${opt.text}'
                                      : opt.text,
                                  style: text.titleMedium,
                                ),
                              ),
                              if (mine)
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.green),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: AppInsets.screen,
          child: _powerupBar(text, const ['detective']),
        ),
      ],
    );
  }

  // ---- reveal phase ---------------------------------------------------------

  Widget _revealPhase(TextTheme text) {
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _phaseBanner(text, '🎬', 'The truth comes out', ''),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Column(
              children: controller.options.map((opt) {
                final isTruth = opt.id ==
                    controller.correctOptionId.value;
                final isMine = opt.authorId == controller.myId;
                final delta = controller.deltas
                    .firstWhereOrNull(
                        (d) => d.userId == opt.authorId);
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GlassCard(
                    child: Padding(
                      padding: AppInsets.card,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(opt.text,
                                    style: text.titleMedium),
                                Text(
                                  isTruth
                                      ? '✅ THE TRUTH'
                                      : isMine
                                          ? '🎭 Your bluff${delta != null && delta.fooled > 0 ? ' — fooled ${delta.fooled}' : ''}'
                                          : '🎭 A bluff',
                                  style: text.bodySmall?.copyWith(
                                    color: isTruth
                                        ? Colors.greenAccent
                                        : AppColors.textSecondaryOf(
                                            Get.context!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isTruth)
                            const Icon(Icons.verified_rounded,
                                color: Colors.greenAccent),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Obx(
            () => controller.roast.value.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    child: GlassCard(
                      child: Padding(
                        padding: AppInsets.card,
                        child: Row(
                          children: [
                            const Text('🎤',
                                style: TextStyle(fontSize: 28)),
                            const SizedBox(
                                width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                controller.roast.value,
                                style: text.bodyMedium?.copyWith(
                                    fontStyle:
                                        FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Column(
              children: controller.deltas.map((d) {
                final isMe = d.userId == controller.myId;
                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMe
                            ? 'You'
                            : 'Player ${_shortId(d.userId)}',
                        style: text.bodyMedium?.copyWith(
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      CountUpText(
                        value: d.delta,
                        prefix: d.delta >= 0 ? '+' : '',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---- done phase -----------------------------------------------------------

  Widget _donePhase(TextTheme text) {
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _phaseBanner(text, '🏁', 'Final standings', ''),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Column(
              children:
                  controller.scores.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final isMe = s.userId == controller.myId;
                final title =
                    controller.titles[s.userId] ?? '';
                const medals = ['🥇', '🥈', '🥉'];
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GlassCard(
                    child: Padding(
                      padding: AppInsets.card,
                      child: Row(
                        children: [
                          Text(
                            i < 3 ? medals[i] : '${i + 1}.',
                            style: text.titleLarge,
                          ),
                          const SizedBox(
                              width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMe
                                      ? 'You'
                                      : 'Player ${_shortId(s.userId)}',
                                  style: text.titleMedium,
                                ),
                                if (title.isNotEmpty)
                                  Text('🏷️ $title',
                                      style: text.bodySmall
                                          ?.copyWith(
                                        color: AppColors
                                            .textSecondaryOf(
                                                Get.context!),
                                      )),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              CountUpText(value: s.score),
                              Text(
                                '${s.truths} truths • ${s.fooled} fooled',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton(
            label: 'Back to arena',
            onPressed: controller.leave,
          ),
        ],
      ),
    );
  }

  // ---- shared bits ----------------------------------------------------------

  Widget _phaseBanner(
      TextTheme text, String emoji, String title, String subtitle) {
    return Column(
      children: [
        Text('$emoji $title',
            style: text.titleLarge,
            textAlign: TextAlign.center),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle,
              style: text.bodySmall?.copyWith(
                color:
                    AppColors.textSecondaryOf(Get.context!),
              ),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _powerupBar(TextTheme text, List<String> types) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: types.map((t) {
          final meta = BluffPowerups.all[t]!;
          final count = controller.powerupCount(t);
          final usable = count > 0;
          return GestureDetector(
            onTap: usable
                ? () => _onPowerupTap(t)
                : null,
            child: Opacity(
              opacity: usable ? 1 : 0.3,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient:
                          usable ? AppGradients.primary : null,
                      color: usable
                          ? null
                          : AppColors.glass,
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(meta['emoji']!,
                        style:
                            const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 2),
                  Text(meta['name']!,
                      style: text.bodySmall),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onPowerupTap(String type) {
    if (type == 'swap') {
      _pickSwapTarget();
      return;
    }
    if (type == 'detective' &&
        controller.phase.value != BluffPhase.vote) {
      Get.snackbar('Not yet', 'Detective works during voting.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (type != 'detective' &&
        controller.phase.value != BluffPhase.write) {
      Get.snackbar('Not now', 'Use it during the write phase.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    controller.usePowerup(type);
    Get.snackbar(
      '${BluffPowerups.all[type]!['emoji']} ${BluffPowerups.all[type]!['name']}',
      BluffPowerups.all[type]!['desc']!,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _pickSwapTarget() {
    final others = controller.scores
        .where((s) => s.userId != controller.myId)
        .toList();
    if (others.isEmpty) return;
    Get.bottomSheet(
      Container(
        padding: AppInsets.screen,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Steal whose bluff?',
                style: Theme.of(Get.context!).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ...others.map(
              (s) => ListTile(
                title: Text(
                    'Player ${_shortId(s.userId, 6)} (${s.score} pts)'),
                trailing:
                    const Icon(Icons.arrow_forward_rounded),
                onTap: () {
                  Get.back();
                  controller.usePowerup('swap',
                      targetUserId: s.userId);
                  Get.snackbar('🔄 Swapped',
                      'Their bluff is now yours.',
                      snackPosition: SnackPosition.BOTTOM);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
