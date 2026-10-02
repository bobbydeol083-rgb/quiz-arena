import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/utils/formatters.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';

/// The quiz play screen: quit + mode title + timer ring, score row,
/// live duel/party scoreboard, animated question card, option tiles,
/// explanation reveal, blitz finish button.
class QuizView extends GetView<QuizController> {
  const QuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quit quiz',
          icon: const Icon(Icons.close_rounded),
          onPressed: controller.quitQuiz,
        ),
        title: Text(controller.mode.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Obx(
              () => TimerRing(
                progress: controller.timeProgress,
                secondsLeft: controller.secondsLeft,
                size: 52,
              ),
            ),
          ),
        ],
      ),
      body: ArenaBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Obx(() {
                if (controller.isLoading.value) return _loadingBody();
                if (controller.error.value.isNotEmpty) return _errorBody();
                return _gameBody();
              }),
              Obx(() => controller.waitingForOpponent.value
                  ? _waitingOverlay()
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  /// Realtime: the local player finished all questions; the server ends the
  /// game for everyone once the opponent is done (or the timer lapses).
  Widget _waitingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Waiting for ${controller.opponentName.value.isEmpty ? 'your opponent' : controller.opponentName.value}…',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Results land the moment the battle ends.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- States ---------------------------------------------------------------

  Widget _loadingBody() {
    return const Padding(
      padding: AppInsets.screen,
      child: ShimmerList(count: 4, itemHeight: 96),
    );
  }

  Widget _errorBody() {
    return EmptyState(
      emoji: '😵',
      title: 'No questions found',
      subtitle: controller.error.value,
      actionLabel: 'Retry',
      onAction: controller.retry,
    );
  }

  // ---- Game -----------------------------------------------------------------

  Widget _gameBody() {
    return Column(
      children: [
        _scoreRow(),
        if (controller.isRealtime) ...[
          const SizedBox(height: AppSpacing.sm),
          _scoreboard(),
        ],
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _questionCard(),
                const SizedBox(height: AppSpacing.lg),
                _options(),
                _explanation(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        _bottomBar(),
      ],
    );
  }

  Widget _scoreRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCORE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adaptiveMuted,
                ),
              ),
              Obx(
                () => Text(
                  '${controller.score.value}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adaptivePrimary,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Obx(() => StreakFlame(streak: controller.streak.value)),
          const Spacer(),
          _modeExtras(),
          Obx(
            () => controller.isOffline.value
                ? const OfflineChip()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Blitz total timer / marathon hearts.
  Widget _modeExtras() {
    if (controller.mode == QuizMode.blitz) {
      return Obx(
        () => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Text(
            '⏱ ${Formatters.mmss(controller.blitzSecondsLeft)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.warning,
            ),
          ),
        ),
      );
    }
    if (controller.mode == QuizMode.marathon) {
      return Obx(
        () => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(
                    i < controller.lives.value ? '♥' : '♡',
                    style: TextStyle(
                      fontSize: 22,
                      color: i < controller.lives.value
                          ? AppColors.error
                          : AppColors.adaptiveMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// Live scoreboard for duel / party rooms.
  Widget _scoreboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Obx(
        () => GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              const PulsingDot(color: AppColors.success, size: 8),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'You',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.adaptivePrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${controller.score.value}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cyan,
                ),
              ),
              Text(
                '  :  ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.adaptiveMuted,
                ),
              ),
              Text(
                '${controller.opponentScore.value}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.magenta,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  controller.opponentName.value.isEmpty
                      ? 'Opponent'
                      : controller.opponentName.value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.adaptiveSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionCard() {
    return Obx(() {
      final q = controller.currentQuestion;
      final idx = controller.currentIndex.value;
      final total = controller.totalQuestions;
      final categoryId = controller.categoryId;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: GlassCard(
          key: ValueKey(idx),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Q${idx + 1}/$total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppColors.adaptiveMuted,
                    ),
                  ),
                  if (q.category.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.violet.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        q.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.violet,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (categoryId != null)
                    Hero(
                      tag: 'category-hero-$categoryId',
                      child: Text(
                        AppColors.categoryEmoji(categoryId),
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                q.question,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.adaptivePrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _options() {
    return Obx(() {
      final q = controller.currentQuestion;
      final revealed = controller.revealed.value;
      final selected = controller.selectedIndex.value;
      final known = controller.isAnswerKnown;
      final answerIdx = q.answerIndex;
      return Column(
        children: [
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OptionTile(
                index: i,
                text: q.options[i],
                state: !revealed
                    ? _TileState.idle
                    : known
                        ? (i == answerIdx
                            ? _TileState.correct
                            : (i == selected
                                ? _TileState.wrong
                                : _TileState.dim))
                        : (i == selected ? _TileState.locked : _TileState.dim),
                onTap: revealed ? null : () => controller.selectOption(i),
              ),
            ),
        ],
      );
    });
  }

  Widget _explanation() {
    return Obx(() {
      if (!controller.revealed.value) return const SizedBox.shrink();
      final exp = controller.currentQuestion.explanation;
      if (exp == null || exp.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: FadeSlideIn(
          child: GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    exp,
                    style: TextStyle(
                      color: AppColors.adaptiveSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _bottomBar() {
    if (controller.mode != QuizMode.blitz) {
      return const SizedBox(height: AppSpacing.md);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Align(
        alignment: Alignment.center,
        child: TextButton(
          onPressed: controller.finishEarly,
          child: Text(
            'Finish',
            style: TextStyle(
              color: AppColors.adaptiveSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

enum _TileState { idle, correct, wrong, locked, dim }

/// One answer option: glass by default; green/red reveal when the answer is
/// known; violet "Locked in ✓" sweep when the backend hides the answer.
class _OptionTile extends StatefulWidget {
  final int index;
  final String text;
  final _TileState state;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    late final Color bg;
    late final Color border;
    switch (widget.state) {
      case _TileState.correct:
        bg = AppColors.success.withValues(alpha: 0.18);
        border = AppColors.success;
      case _TileState.wrong:
        bg = AppColors.error.withValues(alpha: 0.18);
        border = AppColors.error;
      case _TileState.locked:
        bg = AppColors.violet.withValues(alpha: 0.22);
        border = AppColors.violet;
      case _TileState.dim:
        bg = isDark ? AppColors.surface : Colors.white;
        border = AppColors.glassBorder;
      case _TileState.idle:
        bg = isDark ? AppColors.surfaceElevated : Colors.white;
        border = AppColors.glassBorder;
    }

    final enabled = widget.onTap != null;
    Widget tile = GestureDetector(
      onTapDown: enabled ? (_) => _press.forward() : null,
      onTapUp: enabled ? (_) => _press.reverse() : null,
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: border.withValues(alpha: 0.18),
                ),
                child: Text(
                  'ABCD'[widget.index],
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: border,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.adaptivePrimary,
                  ),
                ),
              ),
              if (widget.state == _TileState.locked)
                const Text(
                  'Locked in ✓',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.violet,
                  ),
                ).animate().slideX(
                      begin: -0.4,
                      end: 0,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
              if (widget.state == _TileState.correct)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success),
              if (widget.state == _TileState.wrong)
                const Icon(Icons.cancel_rounded, color: AppColors.error),
            ],
          ),
        ),
      ),
    );

    if (widget.state == _TileState.dim) {
      tile = Opacity(opacity: 0.45, child: tile);
    }
    switch (widget.state) {
      case _TileState.correct:
        return tile.animate().scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            );
      case _TileState.wrong:
        return tile.animate().shake(hz: 4, duration: 400.ms);
      default:
        return tile;
    }
  }
}
