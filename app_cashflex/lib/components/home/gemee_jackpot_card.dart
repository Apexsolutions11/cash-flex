import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geemee_flutter/geemee_flutter.dart';
import '../../utils/constant/constant.dart';
import '../../services/layout_service.dart';
import '../../services/jackpot_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class GemeeJackpotCard extends StatefulWidget {
  final ComponentConfig? config;

  const GemeeJackpotCard({super.key, this.config});

  @override
  State<GemeeJackpotCard> createState() => _GemeeJackpotCardState();
}

class _GemeeJackpotCardState extends State<GemeeJackpotCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    // Use 0 to 1 range so reset() returns to 0 (center/neutral position)
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    // Start shake animation if enabled
    if (widget.config?.shakeAnimationEnabled == true) {
      _startShakeAnimation();
    }
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startShakeAnimation() {
    // Shake twice, then stop, then repeat after a delay
    void performShake() {
      // First shake: forward then back
      _shakeController.forward().then((_) {
        _shakeController.reverse().then((_) {
          // Second shake: forward then back
          _shakeController.forward().then((_) {
            _shakeController.reverse().then((_) {
              // Animate to center (0.5) to ensure card is perfectly aligned during wait period
              _shakeController.animateTo(0.5);
              // Wait 1 second before next shake cycle
              _shakeTimer = Timer(const Duration(milliseconds: 1000), () {
                if (mounted && widget.config?.shakeAnimationEnabled == true) {
                  performShake();
                }
              });
            });
          });
        });
      });
    }

    performShake();
  }

  void _stopShakeAnimation() {
    _shakeTimer?.cancel();
    _shakeController.stop();
    _shakeController.reset();
  }

  @override
  void didUpdateWidget(GemeeJackpotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animation state when config changes
    if (widget.config?.shakeAnimationEnabled == true) {
      if (!_shakeController.isAnimating && _shakeTimer == null) {
        _startShakeAnimation();
      }
    } else {
      _stopShakeAnimation();
    }
  }

  Future<void> _openOfferWall(BuildContext context) async {
    try {
      // Check if placement ID is available
      if (geemeeOfferwallPlacementId.isEmpty) {
        if (context.mounted) {
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
        } catch (e) {
          debugPrint('Error opening Lucky Bonus: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open Lucky Bonus: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Lucky Bonus is not ready. Please try again later.',
              ),
              backgroundColor: AppTheme.warningOrange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening Lucky Bonus: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Lucky Bonus: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildShakeWidget(Widget child) {
    if (widget.config?.shakeAnimationEnabled != true) {
      return child;
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // Create a dynamic shake effect with rotation and translation
        // Reduced shake intensity
        final shakeAmount = 6; // Horizontal shake distance
        final rotationAmount = 0.04; // Rotation in radians

        // The animation value oscillates between 0 and 1
        // Convert to -1 to 1 range for symmetric shake motion
        final normalizedValue =
            (_shakeAnimation.value - 0.5) * 2; // Maps 0->-1, 0.5->0, 1->1

        // Use normalized value to create a back-and-forth shake motion
        final shakeX = normalizedValue * shakeAmount;
        // Add subtle vertical movement that follows a parabolic curve
        // When normalizedValue is 0 (center), shakeY is 0
        // The square ensures it's always positive and returns to 0 at center
        final shakeY = (normalizedValue * normalizedValue) * 1.2;
        final rotation = normalizedValue * rotationAmount;

        return Transform(
          transform: Matrix4.identity()
            ..translate(shakeX, shakeY)
            ..rotateZ(rotation),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: () => _openOfferWall(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
          boxShadow: AppTheme.cardShadowSmall,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Lucky Bonus',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Win amazing rewards!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _openOfferWall(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryTeal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Play Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Spacer for image
                const SizedBox(width: 100),
              ],
            ),
            // Character image at bottom right
            Positioned(
              bottom: -20,
              right: -10,
              child: Image.asset(
                'assets/images/gemee_jackpot.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );

    return _buildShakeWidget(cardContent);
  }
}
