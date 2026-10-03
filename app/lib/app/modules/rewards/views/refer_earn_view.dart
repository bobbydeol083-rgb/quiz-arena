import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/refer_earn_controller.dart';

/// Refer & earn: share your code, both sides win coins.
class ReferEarnView extends GetView<ReferEarnController> {
  const ReferEarnView({super.key});

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
                    Text('Refer & earn', style: text.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error.value.isNotEmpty &&
                      controller.code.value.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: AppInsets.screen,
                        child: Text(
                          controller.error.value,
                          style: text.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return _body(context, text);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TextTheme text) {
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              children: [
                EliteAssets.svg(EliteAssets.referEarn, size: 88),
                const SizedBox(height: AppSpacing.md),
                Text('Invite friends, earn coins', style: text.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Share your code. Your friend gets ${controller.refereeReward.value} coins on signup, you get ${controller.referrerReward.value} for each friend who joins.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              children: [
                Text('YOUR REFERRAL CODE', style: text.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Obx(() => Text(
                      controller.code.value.isEmpty
                          ? '—'
                          : controller.code.value,
                      style: text.displaySmall?.copyWith(
                        letterSpacing: 6,
                        fontWeight: FontWeight.w800,
                      ),
                    )),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Share invite',
                        onPressed: () =>
                            Share.share(controller.shareText),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ArenaIconButton(
                      icon: Icons.copy_rounded,
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: controller.code.value));
                        Get.snackbar('Copied', 'Referral code copied!',
                            snackPosition: SnackPosition.BOTTOM);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      text,
                      '${controller.referredCount.value}',
                      'friends joined',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _statCard(
                      context,
                      text,
                      '${controller.earnedCoins.value}',
                      'coins earned',
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _statCard(
      BuildContext context, TextTheme text, String value, String label) {
    return GlassCard(
      child: Column(
        children: [
          Text(value, style: text.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
