import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/utils/formatters.dart';
import 'package:quiz_arena/app/core/utils/level_config.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

import '../controllers/profile_controller.dart';

/// Player profile: avatar header, XP progress, quick stats and the
/// Badges / Stats / Details tabs. Bottom-nav tab index 3.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      currentIndex: 3,
      body: Obx(() {
        final user = controller.user ?? AppUser.demo();
        final progress = controller.progress;
        final level = LevelConfig.levelForXp(user.xp);
        final tier = LevelConfig.tierForLevel(level);
        final tierColor = AppColors.tierColor(tier);
        return Column(
          children: [
            _header(user, level, tier, tierColor),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(child: XpProgressBar(xp: user.xp)),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _quickStats(user, progress),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _quickLinks(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TabBar(
                controller: controller.tabController,
                indicator: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.adaptiveSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Badges'),
                  Tab(text: 'Stats'),
                  Tab(text: 'Details'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  _badgesTab(),
                  _statsTab(progress),
                  _detailsTab(user, level, tier),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _header(AppUser user, int level, String tier, Color tierColor) {
    return Padding(
      padding: AppInsets.screen,
      child: Column(
        children: [
          ArenaAvatar(imageUrl: user.avatar, name: user.username, radius: 40),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tierColor, tierColor.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'LV $level · $tier',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.email,
            style: TextStyle(
              color: AppColors.adaptiveSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Purple gradient panel: POINTS / STREAK / COINS.
  Widget _quickStats(AppUser user, PlayerProgress progress) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violetDeep, AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _quickStat('POINTS', '${user.xp}'),
          _quickStat('STREAK', '${progress.dailyStreak}'),
          _quickStat('COINS', '${user.coins}'),
        ],
      ),
    );
  }

  Widget _quickStat(String label, String value) => Expanded(        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      );

  /// Quick links to wallet, statistics and bookmarks.
  Widget _quickLinks(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _linkTile(
            context,
            EliteAssets.wallet,
            'Wallet',
            Routes.wallet,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _linkTile(
            context,
            EliteAssets.statistics,
            'Statistics',
            Routes.statistics,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _linkTile(
            context,
            EliteAssets.bookmark,
            'Bookmarks',
            Routes.bookmarks,
          ),
        ),
      ],
    );
  }

  Widget _linkTile(
      BuildContext context, String icon, String label, String route) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: () => Get.toNamed(route),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          EliteAssets.svg(icon, size: 30),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: text.labelLarge),
        ],
      ),
    );
  }

  /// Badge shelf: unlocked badges in color, locked ones greyed with 🔒.
  Widget _badgesTab() {
    final badges = controller.badges;
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.82,
      ),
      itemCount: badges.length,
      itemBuilder: (context, i) => _badgeTile(badges[i]),
    );
  }

  Widget _badgeTile(Badge b) {
    final color = _badgeColor(b.colorHex);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: b.unlocked
            ? color.withValues(alpha: 0.15)
            : AppColors.adaptiveSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: b.unlocked
              ? color.withValues(alpha: 0.6)
              : AppColors.adaptiveBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: b.unlocked ? 1 : 0.35,
                child: Text(
                  b.emoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
              if (!b.unlocked)
                const Text('🔒', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            b.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(String colorHex) {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }

  /// Lifetime gameplay stats.
  Widget _statsTab(PlayerProgress p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GlassCard(
        child: Column(
          children: [
            _statRow('Quizzes played', '${p.totalQuizzes}'),
            _statRow('Accuracy', Formatters.percent(p.accuracy)),
            _statRow('Best streak', 'x${p.bestStreak}'),
            _statRow('Perfect games', '${p.perfectGames}'),
            _statRow('Duels won', '${p.duelsWon}'),
            _statRow('Marathon best', '${p.marathonBest}'),
            _statRow('Daily streak', '${p.dailyStreak} days'),
            _statRow('Questions answered', '${p.totalAnswered}'),
          ],
        ),
      ),
    );
  }

  /// Account details.
  Widget _detailsTab(AppUser user, int level, String tier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GlassCard(
        child: Column(
          children: [
            _statRow('Username', user.username),
            _statRow('Email', user.email),
            _statRow('Level', '$level'),
            _statRow('Tier', tier),
            _statRow('Member', 'Arena player'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.adaptiveSecondary),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}
