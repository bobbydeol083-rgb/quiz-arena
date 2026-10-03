import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:scratcher/scratcher.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';

import '../controllers/daily_reward_controller.dart';

/// Daily scratch-card reward — Elite Quiz UI: centered scratch card on a
/// pink container, "scratch here" hint overlay, confetti on reveal.
class DailyRewardView extends GetView<DailyRewardController> {
  const DailyRewardView({super.key});

  @override
  Widget build(BuildContext context) {
    final confetti = ConfettiController(duration: const Duration(seconds: 2));

    return Scaffold(
      backgroundColor: EliteTheme.pageBg.withValues(alpha: 0.45),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          color: EliteTheme.primary,
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Obx(() {
        if (controller.checking.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.canClaim.value && !controller.revealed.value) {
          return _claimedState(context);
        }
        return _scratchState(context, confetti);
      }),
    );
  }

  Widget _claimedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(EliteAssets.dailyCoins, width: 96, height: 96),
            const SizedBox(height: 20),
            Text('Already claimed!',
                style: eliteText(size: 22, weight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your scratch card was claimed today.\nCome back tomorrow for another shot.',
              style: eliteText(size: 15),
              textAlign: TextAlign.center,
            ),
            if (controller.error.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                controller.error.value,
                style: eliteText(size: 13, color: EliteTheme.wrong),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scratchState(BuildContext context, ConfettiController confetti) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Hero(
            tag: 'daily-scratch',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration:
                    const BoxDecoration(color: EliteTheme.primary),
                height: h * 0.4,
                width: w * 0.8,
                child: Obx(() {
                  if (controller.revealed.value) {
                    confetti.play();
                    return _revealedFace(context);
                  }
                  return Scratcher(
                    brushSize: 35,
                    threshold: 50,
                    color: EliteTheme.primary,
                    image: Image.asset(EliteAssets.scratchCover,
                        fit: BoxFit.cover),
                    onThreshold: controller.claim,
                    onChange: (_) {},
                    child: _prizeFace(context),
                  );
                }),
              ),
            ),
          ),
        ),

        /// "Scratch here" hint overlay
        Obx(() => (!controller.revealed.value && !controller.claiming.value)
            ? Align(
                alignment: Alignment.center,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: EliteTheme.primary
                          .withValues(alpha: 0.3),
                    ),
                    height: h * 0.075,
                    width: w * 0.8,
                    child: Center(
                      child: Text(
                        'SCRATCH HERE',
                        style: eliteText(
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink()),

        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
          ),
        ),
        if (controller.claiming.value)
          const Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  /// The hidden prize face under the scratch cover.
  Widget _prizeFace(BuildContext context) {
    return Container(
      color: EliteTheme.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(EliteAssets.coin, width: 64, height: 64),
            const SizedBox(height: 8),
            Text('?',
                style: eliteText(
                    size: 40,
                    weight: FontWeight.w800,
                    color: Colors.white)),
            Text('coins inside!',
                style: eliteText(
                    size: 16,
                    weight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _revealedFace(BuildContext context) {
    return Container(
      color: EliteTheme.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 120,
              child:
                  Lottie.asset(EliteAssets.successLottie, repeat: false),
            ),
            Text(
              '+${controller.awarded.value} coins!',
              style: eliteText(
                  size: 28,
                  weight: FontWeight.w800,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
