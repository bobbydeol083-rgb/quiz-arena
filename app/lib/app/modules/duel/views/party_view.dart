import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/modules/duel/controllers/party_controller.dart';

/// Party room: setup (create / join by code) or the live room lobby.
class PartyView extends GetView<PartyController> {
  const PartyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Party Room')),
      body: ArenaBackground(
        child: SafeArea(
          child: Obx(
            () => controller.room.value == null
                ? _setup(context)
                : _room(context),
          ),
        ),
      ),
    );
  }

  // ---- Setup: create or join ------------------------------------------------

  Widget _setup(BuildContext context) {
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create a room',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          _categoryChips(),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Row(
              children: [
                ChoiceChip(
                  label: const Text('🧠 Classic quiz'),
                  selected: !controller.bluffMode.value,
                  onSelected: (_) =>
                      controller.bluffMode.value = false,
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: const Text('🎭 Bluff & Brain'),
                  selected: controller.bluffMode.value,
                  onSelected: (_) =>
                      controller.bluffMode.value = true,
                ),
              ],
            ),
          ),
          Obx(
            () => controller.bluffMode.value
                ? Padding(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.xs),
                    child: Text(
                      'Write fake answers, fool your friends, spot the truth.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Obx(
            () => GradientButton(
              label: 'Create Room',
              icon: Icons.add_rounded,
              isLoading: controller.creating.value,
              onPressed: controller.createRoom,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'or join',
                  style: TextStyle(color: AppColors.adaptiveMuted),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: controller.joinCodeCtrl,
            onChanged: (v) => controller.joinCode.value = v,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Enter room code',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => GradientButton(
              label: 'Join Room',
              icon: Icons.login_rounded,
              onPressed: controller.joinCode.value.trim().isEmpty
                  ? null
                  : controller.joinRoom,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return Obx(
      () => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final c in QuizCategory.localDefaults())
            ChoiceChip(
              label: Text('${c.icon} ${c.name}'),
              selected: controller.selectedCategory.value == c.id,
              onSelected: (_) => controller.selectedCategory.value = c.id,
              selectedColor: AppColors.blue.withValues(alpha: 0.18),
              backgroundColor: AppColors.adaptiveElevated,
              labelStyle: TextStyle(
                color: AppColors.adaptivePrimary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: controller.selectedCategory.value == c.id
                    ? AppColors.blue
                    : AppColors.adaptiveBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Room lobby -----------------------------------------------------------

  Widget _room(BuildContext context) {
    final room = controller.room.value!;
    return SingleChildScrollView(
      padding: AppInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Room code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    room.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: AppColors.adaptivePrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  icon: const Icon(Icons.copy_rounded),
                  color: AppColors.cyan,
                  onPressed: controller.copyCode,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Players',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Column(
              children: [
                for (final p in controller.players)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          ArenaAvatar(
                            imageUrl: p.avatar,
                            name: p.username,
                            radius: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              p.username,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.adaptivePrimary,
                              ),
                            ),
                          ),
                          if (p.isHost)
                            const Text(
                              '👑',
                              style: TextStyle(fontSize: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Obx(
            () => controller.isHost.value
                ? GradientButton(
                    label: 'Start Game',
                    icon: Icons.play_arrow_rounded,
                    onPressed: controller.startGame,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),
          GhostButton(
            label: 'Leave',
            icon: Icons.exit_to_app_rounded,
            onPressed: controller.leave,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
