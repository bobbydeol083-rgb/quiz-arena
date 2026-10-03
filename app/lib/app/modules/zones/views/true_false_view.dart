import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';

import '../controllers/true_false_controller.dart';

/// True/False speed zone — Elite Quiz UI: rounded app bar, circular pink
/// timer, white statement card, TRUE/FALSE option containers.
class TrueFalseView extends GetView<TrueFalseController> {
  const TrueFalseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: EliteAppBar(
        title: 'True / False',
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: EliteTheme.primaryText),
          onPressed: Get.back,
        ),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${controller.score.value} pts',
                    style: eliteText(
                        size: 16,
                        weight: FontWeight.bold,
                        color: EliteTheme.primary),
                  ),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.finished.value) return _result(context);
        return _play(context);
      }),
    );
  }

  Widget _play(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => Center(
                child: Text(
                  'Q ${controller.index.value + 1}/${controller.statements.length}',
                  style: eliteText(
                      size: 14,
                      color: EliteTheme.primaryText
                          .withValues(alpha: 0.7)),
                ),
              )),
          const SizedBox(height: 8),

          /// Circular pink timer
          Obx(() => Center(
                child: _CircularTimer(
                  progress: controller.secondsLeft.value /
                      TrueFalseController.secondsPerStatement,
                  secondsLeft: controller.secondsLeft.value,
                ),
              )),
          const SizedBox(height: 16),

          /// Statement card
          Expanded(
            child: Obx(() {
              final answered = controller.answered.value;
              final correct = controller.lastCorrect.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: answered
                      ? Border.all(
                          color: correct
                              ? EliteTheme.correct
                              : EliteTheme.wrong,
                          width: 3,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    controller.current.statement,
                    style: eliteText(
                        size: 22,
                        weight: FontWeight.w600,
                        color: EliteTheme.primaryText),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          /// TRUE / FALSE option containers
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _AnswerOption(
                      label: 'FALSE',
                      color: EliteTheme.wrong,
                      enabled: !controller.answered.value,
                      onTap: controller.answerFalse,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnswerOption(
                      label: 'TRUE',
                      color: EliteTheme.correct,
                      enabled: !controller.answered.value,
                      onTap: controller.answerTrue,
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 110,
            height: 110,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: EliteTheme.primary,
            ),
            child: Obx(() => Text(
                  '${controller.score.value}',
                  style: eliteText(
                      size: 36,
                      weight: FontWeight.w800,
                      color: Colors.white),
                )),
          ),
          const SizedBox(height: 20),
          Text('Zone complete!',
              style: eliteText(size: 22, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() => Text(
                '${controller.score.value} points',
                style: eliteText(size: 18),
              )),
          const SizedBox(height: 32),
          EliteButton(
              title: 'Play again', onTap: controller.playAgain),
          const SizedBox(height: 12),
          EliteButton(
            title: 'Back',
            onTap: Get.back,
            backgroundColor: EliteTheme.pageBg,
            titleColor: EliteTheme.primary,
            elevation: 0,
          ),
        ],
      ),
    );
  }
}

/// Elite circular timer: white base ring + pink progress arc, round caps.
class _CircularTimer extends StatelessWidget {
  final double progress;
  final int secondsLeft;

  const _CircularTimer(
      {required this.progress, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(70, 70),
            painter: _TimerPainter(progress: progress),
          ),
          Text('$secondsLeft',
              style: eliteText(
                  size: 22,
                  weight: FontWeight.bold,
                  color: EliteTheme.primaryText)),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  _TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(4),
      0,
      3.14159 * 2,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      rect.deflate(4),
      -3.14159 / 2,
      3.14159 * 2 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = EliteTheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter old) =>
      old.progress != progress;
}

/// Elite TRUE/FALSE option container with press scale animation.
class _AnswerOption extends StatefulWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_AnswerOption> createState() => _AnswerOptionState();
}

class _AnswerOptionState extends State<_AnswerOption> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: Container(
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.color, width: 2),
            ),
            child: Text(
              widget.label,
              style: eliteText(
                size: 20,
                weight: FontWeight.w800,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
