import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/settings_controller.dart';

/// App settings: appearance, backend, preferences, data, account, about.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: ArenaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section('Appearance', _appearanceSection()),
                _section('Backend', _backendSection()),
                _section('Preferences', _preferencesSection()),
                _section('Data', _dataSection()),
                _section('Account', _accountSection()),
                _section(
                  'About',
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        'QuizArena v${controller.version}',
                        style: TextStyle(
                          color: AppColors.adaptiveSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(child: child),
          const SizedBox(height: AppSpacing.lg),
        ],
      );

  Widget _appearanceSection() {
    return Obx(() {
      final dark = controller.theme.mode.value == ThemeMode.dark;
      return SwitchListTile(
        title: const Text('Dark mode'),
        subtitle: const Text('Midnight arena theme'),
        value: dark,
        onChanged: (_) => controller.toggleTheme(),
      );
    });
  }

  Widget _backendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller.apiCtrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'API base URL',
            hintText: 'http://10.0.2.2:5000/api',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Default: 10.0.2.2:5000 for Android emulator',
          style: TextStyle(color: AppColors.adaptiveMuted, fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'Save',
                onPressed: controller.saveApiBase,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Obx(
                () => GhostButton(
                  label: controller.saving.value
                      ? 'Testing…'
                      : 'Test connection',
                  onPressed: controller.saving.value
                      ? null
                      : controller.testConnection,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _preferencesSection() {
    return Column(
      children: [
        Obx(
          () => SwitchListTile(
            title: const Text('Sound effects'),
            value: controller.sound.value,
            onChanged: controller.setSound,
          ),
        ),
        Obx(
          () => SwitchListTile(
            title: const Text('Haptics'),
            value: controller.haptics.value,
            onChanged: controller.setHaptics,
          ),
        ),
      ],
    );
  }

  Widget _dataSection() {
    return OutlinedButton.icon(
      onPressed: controller.resetProgress,
      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      label: const Text(
        'Reset progress',
        style: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.error),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }

  Widget _accountSection() {
    return Obx(() {
      final user = controller.user;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ArenaAvatar(
              imageUrl: user?.avatar,
              name: user?.username ?? '?',
              radius: 22,
            ),
            title: Text(
              user?.username ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(user?.email ?? '—'),
          ),
          if (controller.auth.isOfflineDemo)
            const Align(
              alignment: Alignment.centerLeft,
              child: OfflineChip(),
            ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            label: 'Log out',
            icon: Icons.logout_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.error, AppColors.errorDim],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: controller.logout,
          ),
        ],
      );
    });
  }
}
