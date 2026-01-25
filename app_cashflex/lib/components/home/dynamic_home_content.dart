import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/layout_service.dart';
import '../../providers/layout_provider.dart';
import '../common/app_badge.dart';
import 'external_app_1_card.dart';
import 'external_app_2_card.dart';
import 'external_app_3_card.dart';
import 'external_app_4_card.dart';
import 'review_offers_card.dart';
import 'gemee_jackpot_card.dart';
import 'catch_coins_card.dart';
import 'general_quiz_card.dart';
import 'adjoe_card.dart';
import 'trending_apps_card.dart';
import 'rate_us_card.dart';

class DynamicHomeContent extends ConsumerWidget {
  const DynamicHomeContent({super.key});

  bool _isHeading(ComponentConfig c) => c.type == 'heading';

  Widget _buildHeading(String title) {
    final t = title.trim().isEmpty ? 'Section' : title.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        t,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildComponentById(
    ComponentId id,
    ComponentConfig? config, {
    bool isInRow = false,
  }) {
    switch (id) {
      case 'promo-app-1':
        return const ExternalApp1Card();
      case 'promo-app-2':
        return const ExternalApp2Card();
      case 'promo-app-3':
        return ExternalApp3Card(isInRow: isInRow);
      case 'promo-app-4':
        return const ExternalApp4Card();
      case 'review-offers':
        return const ReviewOffersCard();
      case 'gemee-jackpot':
        return GemeeJackpotCard(config: config);
      case 'tic-tac-toe':
        return const CatchCoinsCard();
      case 'math-quiz':
        return const GeneralQuizCard();
      case 'adjoe':
        return const AdjoeCard();
      case 'more-apps':
        return const TrendingAppsCard();
      case 'rate-us':
        return const RateUsCard();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildItem(ComponentConfig c, {bool isInRow = false}) {
    if (_isHeading(c)) {
      return _buildHeading(c.title ?? '');
    }
    final child = _buildComponentById(c.id, c, isInRow: isInRow);

    // Promo apps have their own badge config in admin/app1..app4 (Promotion Apps page)
    // so we don't overlay layout-level badges for them (avoids double badges).
    final isPromo = c.id.startsWith('promo-app-');
    if (isPromo) return child;

    if ((c.badgeText == null || c.badgeText!.trim().isEmpty) &&
        (c.badgeVariant == null || c.badgeVariant!.trim().isEmpty)) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: IgnorePointer(
            child: AppBadge(text: c.badgeText, variant: c.badgeVariant),
          ),
        ),
      ],
    );
  }

