import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/modules/categories/controllers/categories_controller.dart';
import 'package:quiz_arena/app/modules/shared/widgets/difficulty_sheet.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: ArenaBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: controller.refreshAll,
            color: AppColors.blue,
            backgroundColor: AppColors.elevatedOf(context),
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView(
                  padding: AppInsets.screen,
                  children: const [
                    ShimmerList(count: 6, itemHeight: 150),
                  ],
                );
              }
              final categories = controller.categories;
              if (categories.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    EmptyState(
                      emoji: '🗂️',
                      title: 'No categories yet',
                      subtitle:
                          'Pull down to refresh and try again.',
                    ),
                  ],
                );
              }
              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppInsets.screen.copyWith(bottom: 40),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.86,
                ),
                itemCount: categories.length,
                itemBuilder: (context, i) => FadeSlideIn(
                  index: i,
                  child: _CategoryCard(category: categories[i]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final QuizCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => DifficultySheet.pick(category),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'category-hero-${category.id}',
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${category.quizCount} quizzes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.adaptiveSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
