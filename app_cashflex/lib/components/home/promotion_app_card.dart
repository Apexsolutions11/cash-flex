import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../models/external_app_model.dart';
import '../../utils/helper/jackpot_check_helper.dart';
import '../../utils/helper/external_app_helper.dart';
import '../common/app_badge.dart';
import '../external_app_modal.dart';

class PromotionAppCard extends StatelessWidget {
  final ExternalAppModel app;
  final bool isHorizontal;
  final double? height;
  final bool useColumnLayout;

  const PromotionAppCard({
    super.key,
    required this.app,
    this.isHorizontal = false,
    this.height,
    this.useColumnLayout = false,
  });

  void _showModal(BuildContext context, ExternalAppModel app) {
    if (app.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExternalAppModal(app: app),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    final canProceed = await JackpotCheckHelper.checkAndShowDialogIfNeeded(
      context,
    );
    if (!canProceed) return;
    
    // Check if app is installed and launch directly, otherwise show modal
    final launchedDirectly = await ExternalAppHelper.handleAppCardTap(app);
    if (!launchedDirectly && context.mounted) {
      _showModal(context, app);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (app.isEmpty) {
      return const SizedBox.shrink();
    }

    if (useColumnLayout) {
      return _buildColumnLayout(context);
    }
    if (isHorizontal) {
      return _buildHorizontalLayout(context);
    }
    return _buildVerticalLayout(context);
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final theme = Theme.of(context);
    final badgeText = (app.badgeText ?? '').trim();
    final badgeVariant = (app.badgeVariant ?? '').trim();
    final showBadge =
        badgeText.isNotEmpty ||
        (badgeVariant.isNotEmpty && badgeVariant.toLowerCase() != 'none');

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: height ?? 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppTheme.cardShadowSmall,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Square image on the left
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    image: app.photo != null
                        ? DecorationImage(
                            image: NetworkImage(app.photo!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                    gradient: app.photo == null
                        ? AppTheme.primaryGradient
                        : null,
                  ),
                  child: app.photo == null
                      ? Center(
                          child: Icon(
                            TablerIcons.device_gamepad_2,
                            size: 32,
                            color: theme.colorScheme.onPrimary.withOpacity(0.5),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                // Content on the right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        app.title ?? 'App',
                        style: TextStyle(
                          color: theme.textTheme.titleMedium?.color,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Description with ellipsis
                      if (app.description != null &&
                          app.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            app.description!,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                              fontSize: 11,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      // Rating and Coins
                      _buildRatingAndCoins(context, iconSize: 10, fontSize: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Badge overflowing on top with negative value
          if (showBadge)
            Positioned(
              top: -8,
              right: 8,
              child: AppBadge(
                text: badgeText.isEmpty ? null : badgeText,
                variant: badgeVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    final theme = Theme.of(context);

    final badgeText = (app.badgeText ?? '').trim();
    final badgeVariant = (app.badgeVariant ?? '').trim();
    final showBadge =
        badgeText.isNotEmpty ||
        (badgeVariant.isNotEmpty && badgeVariant.toLowerCase() != 'none');

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppTheme.cardShadowSmall,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Square thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    image: app.photo != null
                        ? DecorationImage(
                            image: NetworkImage(app.photo!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                    gradient: app.photo == null
                        ? AppTheme.primaryGradient
                        : null,
                    boxShadow: app.photo != null ? AppTheme.cardShadowSmall : null,
                  ),
                  child: app.photo == null
                      ? Icon(
                          TablerIcons.device_gamepad_2,
                          size: 32,
                          color: theme.colorScheme.onPrimary.withOpacity(0.7),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        app.title ?? 'App',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Description with ellipsis
                      if (app.description != null &&
                          app.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          app.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.8),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildRatingAndCoins(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Badge overflowing on top with negative value
          if (showBadge)
            Positioned(
              top: -8,
              right: 8,
              child: AppBadge(
                text: badgeText.isEmpty ? null : badgeText,
                variant: badgeVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColumnLayout(BuildContext context) {
    final theme = Theme.of(context);
    final badgeText = (app.badgeText ?? '').trim();
    final badgeVariant = (app.badgeVariant ?? '').trim();
    final showBadge =
        badgeText.isNotEmpty ||
        (badgeVariant.isNotEmpty && badgeVariant.toLowerCase() != 'none');

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppTheme.cardShadowSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Square image on top
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      image: app.photo != null
                          ? DecorationImage(
                              image: NetworkImage(app.photo!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                      gradient: app.photo == null
                          ? AppTheme.primaryGradient
                          : null,
                    ),
                    child: app.photo == null
                        ? Center(
                            child: Icon(
                              TablerIcons.device_gamepad_2,
                              size: 32,
                              color: theme.colorScheme.onPrimary.withOpacity(
                                0.5,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  app.title ?? 'App',
                  style: TextStyle(
                    color: theme.textTheme.titleMedium?.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Rating and Coins
                _buildRatingAndCoins(context, iconSize: 10, fontSize: 10),
              ],
            ),
          ),
          // Badge overflowing on top with negative value
          if (showBadge)
            Positioned(
              top: -8,
              right: 8,
              child: AppBadge(
                text: badgeText.isEmpty ? null : badgeText,
                variant: badgeVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingAndCoins(
    BuildContext context, {
    double iconSize = 14,
    double fontSize = 13,
  }) {
    final theme = Theme.of(context);
    final rating = app.stars ?? 0.0;
    final coins = app.coins ?? 0;

    return Row(
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(
              TablerIcons.star_filled,
              size: iconSize,
              color: Colors.amber,
            );
          } else if (index < rating) {
            return Icon(
              TablerIcons.star_half_filled,
              size: iconSize,
              color: Colors.amber,
            );
          } else {
            return Icon(
              TablerIcons.star,
              size: iconSize,
              color: theme.disabledColor.withOpacity(0.3),
            );
          }
        }),
        const Spacer(),
        Image.asset(
          'assets/images/coin.png',
          width: iconSize + 2,
          height: iconSize + 2,
        ),
        const SizedBox(width: 4),
        Text(
          '$coins',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
