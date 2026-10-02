import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/providers/socket_service.dart';

/// Incoming duel invite dialog, shown app-wide by [RealtimeController].
/// Keep this constructor EXACT — it is referenced from the realtime service.
class DuelInviteDialog extends StatelessWidget {
  final String inviteId;
  final String fromName;
  final String? fromAvatar;
  final String category;

  const DuelInviteDialog({
    super.key,
    required this.inviteId,
    required this.fromName,
    this.fromAvatar,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final socket = Get.find<SocketService>();
    final catColor = AppColors.categoryColor(category);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArenaAvatar(imageUrl: fromAvatar, name: fromName, radius: 36),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$fromName invites you to a duel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: catColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '${AppColors.categoryEmoji(category)} $category',
                style: TextStyle(
                  color: catColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Decline',
                    onPressed: () {
                      socket.declineDuel(inviteId);
                      Get.back();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GradientButton(
                    label: 'Accept',
                    onPressed: () {
                      socket.acceptDuel(inviteId);
                      Get.back();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
