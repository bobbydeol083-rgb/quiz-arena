import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';

import '../controllers/refer_earn_controller.dart';

/// Refer & earn — Elite Quiz UI: pink header band with curved bottom,
/// illustration, coin reward, dotted code box, share CTA.
class ReferEarnView extends GetView<ReferEarnController> {
  const ReferEarnView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: EliteTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty &&
            controller.code.value.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.error.value,
                style: eliteText(size: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return _body(context);
      }),
    );
  }

  Widget _body(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Container(
          width: w,
          decoration: const BoxDecoration(
            color: EliteTheme.primary,
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Refer & Earn',
                textAlign: TextAlign.center,
                style: eliteText(
                    size: 22,
                    weight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: h * 0.01),
              SizedBox(
                height: h * 0.16,
                child: SvgPicture.asset(EliteAssets.referEarn),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(EliteAssets.coin,
                      width: 28, height: 28),
                  const SizedBox(width: 10),
                  Obx(() => Text(
                        '${controller.referrerReward.value}',
                        style: eliteText(
                            size: 32,
                            weight: FontWeight.bold,
                            color: Colors.white),
                      )),
                ],
              ),
              Text(
                'Get free coins',
                style: eliteText(
                    size: 16,
                    weight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: h * 0.008),
              SizedBox(
                width: w * 0.8,
                child: Obx(() => Text(
                      'Refer your friends and you will get ${controller.referrerReward.value} coins.\nThey will get ${controller.refereeReward.value} coins.',
                      textAlign: TextAlign.center,
                      style:
                          eliteText(size: 14, color: Colors.white),
                    )),
              ),
              SizedBox(height: h * 0.02),

              /// Dotted referral-code box
              DottedBorder(
                color: Colors.white.withValues(alpha: 0.5),
                strokeWidth: 3,
                dashPattern: const [6, 4],
                radius: const Radius.circular(8),
                borderType: BorderType.RRect,
                padding: EdgeInsets.zero,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: EliteTheme.primaryText
                        .withValues(alpha: 0.8),
                  ),
                  height: 60,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 25),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'YOUR REFERRAL CODE',
                            style: eliteText(
                                size: 10,
                                weight: FontWeight.w600,
                                color: Colors.white
                                    .withValues(alpha: 0.8)),
                          ),
                          Obx(() => Text(
                                controller.code.value.isEmpty
                                    ? '—'
                                    : controller.code.value,
                                style: eliteText(
                                    size: 18,
                                    weight: FontWeight.w600,
                                    color: Colors.white),
                              )),
                        ],
                      ),
                      const SizedBox(width: 5),
                      VerticalDivider(
                        color: Colors.white.withValues(alpha: 0.4),
                        indent: 10,
                        endIndent: 10,
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(
                              text: controller.code.value));
                          Get.snackbar('Copied',
                              'Referral code copied to clipboard',
                              snackPosition: SnackPosition.BOTTOM);
                        },
                        child: Text(
                          'COPY CODE',
                          style: eliteText(
                              size: 10,
                              weight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 25),
                    ],
                  ),
                ),
              ),
              SizedBox(height: h * 0.015),
              Obx(() => Text(
                    '${controller.referredCount.value} friends joined · ${controller.earnedCoins.value} coins earned',
                    style: eliteText(
                        size: 13,
                        color:
                            Colors.white.withValues(alpha: 0.85)),
                  )),
            ],
          ),
        ),
        const Spacer(),

        /// Share CTA at bottom
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: EliteButton(
            title: 'Share Now',
            widthFactor: 0.9,
            height: 60,
            onTap: () => Share.share(controller.shareText),
          ),
        ),
      ],
    );
  }
}
