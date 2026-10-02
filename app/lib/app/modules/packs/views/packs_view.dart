import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

import '../controllers/packs_controller.dart';

/// Game Packs — community-published custom games.
/// Tabs: Browse (install), Installed (play offline), My Packs (publish).
class PacksView extends GetView<PacksController> {
  const PacksView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: ArenaBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text('Game Packs',
                        style: text.headlineSmall),
                    const Spacer(),
                    Obx(
                      () => controller.packs.offline.value
                          ? const OfflineChip()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              _tabs(text),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Obx(() {
                  switch (controller.tab.value) {
                    case 1:
                      return _installedTab(text);
                    case 2:
                      return _mineTab(text);
                    default:
                      return _browseTab(text);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(
        () => controller.tab.value == 2
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final created =
                      await Get.toNamed(Routes.packEditor);
                  if (created == true) controller.refreshAll();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('New pack'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _tabs(TextTheme text) {
    const labels = ['Browse', 'Installed', 'My Packs'];
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = controller.tab.value == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.tab.value = i,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient:
                        selected ? AppGradients.primary : null,
                    color: selected
                        ? null
                        : AppColors.glass,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: text.labelLarge?.copyWith(
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondaryOf(
                              Get.context!),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _browseTab(TextTheme text) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: controller.searchCtrl,
            onChanged: (v) => controller.search.value = v,
            decoration: InputDecoration(
              hintText: 'Search packs…',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _modeFilter(text),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value &&
                controller.browsePacks.isEmpty) {
              return const Padding(
                padding: AppInsets.screen,
                child: ShimmerList(count: 5),
              );
            }
            if (controller.browsePacks.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.refreshBrowse,
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 380,
                    child: EmptyState(
                      emoji: '📦',
                      title: 'No packs yet',
                      subtitle:
                          'Be the first to publish a custom game.',
                    ),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: controller.refreshBrowse,
              child: ListView.builder(
                padding: AppInsets.screen,
                itemCount: controller.browsePacks.length,
                itemBuilder: (_, i) =>
                    _packCard(text, controller.browsePacks[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _modeFilter(TextTheme text) {
    const modes = ['', 'quiz', 'bluff'];
    const labels = ['All', 'Quiz', 'Bluff'];
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(modes.length, (i) {
            final selected = controller.modeFilter.value == modes[i];
            return Padding(
              padding:
                  const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(labels[i]),
                selected: selected,
                onSelected: (_) {
                  controller.modeFilter.value = modes[i];
                  controller.refreshBrowse();
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _packCard(TextTheme text, GamePack pack) {
    final installed = controller.isInstalled(pack.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(pack.title,
                            style: text.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${pack.label} • ${pack.mode == 'bluff' ? '🎭 Bluff' : '🧠 Quiz'} • ${pack.questionCount} Qs',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondaryOf(
                                Get.context!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pack.authorName != null &&
                      pack.authorName!.isNotEmpty)
                    Text('by ${pack.authorName}',
                        style: text.bodySmall),
                ],
              ),
              if (pack.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(pack.description,
                    style: text.bodyMedium, maxLines: 2),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _stat(text, '⬇️', '${pack.installs}'),
                  const SizedBox(width: AppSpacing.md),
                  _stat(text, '🎮', '${pack.plays}'),
                  const Spacer(),
                  installed
                      ? GhostButton(
                          label: 'Installed ✓',
                          onPressed: () {},
                        )
                      : GradientButton(
                          label: 'Install',
                          onPressed: () =>
                              controller.install(pack),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(TextTheme text, String emoji, String value) {
    return Text('$emoji $value', style: text.bodySmall);
  }

  Widget _installedTab(TextTheme text) {
    return Obx(() {
      if (controller.installed.isEmpty) {
        return const EmptyState(
          emoji: '💾',
          title: 'Nothing installed',
          subtitle: 'Install a pack to play it anytime — even offline.',
        );
      }
      return ListView.builder(
        padding: AppInsets.screen,
        itemCount: controller.installed.length,
        itemBuilder: (_, i) {
          final pack = controller.installed[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GlassCard(
              child: Padding(
                padding: AppInsets.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.title, style: text.titleMedium),
                    Text(
                      '${pack.label} • ${pack.questionCount} questions',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondaryOf(
                            Get.context!),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        GradientButton(
                          label: 'Play',
                          onPressed: () =>
                              controller.playPack(pack),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        GhostButton(
                          label: 'Remove',
                          onPressed: () =>
                              controller.uninstall(pack.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _mineTab(TextTheme text) {
    return Obx(() {
      if (controller.mine.isEmpty) {
        return const EmptyState(
          emoji: '✍️',
          title: 'No packs yet',
          subtitle: 'Tap "New pack" to author your first custom game.',
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refreshMine,
        child: ListView.builder(
          padding: AppInsets.screen,
          itemCount: controller.mine.length,
          itemBuilder: (_, i) {
            final pack = controller.mine[i];
            final published = pack.status == 'published';
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                child: Padding(
                  padding: AppInsets.card,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(pack.title,
                                style: text.titleMedium),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: published
                                  ? Colors.green
                                      .withValues(alpha: 0.2)
                                  : Colors.orange.withValues(
                                      alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.sm),
                            ),
                            child: Text(
                              published
                                  ? 'Published'
                                  : 'Draft',
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          if (!published)
                            GradientButton(
                              label: 'Publish',
                              onPressed: () =>
                                  controller.publish(pack.id),
                            )
                          else
                            GhostButton(
                              label: 'Unpublish',
                              onPressed: () => controller
                                  .unpublish(pack.id),
                            ),
                          GhostButton(
                            label: 'Delete',
                            onPressed: () =>
                                controller.deletePack(pack.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
