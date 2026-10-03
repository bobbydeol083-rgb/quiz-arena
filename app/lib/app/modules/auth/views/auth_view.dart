import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_strings.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/modules/auth/controllers/auth_controller.dart';

/// Login / register screen: animated tab pill, staggered glass form,
/// error banner, gradient CTA, and an offline-demo escape hatch.
class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArenaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Logo header.
                FadeSlideIn(
                  index: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.violet
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('🧠',
                            style: TextStyle(fontSize: 30)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('QuizArena',
                          style: text.displaySmall),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Animated Login / Register tab pill.
                FadeSlideIn(index: 1, child: _tabPill()),
                const SizedBox(height: AppSpacing.xl),
                // Staggered form fields.
                Obx(_form),
                // Animated error banner.
                Obx(_errorBanner),
                // Primary CTA.
                FadeSlideIn(
                  index: 5,
                  child: Obx(
                    () => GradientButton(
                      label: controller.tab.value == 0
                          ? 'Enter the Arena'
                          : 'Create Account',
                      icon: Icons.bolt_rounded,
                      isLoading: controller.isLoading.value,
                      onPressed: () => controller.tab.value == 0
                          ? controller.login()
                          : controller.register(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  index: 6,
                  child: Center(
                    child: GhostButton(
                      label: 'Continue offline (demo)',
                      icon: Icons.cloud_off_outlined,
                      onPressed: controller.continueOffline,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // What the offline badge looks like / means.
                FadeSlideIn(
                  index: 7,
                  child: const Center(child: OfflineChip()),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  index: 8,
                  child: Text(
                    AppStrings.offlineHint,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.adaptiveMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Login/Register segmented pill; the active segment fills with the
  /// primary gradient via AnimatedContainer.
  Widget _tabPill() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.adaptiveSoftTint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.adaptiveBorder),
        ),
        child: Row(
          children: [
            _tabSegment(0, 'Login'),
            _tabSegment(1, 'Register'),
          ],
        ),
      ),
    );
  }

  Widget _tabSegment(int index, String label) {
    final active = controller.tab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.toggleTab(index),
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: AppCurves.entrance,
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: active ? AppGradients.primary : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : AppColors.adaptiveSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  /// Login: email + password. Register: username + email + password.
  Widget _form() {
    final isLogin = controller.tab.value == 0;
    final fields = <Widget>[];
    var i = 2;
    if (!isLogin) {
      fields.add(
        FadeSlideIn(
          index: i++,
          child: _field(
            controller: controller.username,
            hint: 'Username',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.text,
          ),
        ),
      );
    }
    fields.addAll([
      FadeSlideIn(
        index: i++,
        child: _field(
          controller: controller.email,
          hint: 'Email',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      FadeSlideIn(
        index: i,
        child: _field(
          controller: controller.password,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
        ),
      ),
    ]);
    if (!isLogin) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: FadeSlideIn(
            index: i + 1,
            child: _field(
              controller: controller.referralCode,
              hint: 'Referral code (optional)',
              icon: Icons.card_giftcard_rounded,
              keyboardType: TextInputType.text,
            ),
          ),
        ),
      );
    }
    return Column(
      children: fields
          .map(
            (w) => Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.md),
              child: w,
            ),
          )
          .toList(),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.adaptivePrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.adaptiveMuted),
      ),
    );
  }

  /// Red glass error banner; hidden when there is no error.
  Widget _errorBanner() {
    final msg = controller.error.value;
    if (msg.isEmpty) return const SizedBox.shrink();
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