  bool _isRowPair(ComponentConfig a, ComponentConfig b) {
    if (_isHeading(a) || _isHeading(b)) return false;
    final isTtt = a.id == 'tic-tac-toe' || b.id == 'tic-tac-toe';
    final isPromoApp3 = a.id == 'promo-app-3' || b.id == 'promo-app-3';
    return isTtt && isPromoApp3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(layoutConfigProvider);

    return layoutAsync.when(
      data: (layoutConfig) {
        if (layoutConfig == null) {
          // Fallback to google layout when config is null
          return _buildGoogleLayout();
        }

        final enabledComponents = LayoutService.getEnabledComponents(
          layoutConfig.pageLayout.homepage,
        );

        // Group components for row handling
        final List<Widget> widgets = [];
        int i = 0;

        while (i < enabledComponents.length) {
          final current = enabledComponents[i];

          // Skip promo-app-1 and promo-app-2 (they're now at the top of home page)
          if (current.id == 'promo-app-1' || current.id == 'promo-app-2') {
            i++;
            continue;
          }

          // Headings render as-is (no special pairing)
          if (_isHeading(current)) {
            widgets.add(_buildItem(current));
            widgets.add(const SizedBox(height: 12));
            i++;
            continue;
          }

          // Special case: If current is jackpot card, show next two cards in a row
          if (current.id == 'gemee-jackpot' && i < enabledComponents.length - 2) {
            final next1 = enabledComponents[i + 1];
            final next2 = enabledComponents[i + 2];
            
            // Skip if either next card is a heading
            if (!_isHeading(next1) && !_isHeading(next2)) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildItem(current),
                ),
              );
              widgets.add(const SizedBox(height: 12));
              
              // Build row with next two cards
              widgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildItem(next1, isInRow: next1.id == 'promo-app-3'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildItem(next2, isInRow: next2.id == 'promo-app-3'),
                      ),
                    ],
                  ),
                ),
              );
              widgets.add(const SizedBox(height: 12));
              i += 3;
              continue;
            }
          }

          // Row pair: Tic Tac Toe + Promotion App 3 when adjacent in admin layout
          if (i < enabledComponents.length - 1) {
            final next = enabledComponents[i + 1];
            if (_isRowPair(current, next)) {
              // Determine which one is app3 to pass isInRow parameter
              final isCurrentApp3 = current.id == 'promo-app-3';
              final isNextApp3 = next.id == 'promo-app-3';

              widgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildItem(current, isInRow: isCurrentApp3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildItem(next, isInRow: isNextApp3)),
                    ],
                  ),
                ),
              );
              widgets.add(const SizedBox(height: 16));
              i += 2;
              continue;
            }
          }

          // Regular component
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildItem(current),
            ),
          );

          widgets.add(const SizedBox(height: 12));
          i++;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        );
      },
      loading: () => _buildGoogleLayout(), // Show google layout while loading
      error: (_, __) => _buildGoogleLayout(), // Show google layout on error
    );
  }

  Widget _buildGoogleLayout() {
    // Google layout - minimal layout with essential components only
    // This is shown by default, while loading, or on error
    return FutureBuilder<LayoutConfig?>(
      future: LayoutService.loadLayout('google'),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final layoutConfig = snapshot.data!;
          final enabledComponents = LayoutService.getEnabledComponents(
            layoutConfig.pageLayout.homepage,
          );

          if (enabledComponents.isEmpty) {
            // If google layout has no components, show minimal default
            return _buildMinimalGoogleLayout();
          }

          // Build layout from google config
          final List<Widget> widgets = [];
          int i = 0;

          while (i < enabledComponents.length) {
            final current = enabledComponents[i];

            // Skip promo-app-1 and promo-app-2 (they're now at the top of home page)
            if (current.id == 'promo-app-1' || current.id == 'promo-app-2') {
              i++;
              continue;
            }

            if (_isHeading(current)) {
              widgets.add(_buildItem(current));
              widgets.add(const SizedBox(height: 12));
              i++;
              continue;
            }

            // Special case: If current is jackpot card, show next two cards in a row
            if (current.id == 'gemee-jackpot' && i < enabledComponents.length - 2) {
              final next1 = enabledComponents[i + 1];
              final next2 = enabledComponents[i + 2];
              
              // Skip if either next card is a heading
              if (!_isHeading(next1) && !_isHeading(next2)) {
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildItem(current),
                  ),
                );
                widgets.add(const SizedBox(height: 12));
                
                // Build row with next two cards
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildItem(next1, isInRow: next1.id == 'promo-app-3'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildItem(next2, isInRow: next2.id == 'promo-app-3'),
                        ),
                      ],
                    ),
                  ),
                );
                widgets.add(const SizedBox(height: 12));
                i += 3;
                continue;
              }
            }

            if (i < enabledComponents.length - 1) {
              final next = enabledComponents[i + 1];
              if (_isRowPair(current, next)) {
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildItem(current)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildItem(next)),
                      ],
                    ),
                  ),
                );
                widgets.add(const SizedBox(height: 16));
                i += 2;
                continue;
              }
            }

            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildItem(current),
              ),
            );

            widgets.add(const SizedBox(height: 12));
            i++;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          );
        }

        // While loading google layout or if it fails, show minimal layout
        return _buildMinimalGoogleLayout();
      },
    );
  }

  Widget _buildMinimalGoogleLayout() {
    // Minimal google layout fallback - just essential components
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const GemeeJackpotCard(),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const AdjoeCard(),
        ),
      ],
    );
  }
}
