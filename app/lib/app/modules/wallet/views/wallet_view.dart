import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/app_theme.dart';
import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

String _fmtDate(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Coin wallet: balance, earn paths, transaction history.
class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final auth = Get.find<AuthRepository>();
    final ledger = Get.find<CoinLedger>();
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
                    Text('Wallet', style: text.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppInsets.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _balanceCard(context, text, auth),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Earn coins', style: text.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      _earnTile(
                        context,
                        text,
                        EliteAssets.dailyCoins,
                        'Daily scratch card',
                        'Scratch once a day for up to 100 coins',
                        () => Get.toNamed(Routes.dailyReward),
                      ),
                      _earnTile(
                        context,
                        text,
                        EliteAssets.referEarn,
                        'Refer & earn',
                        '100 coins per friend who joins',
                        () => Get.toNamed(Routes.referEarn),
                      ),
                      _earnTile(
                        context,
                        text,
                        EliteAssets.trueFalse,
                        'True / False zone',
                        'Fast rounds, coin rewards',
                        () => Get.toNamed(Routes.trueFalse),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('History', style: text.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      _history(context, text, ledger),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(
      BuildContext context, TextTheme text, AuthRepository auth) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        gradient: AppGradients.sunny,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          EliteAssets.svg(EliteAssets.wallet, size: 56),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COIN BALANCE',
                style: text.labelLarge?.copyWith(color: Colors.white70),
              ),
              Obx(() => Text(
                    '${auth.currentUser.value?.coins ?? 0}',
                    style: text.displaySmall
                        ?.copyWith(color: Colors.white),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earnTile(BuildContext context, TextTheme text, String icon,
      String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          child: Row(
            children: [
              EliteAssets.svg(icon, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _history(
      BuildContext context, TextTheme text, CoinLedger ledger) {
    final entries = ledger.entries();
    if (entries.isEmpty) {
      return GlassCard(
        child: Center(
          child: Padding(
            padding: AppInsets.card,
            child: Text(
              'No transactions yet.\nEarn your first coins above!',
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < entries.length && i < 20; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  EliteAssets.svg(
                      entries[i].amount >= 0
                          ? EliteAssets.earnedCoin
                          : EliteAssets.coin,
                      size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entries[i].reason, style: text.bodyMedium),
                        Text(
                          _fmtDate(entries[i].at),
                          style: text.bodySmall?.copyWith(
                            color:
                                AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${entries[i].amount}',
                    style: text.titleMedium?.copyWith(
                      color: AppColors.successOf(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
