import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:geemee_flutter/geemee_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../utils/constant/constant.dart';
import '../../services/auth_service.dart';
import '../../services/jackpot_service.dart';

class GemeeJackpotDialog extends StatelessWidget {
  final String? title;
  final String? message;

  const GemeeJackpotDialog({super.key, this.title, this.message});

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    bool barrierDismissible = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => GemeeJackpotDialog(title: title, message: message),
    );
  }

  Future<void> _openOfferWall(BuildContext context) async {
    try {
      // Check if placement ID is available
      if (geemeeOfferwallPlacementId.isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geemee offerwall is not configured'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if offerwall is ready
      final isReady = await GeemeeFlutter.isInterstitialReady(
        placementId: geemeeOfferwallPlacementId,
      );

      if (isReady) {
        // Mark as played today locally for the current user
        await JackpotService.markJackpotPlayedToday(
          userId: AuthService.currentUser?.uid,
        );

        // Open the offerwall
        try {
          await GeemeeFlutter.showInterstitial(
            placementId: geemeeOfferwallPlacementId,
          );

          // Close dialog and return success
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        } catch (e) {
          debugPrint('Error opening Lucky Jackpot: $e');
          if (context.mounted) {
            Navigator.of(context).pop(false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open Lucky Jackpot: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          Navigator.of(context).pop(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Lucky Jackpot is not ready. Please try again later.',
              ),
              backgroundColor: AppTheme.warningOrange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening Lucky Jackpot: $e');
      if (context.mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Lucky Jackpot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          boxShadow: AppTheme.cardShadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.warningOrange, AppTheme.warningOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      TablerIcons.lock,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title ?? 'Content Locked',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    message ??
                        'Game is locked, to unlock please play lucky jackpot first and come back later.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Play Now Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openOfferWall(context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                        elevation: 0,
                      ),
                      icon: const SizedBox.shrink(),
                      label: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.warningOrange,
                              Colors.deepOrange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                TablerIcons.player_play,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Play Lucky Jackpot',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
