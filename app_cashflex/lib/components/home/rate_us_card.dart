import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/user_provider.dart';
import '../../services/cloud_functions.dart';
import '../../utils/helper/toast_manager.dart';
import '../../utils/helper/jackpot_check_helper.dart';
import '../../utils/constant/constant.dart';
import '../../theme/app_theme.dart';

class RateUsCard extends ConsumerWidget {
  const RateUsCard({super.key});

  String _applyCoinsTemplate(String input, int coins) {
    if (input.trim().isEmpty) return input;
    return input.replaceAll('{coins}', coins.toString());
  }

  Future<void> _showRateUsDialog(BuildContext context, WidgetRef ref) async {
    // Check if user has already rated
    final user = ref.read(currentUserProvider).asData?.value;

    if (user?.rated == true) {
      showDialog(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor =
              Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            title: Text('Already Rated', style: TextStyle(color: textColor)),
            content: Text(
              'You have already rated us. Thank you for your support!',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show rate us dialog
    showDialog(
      context: context,
      builder: (context) => _RateUsDialog(
        onRate: () async {
          Navigator.of(context).pop();
          await _openPlayStoreRating(context, ref);
        },
      ),
    );
  }

  Future<void> _openPlayStoreRating(BuildContext context, WidgetRef ref) async {
    try {
      // Get package name
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      // Play Store URL
      final playStoreUrl =
          'https://play.google.com/store/apps/details?id=$packageName';
      final uri = Uri.parse(playStoreUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Wait a bit then check if user rated (you could implement a better check)
        // For now, we'll just show a message that they can claim reward after rating
        Future.delayed(const Duration(seconds: 2), () {
          try {
            // Check if navigator is still available before showing dialog
            Navigator.of(context, rootNavigator: true);
            _showClaimRewardDialog(context, ref);
          } catch (e) {
            // Context is no longer valid, skip showing dialog
            debugPrint('Cannot show claim reward dialog: context is invalid - $e');
          }
        });
      } else {
        ToastManager.error(msg: 'Could not open Play Store');
      }
    } catch (e) {
      ToastManager.error(msg: 'Error opening Play Store');
    }
  }

  Future<void> _showClaimRewardDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Check if navigator is available before showing dialog
      Navigator.of(context, rootNavigator: true);
    } catch (e) {
      // Context is no longer valid, skip showing dialog
      debugPrint('Cannot show claim reward dialog: context is invalid - $e');
      return;
    }
    
    final coins = rateUsCoins;
    final contentText = rateUsDialogText.trim().isNotEmpty
        ? _applyCoinsTemplate(rateUsDialogText, coins)
        : 'After rating us on Play Store, tap the button below to claim your $coins coins reward!';

    final theme = Theme.of(context);
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            children: [
              Icon(TablerIcons.star, color: AppTheme.secondaryCyan, size: 24),
              const SizedBox(width: 8),
              Text('Claim Your Reward', style: theme.textTheme.titleLarge),
            ],
          ),
          content: Text(
            contentText,
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Later', style: theme.textTheme.labelLarge),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _claimRatingReward(ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryCyan,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: Text('Claim $coins Coins', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Context is no longer valid, skip showing dialog
      debugPrint('Cannot show claim reward dialog: context error - $e');
    }
  }

  Future<void> _claimRatingReward(WidgetRef ref) async {
    try {
      final coins = rateUsCoins;
      final result = await CloudFunctions.ratingReward();

      if (result['response'] == 'success') {
        ToastManager.success('You received $coins coins for rating us!');
        // User provider is stream-based; balance will update automatically.
      } else {
        final reason =
            result['reason'] ?? result['message'] ?? 'Failed to claim reward';
        if (reason.toString().contains('Already') ||
            reason.toString().contains('already')) {
          ToastManager.error(msg: 'You have already claimed this reward');
        } else {
          ToastManager.error(msg: reason.toString());
        }
      }
    } catch (e) {
      ToastManager.error(msg: 'Error claiming reward. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = rateUsCoins;
    final subtitle = rateUsCardText.trim().isNotEmpty
        ? _applyCoinsTemplate(rateUsCardText, coins)
        : 'Rate us 5 star and get $coins coins';

    return GestureDetector(
      onTap: () async {
        final canProceed = await JackpotCheckHelper.checkAndShowDialogIfNeeded(
          context,
        );
        if (!canProceed) return;
        _showRateUsDialog(context, ref);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient1,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: AppTheme.cardShadowSmall,
        ),
        child: Row(
          children: [
            // Icon on the left
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TablerIcons.star,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // Content in the middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rate Us',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/coin.png',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$coins Coins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon on the right
            const Icon(
              TablerIcons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _RateUsDialog extends StatelessWidget {
  final VoidCallback onRate;

  const _RateUsDialog({required this.onRate});

  @override
  Widget build(BuildContext context) {
    final coins = rateUsCoins;
    final dialogText = rateUsDialogText.trim().isNotEmpty
        ? rateUsDialogText.replaceAll('{coins}', coins.toString())
        : 'We would love to hear your feedback! Rate us on Play Store and get rewarded with';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.secondaryCyan, AppTheme.primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryCyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                TablerIcons.star,
                size: 44,
                color: theme.colorScheme.onPrimary,
              ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
              'Rate Us on Play Store',
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
              ),
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
              dialogText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Coins reward
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.secondaryCyan.withOpacity(0.1)
                    : AppTheme.secondaryCyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppTheme.secondaryCyan.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/coin.png', width: 24, height: 24),
                  const SizedBox(width: 8),
                  Text(
                    '$coins Coins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondaryCyan,
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 32),
          // Buttons
          Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isDark ? Colors.white60 : Colors.black54,
                    ),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryCyan,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(TablerIcons.star, size: 18, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Rate Us',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
          ),
        ],
      ),
    );
  }
}
