import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/contest_repository.dart';
import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

String _fmtDate(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Coin wallet — Elite Quiz UI: pink balance header, white earn tiles,
/// transaction history list.
class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthRepository>();
    final ledger = Get.find<CoinLedger>();
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: const EliteAppBar(title: 'Wallet'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _balanceCard(auth),
            const SizedBox(height: 20),
            Text('Earn coins',
                style:
                    eliteText(size: 18, weight: FontWeight.bold)),
            const SizedBox(height: 8),
            _earnTile(
              EliteAssets.dailyCoins,
              'Daily scratch card',
              'Scratch once a day for up to 100 coins',
              () => Get.toNamed(Routes.dailyReward),
            ),
            _earnTile(
              EliteAssets.referEarn,
              'Refer & earn',
              '100 coins per friend who joins',
              () => Get.toNamed(Routes.referEarn),
            ),
            _earnTile(
              EliteAssets.trueFalse,
              'True / False zone',
              'Fast rounds, coin rewards',
              () => Get.toNamed(Routes.trueFalse),
            ),
            const SizedBox(height: 20),
            Text('History',
                style:
                    eliteText(size: 18, weight: FontWeight.bold)),
            const SizedBox(height: 8),
            _history(ledger),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(AuthRepository auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EliteTheme.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          SvgPicture.asset(EliteAssets.wallet,
              width: 56, height: 56),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COIN BALANCE',
                  style: eliteText(
                      size: 13,
                      weight: FontWeight.w600,
                      color:
                          Colors.white.withValues(alpha: 0.8))),
              Obx(() => Text(
                    '${auth.currentUser.value?.coins ?? 0}',
                    style: eliteText(
                        size: 36,
                        weight: FontWeight.w800,
                        color: Colors.white),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earnTile(String icon, String title, String subtitle,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SvgPicture.asset(icon, width: 40, height: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: eliteText(
                            size: 16, weight: FontWeight.bold)),
                    Text(subtitle,
                        style: eliteText(
                            size: 13,
                            color: EliteTheme.primaryText.withValues(
                                alpha: 0.7))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: EliteTheme.primaryText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _history(CoinLedger ledger) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _serverTransactions(),
      builder: (context, snap) {
        final server = snap.data?['transactions'] as List?;
        if (server != null && server.isNotEmpty) {
          return _txList(server
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList());
        }
        final entries = ledger.entries();
        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'No transactions yet.\nEarn your first coins above!',
                style: eliteText(size: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return _txList(entries
            .map((e) => {
                  'amount': e.amount,
                  'reason': e.reason,
                  'createdAt': e.at.toIso8601String(),
                })
            .toList());
      },
    );
  }

  Future<Map<String, dynamic>> _serverTransactions() async {
    try {
      final repo = Get.isRegistered<ContestRepository>()
          ? Get.find<ContestRepository>()
          : ContestRepository(api: Get.find<ApiService>());
      return await repo.transactions(limit: 20);
    } catch (_) {
      return const {};
    }
  }

  Widget _txList(List<Map<String, dynamic>> txs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (var i = 0; i < txs.length && i < 20; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SvgPicture.asset(
                      (txs[i]['amount'] as num? ?? 0) >= 0
                          ? EliteAssets.earnedCoin
                          : EliteAssets.coin,
                      width: 28,
                      height: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${txs[i]['reason'] ?? ''}',
                            style: eliteText(
                                size: 14,
                                weight: FontWeight.w600)),
                        Text(
                          _fmtDate(DateTime.tryParse(
                                  '${txs[i]['createdAt'] ?? ''}') ??
                              DateTime.now()),
                          style: eliteText(
                              size: 12,
                              color: EliteTheme.primaryText.withValues(
                                  alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  _amountText(
                      (txs[i]['amount'] as num?)?.toInt() ?? 0),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _amountText(int amount) {
    final positive = amount >= 0;
    return Text(
      '${positive ? '+' : ''}$amount',
      style: eliteText(
        size: 16,
        weight: FontWeight.w800,
        color: positive ? EliteTheme.correct : EliteTheme.wrong,
      ),
    );
  }
}
