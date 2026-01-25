import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/wallet/history_provider.dart';
import '../services/auth_service.dart';
import '../utils/helper/helper.dart';

enum AllTransactionsTab {
  transactions,
  rewards,
}

class AllTransactionsPage extends ConsumerWidget {
  final AllTransactionsTab initialTab;

  const AllTransactionsPage({
    super.key,
    this.initialTab = AllTransactionsTab.transactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = AuthService.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in to view your transactions.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final withdrawalAsync = ref.watch(withdrawalHistoryProvider(userId));
    final earningAsync = ref.watch(earningHistoryProvider(userId));

    final initialIndex = initialTab == AllTransactionsTab.transactions ? 0 : 1;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Transactions'),
              Tab(text: 'Rewards'),
            ],
          ),
      ),
      body: SafeArea(
          child: TabBarView(
            children: [
              // Transactions (Redeems)
              withdrawalAsync.when(
                  data: (withdrawals) {
                  if (withdrawals.isEmpty) {
                    return const Center(
                      child: Text(
                        'No transactions yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final items = withdrawals
                      .map(
                        (w) => _TransactionItem(
                          title: 'Redeem',
                              subtitle:
                                  '${w.paymentMethod.toUpperCase()} - ${w.status}',
                              isCredit: false,
                              amount: '-${w.coins}',
                              icon: LucideIcons.arrowUpRight,
                              color: Colors.red,
                              timestampMs: w.timestampMs,
                              timeLabel: w.timestamp.formatTimestamp(),
                        ),
                      )
                      .toList()
                    ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _TransactionCard(item: items[index]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading transactions: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),

              // Rewards (Earnings)
              earningAsync.when(
                data: (earnings) {
                  if (earnings.isEmpty) {
                    return const Center(
                      child: Text(
                        'No rewards yet.',
                        style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                  final items = earnings
                      .map(
                        (e) => _TransactionItem(
                          title: 'Reward',
                              subtitle: e.provider,
                              isCredit: true,
                              amount: '+${e.rewardAmount}',
                              icon: LucideIcons.coins,
                              color: Colors.green,
                          timestampMs: e.timestamp.millisecondsSinceEpoch,
                              timeLabel: e.timestamp.formatTimestamp(),
                            ),
                      )
                      .toList()
                    ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.separated(
                          itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _TransactionCard(item: items[index]),
                      ),
                    );
                  },
                loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                    'Error loading rewards: $error',
                      style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionItem {
  final String title;
  final String subtitle;
  final String amount;
  final bool isCredit;
  final IconData icon;
  final Color color;
  final int timestampMs;
  final String timeLabel;

  _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.icon,
    required this.color,
    required this.timestampMs,
    required this.timeLabel,
  });
}

class _TransactionCard extends StatelessWidget {
  final _TransactionItem item;

  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.timeLabel,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.amount,
            style: TextStyle(
              color: item.isCredit ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}



