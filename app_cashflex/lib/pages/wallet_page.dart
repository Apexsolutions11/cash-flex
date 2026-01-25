import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../pages/all_transactions_page.dart';
import '../pages/redeem_page.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../providers/wallet/history_provider.dart';
import '../utils/helper/helper.dart';
import '../providers/layout_provider.dart';
import '../services/layout_service.dart';
import '../models/user_data_model.dart';
import '../utils/navigation/bottom_nav_controller.dart';
import '../utils/helper/toast_manager.dart';
import '../theme/app_theme.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final Set<String> _seenOrderIds = {};
  bool _isInitialLoad = true;
  String? _listenedUserId;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final country = userAsync.asData?.value?.country ?? 'IN';
    final userId =
        userAsync.asData?.value?.userId ?? AuthService.currentUser?.uid ?? '';

    // Setup reward listener only once per userId
    if (userId.isNotEmpty && userId != _listenedUserId) {
      _listenedUserId = userId;
      _isInitialLoad = true;
      _seenOrderIds.clear();

      // Use postFrameCallback to ensure listener is set up after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.listen(
          earningHistoryProvider(userId),
          (previous, next) {
            next.whenData((earnings) {
              if (earnings.isEmpty) return;

              // On initial load, mark all existing rewards as seen
              if (_isInitialLoad) {
                for (final earning in earnings) {
                  final identifier = earning.orderId ?? 
                      '${earning.timestamp.seconds}_${earning.provider}_${earning.rewardAmount}';
                  _seenOrderIds.add(identifier);
                }
                _isInitialLoad = false;
                return;
              }

              // Check for new rewards by comparing orderIds
              // If orderId is available, use it; otherwise use timestamp as fallback
              for (final earning in earnings) {
                final identifier = earning.orderId ?? 
                    '${earning.timestamp.seconds}_${earning.provider}_${earning.rewardAmount}';
                
                if (!_seenOrderIds.contains(identifier)) {
                  // New reward detected - show toast
                  ToastManager.success(
                    '🎉 You earned ${earning.rewardAmount} coins from ${earning.provider}!',
                  );
                  _seenOrderIds.add(identifier);
                  // Only show toast for the first new reward found
                  break;
                }
              }
            });
          },
        );
      });
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
          },
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, userAsync.asData?.value),
                Padding(
                  padding: AppTheme.paddingHorizontalLarge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(
                        context,
                        ref,
                        userAsync.asData?.value,
                        country,
                        userId,
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildHistorySections(context, ref, userId),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserDataModel? userData) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppTheme.paddingLarge,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest,
                width: 2,
              ),
              image: userData?.photo != null && userData!.photo!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(userData.photo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: userData?.photo == null || userData!.photo!.isEmpty
                ? Icon(
                    TablerIcons.user,
                    color: Colors.white,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: AppTheme.spacingMediumSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  (userData?.name ?? 'User').toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    WidgetRef ref,
    UserDataModel? userData,
    String country,
    String userId,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: AppTheme.paddingLarge,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
        boxShadow: AppTheme.cardShadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSmall + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: const Icon(
                  TablerIcons.coin,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMediumSmall),
              Text(
                'Total Balance',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Text(
            '${userData?.balance ?? 0}',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'coins available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    boxShadow: AppTheme.cardShadowSmall,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateToRedeemPage(
                        context,
                        country,
                        userId,
                        userData?.balance ?? 0,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.arrow_up_right,
                              size: 18,
                              color: AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              'Withdraw',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Navigate to Home page (index 0)
                        final navController = BottomNavScope.maybeOf(context);
                        if (navController != null) {
                          navController.goTo(0);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(TablerIcons.gift, size: 18, color: Colors.white),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              'Earn More',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySections(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final layoutAsync = ref.watch(walletLayoutConfigProvider);

    return layoutAsync.when(
      data: (layoutConfig) {
        // We will display both sections if config allows, effectively stacking them with headers.
        final showTransactions = LayoutService.shouldShowWalletComponent(
          'wallet-transaction-history-section',
          layoutConfig,
        );
        final showRewards = LayoutService.shouldShowWalletComponent(
          'wallet-reward-history-section',
          layoutConfig,
        );

        // If config is missing or strict default needed, we can default to true since User requested "remain".
        // But adhering to config is safer for app integrity.

        return Column(
          children: [
            if (showTransactions) ...[
              _buildSectionHeader(context, 'Recent Transactions', () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AllTransactionsPage(
                      initialTab: AllTransactionsTab.transactions,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              _buildTransactionList(ref, userId, 'withdrawal'),
              const SizedBox(height: 24),
            ],

            if (showRewards) ...[
              _buildSectionHeader(context, 'Reward History', () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AllTransactionsPage(
                      initialTab: AllTransactionsTab.rewards,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              _buildTransactionList(ref, userId, 'earning'),
            ],
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onViewAll,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            'View All',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(WidgetRef ref, String userId, String type) {
    if (type == 'withdrawal') {
      final withdrawalHistoryAsync = ref.watch(
        withdrawalHistoryProvider(userId),
      );
      return withdrawalHistoryAsync.when(
        data: (withdrawals) {
          final theme = Theme.of(context);
          if (withdrawals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No transactions yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            );
          }
          return Column(
            children: withdrawals.take(5).map((withdrawal) {
              return _buildTransactionItem(
                title: 'Withdrawal',
                subtitle:
                    '${withdrawal.paymentMethod.toUpperCase()} - ${withdrawal.status}',
                amount: '-${withdrawal.coins}',
                isCredit: false,
                icon: TablerIcons.arrow_up_right,
                iconColor: AppTheme.secondaryCyan,
                time: withdrawal.timestamp.formatTimestamp(),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      );
    } else {
      final earningHistoryAsync = ref.watch(earningHistoryProvider(userId));
      return earningHistoryAsync.when(
        data: (earnings) {
          final theme = Theme.of(context);
          if (earnings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No rewards yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            );
          }
          return Column(
            children: earnings.take(5).map((earning) {
              return _buildTransactionItem(
                title: earning.provider,
                subtitle: 'Reward',
                amount: '+${earning.rewardAmount}',
                isCredit: true,
                icon: TablerIcons.gift,
                iconColor: AppTheme.accentEmerald,
                time: earning.timestamp.formatTimestamp(),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      );
    }
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required bool isCredit,
    required IconData icon,
    required Color iconColor,
    required String time,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMediumSmall),
      padding: AppTheme.paddingMedium,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
          width: 1,
        ),
        boxShadow: AppTheme.cardShadowSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMediumSmall),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.9),
                  iconColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isCredit
                      ? AppTheme.accentEmerald
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isCredit) ...[
                const SizedBox(width: 6),
                Image.asset(
                  'assets/images/coin.png',
                  width: 18,
                  height: 18,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToRedeemPage(
    BuildContext context,
    String country,
    String userId,
    int balance,
  ) {
    if (userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to redeem rewards.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RedeemPage(country: country, userId: userId, balance: balance),
      ),
    );
  }
}
