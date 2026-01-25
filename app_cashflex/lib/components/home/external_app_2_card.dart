import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/external_app_model.dart';
import '../../providers/external_app_provider.dart';
import '../common/app_badge.dart';
import '../../widgets/shimmer_widget.dart' show ExternalAppShimmerCard;
import '../../utils/helper/jackpot_check_helper.dart';
import '../../utils/helper/external_app_helper.dart';
import '../../theme/app_theme.dart';
import '../external_app_modal.dart';

class ExternalApp2Card extends ConsumerWidget {
  const ExternalApp2Card({super.key});

  void _showModal(BuildContext context, ExternalAppModel app) {
    if (app.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExternalAppModal(app: app),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(externalApp2Provider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return appAsync.when(
      data: (app) {
        if (app.isEmpty) {
          return const SizedBox.shrink();
        }

        final badgeText = (app.badgeText ?? '').trim();
        final badgeVariant = (app.badgeVariant ?? '').trim();
        final showBadge =
            badgeText.isNotEmpty ||
            (badgeVariant.isNotEmpty && badgeVariant.toLowerCase() != 'none');

        return GestureDetector(
          onTap: () async {
            final canProceed =
                await JackpotCheckHelper.checkAndShowDialogIfNeeded(context);
            if (!canProceed) return;
            
            // Check if app is installed and launch directly, otherwise show modal
            final launchedDirectly = await ExternalAppHelper.handleAppCardTap(app);
            if (!launchedDirectly) {
              _showModal(context, app);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120, // Match the height of first app
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : AppTheme.cardShadowSmall,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content on the left
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
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                final rating = app.stars ?? 0.0;
                                if (index < rating.floor()) {
                                  return const Icon(
                                    TablerIcons.star_filled,
                                    size: 10,
                                    color: Colors.amber,
                                  );
                                } else if (index < rating) {
                                  return const Icon(
                                    TablerIcons.star_half_filled,
                                    size: 10,
                                    color: Colors.amber,
                                  );
                                } else {
                                  return Icon(
                                    TablerIcons.star,
                                    size: 10,
                                    color: isDark
                                        ? Colors.grey.withOpacity(0.3)
                                        : Colors.grey.shade300,
                                  );
                                }
                              }),
                              const Spacer(),
                              Image.asset(
                                'assets/images/coin.png',
                                width: 10,
                                height: 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${app.coins ?? 0}',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Square image on the right
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        width: 120,
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
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              )
                            : null,
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
      },
      loading: () => const ExternalAppShimmerCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
