import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/repositories/bookmark_repository.dart';

/// Saved questions for later review.
class BookmarksView extends StatelessWidget {
  const BookmarksView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final repo = Get.find<BookmarkRepository>();
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
                    EliteAssets.svg(EliteAssets.bookmark, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Bookmarks', style: text.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: _BookmarksList(repo: repo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarksList extends StatefulWidget {
  final BookmarkRepository repo;
  const _BookmarksList({required this.repo});

  @override
  State<_BookmarksList> createState() => _BookmarksListState();
}

class _BookmarksListState extends State<_BookmarksList> {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = widget.repo.all();
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: AppInsets.screen,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EliteAssets.svg(EliteAssets.bookmark, size: 88),
              const SizedBox(height: AppSpacing.lg),
              Text('No bookmarks yet', style: text.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap the bookmark icon during a quiz\nto save tricky questions here.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: AppInsets.screen,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final q = items[i];
        final answer = q.answerIndex != null &&
                q.answerIndex! >= 0 &&
                q.answerIndex! < q.options.length
            ? q.options[q.answerIndex!]
            : null;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(q.question, style: text.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_rounded),
                    color: AppColors.sun,
                    onPressed: () async {
                      await widget.repo.toggle(q);
                      setState(() {});
                    },
                  ),
                ],
              ),
              if (answer != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Answer: $answer',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.successOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (q.explanation?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  q.explanation!,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
