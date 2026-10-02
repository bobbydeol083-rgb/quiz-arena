import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/utils/formatters.dart';
import 'package:quiz_arena/app/core/values/app_strings.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';

import '../controllers/nearby_controller.dart';

/// Players around the user, with per-category duel invites.
class NearbyView extends GetView<NearbyController> {
  const NearbyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Nearby Players')),
      body: ArenaBackground(
        child: SafeArea(
          child: Padding(
            padding: AppInsets.screen,
            child: Obx(() {
              switch (controller.status.value) {
                case 'loading':
                  return const ShimmerList(count: 5);
                case 'denied':
                  return _permissionCard(context);
                case 'error':
                  return EmptyState(
                    emoji: '📡',
                    title: 'Couldn\'t load nearby players',
                    subtitle: controller.error.value.isEmpty
                        ? 'Something went wrong.'
                        : controller.error.value,
                    actionLabel: 'Retry',
                    onAction: controller.refresh,
                  );
                case 'ready':
                  return _readyBody();
                default:
                  return const SizedBox.shrink();
              }
            }),
          ),
        ),
      ),
    );
  }

  /// Location permission / services-off card.
  Widget _permissionCard(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.nearbyPermissionTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.nearbyPermissionBody,
              style: TextStyle(color: AppColors.adaptiveSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: 'Enable location',
              icon: Icons.my_location_rounded,
              onPressed: controller.init,
            ),
            const SizedBox(height: AppSpacing.sm),
            GhostButton(
              label: 'Open settings',
              icon: Icons.settings_rounded,
              onPressed: controller.openSettings,
            ),
          ],
        ),
      ),
    );
  }

  /// Category chips + player list + range note.
  Widget _readyBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _categoryChips(),
        const SizedBox(height: AppSpacing.md),
        if (controller.error.value.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OfflineChip(),
            ),
          ),
        Expanded(
          child: controller.players.isEmpty
              ? const EmptyState(
                  emoji: '🛰️',
                  title: 'No players nearby right now',
                  subtitle:
                      'Try again in a bit — or start a solo quiz meanwhile.',
                )
              : ListView.builder(
                  itemCount: controller.players.length,
                  itemBuilder: (context, i) =>
                      _playerRow(controller.players[i], i),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Showing players within 5 km',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.adaptiveMuted, fontSize: 12),
        ),
      ],
    );
  }

  /// Single-select category chips (invite category).
  Widget _categoryChips() {
    final cats = QuizCategory.localDefaults();
    return SizedBox(
      height: 46,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final c = cats[i];
            final selected = controller.selectedCategory.value == c.id;
            return GestureDetector(
              onTap: () => controller.selectedCategory.value = c.id,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: selected ? AppGradients.primary : null,
                  color: selected ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      c.name,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.adaptiveSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _playerRow(NearbyPlayer p, int index) {
    return FadeSlideIn(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            if (p.online)
              const PulsingDot(color: AppColors.success)
            else
              const SizedBox(width: 22),
            const SizedBox(width: AppSpacing.sm),
            ArenaAvatar(imageUrl: p.avatar, name: p.username, radius: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Lv ${p.level} · ${Formatters.distance(p.distanceM)}',
                    style: TextStyle(
                      color: AppColors.adaptiveSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            GradientButton(
              label: 'Invite',
              height: 38,
              borderRadius: AppRadius.pill,
              textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              onPressed: () => controller.invite(p),
            ),
          ],
        ),
      ),
    );
  }
}
