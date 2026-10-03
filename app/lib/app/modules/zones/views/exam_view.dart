import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';

import '../controllers/exam_controller.dart';

/// Timed exam — Elite Quiz UI: flat app bar with countdown, PageView of
/// questions, option containers (white, pink when selected), chevron bottom
/// nav, dark center tab opening the question-status sheet.
class ExamView extends GetView<ExamController> {
  const ExamView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: EliteAppBar(
        title: '',
        rounded: false,
        backgroundColor: EliteTheme.pageBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: EliteTheme.primaryText),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    controller.timeLabel,
                    style: eliteText(
                      size: 18,
                      weight: FontWeight.bold,
                      color: controller.secondsLeft.value < 120
                          ? EliteTheme.hurry
                          : EliteTheme.primaryText,
                    ),
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
    return Stack(
      children: [
        PageView.builder(
          controller: controller.pageController,
          itemCount: controller.questions.length,
          onPageChanged: (i) => controller.index.value = i,
          itemBuilder: (_, i) {
            final q = controller.questions[i];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Question container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Question ${i + 1}',
                            style: eliteText(
                                size: 13,
                                color: EliteTheme.primaryText.withValues(
                                    alpha: 0.7))),
                        const SizedBox(height: 6),
                        Text(q.question,
                            style: eliteText(
                                size: 18,
                                weight: FontWeight.w600,
                                color: EliteTheme.primaryText)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  /// Option containers
                  ...List.generate(q.options.length, (oi) {
                    final selected =
                        controller.answers[i] == oi;
                    return _OptionContainer(
                      text: q.options[oi],
                      selected: selected,
                      onTap: () => controller.select(oi),
                    );
                  }),
                ],
              ),
            );
          },
        ),

        /// Bottom menu
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 16),
                Obx(() => _navSquare(
                      icon: Icons.chevron_left_rounded,
                      dimmed: controller.index.value == 0,
                      onTap: controller.prev,
                    )),
                GestureDetector(
                  onTap: () => _statusSheet(context),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(42, 8, 48, 8),
                    decoration: BoxDecoration(
                      color: EliteTheme.primaryText,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                Obx(() => _navSquare(
                      icon: Icons.chevron_right_rounded,
                      dimmed: controller.index.value + 1 >=
                          controller.questions.length,
                      onTap: () {
                        if (controller.index.value + 1 >=
                            controller.questions.length) {
                          _confirmFinish(context);
                        } else {
                          controller.next();
                        }
                      },
                    )),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _navSquare({
    required IconData icon,
    required bool dimmed,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EliteTheme.primaryText.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon,
              size: 28, color: EliteTheme.primaryText),
        ),
      ),
    );
  }

  /// Question-status bottom sheet: answered/unanswered grid + submit.
  void _statusSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Questions',
                style:
                    eliteText(size: 18, weight: FontWeight.bold)),
            const SizedBox(height: 12),
            Obx(() => GridView.builder(
                  shrinkWrap: true,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: controller.questions.length,
                  itemBuilder: (_, i) {
                    final done =
                        controller.answers.containsKey(i);
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.jumpTo(i);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: done
                              ? EliteTheme.correct
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: EliteTheme.pageBg, width: 2),
                        ),
                        child: Text('${i + 1}',
                            style: eliteText(
                                size: 14,
                                weight: FontWeight.bold,
                                color: done
                                    ? Colors.white
                                    : EliteTheme.primaryText)),
                      ),
                    );
                  },
                )),
            const SizedBox(height: 16),
            EliteButton(
              title: 'Submit exam',
              onTap: () {
                Navigator.of(context).pop();
                _confirmFinish(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Leave exam?',
            style: eliteText(size: 18, weight: FontWeight.bold)),
        content: Text(
            'Your progress will be submitted as-is.',
            style: eliteText(size: 15)),
        actions: [
          TextButton(
              onPressed: Get.back, child: const Text('Keep playing')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.finish();
            },
            child: const Text('Leave anyways'),
          ),
        ],
      ),
    );
  }

  void _confirmFinish(BuildContext context) {
    final unanswered =
        controller.questions.length - controller.answers.length;
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Finish exam?',
            style: eliteText(size: 18, weight: FontWeight.bold)),
        content: Text(
            unanswered > 0
                ? 'You still have $unanswered unanswered question(s). Submit anyway?'
                : 'Submit your exam for grading?',
            style: eliteText(size: 15)),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Review')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.finish();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    final pct = (controller.accuracy * 100).toStringAsFixed(1);
    final pass = controller.accuracy >= 0.6;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pass ? EliteTheme.correct : EliteTheme.primary,
            ),
            child: Text(
              controller.grade,
              style: eliteText(
                  size: 44,
                  weight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            pass ? 'Exam passed!' : 'Keep practicing!',
            style: eliteText(size: 22, weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.correctCount}/${controller.questions.length} correct · $pct%',
            style: eliteText(size: 15),
          ),
          const SizedBox(height: 32),
          EliteButton(
              title: 'Retake exam', onTap: controller.retake),
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

/// Elite option container: white, radius 10, pink bg + white text when
/// selected (no correctness revealed during the exam).
class _OptionContainer extends StatefulWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionContainer({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_OptionContainer> createState() => _OptionContainerState();
}

class _OptionContainerState extends State<_OptionContainer> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          margin: EdgeInsets.only(top: maxH * 0.015),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
