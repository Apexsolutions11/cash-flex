import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../utils/constant/constant.dart';
import '../../theme/app_theme.dart';

class CoinsRateCard extends StatelessWidget {
  final String layoutType;

  const CoinsRateCard({super.key, required this.layoutType});

  String _getCurrencySymbol(String layoutType) {
    if (layoutType == 'normal') {
      return '₹';
    } else {
      return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNormal = layoutType == 'normal';
    final factor = isNormal ? indiaCoinCurFactor : foreignCoinCurFactor;

    if (factor <= 0) {
      return const SizedBox.shrink();
    }

    final currencySymbol = _getCurrencySymbol(layoutType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentEmerald.withOpacity(0.15),
            AppTheme.accentEmeraldDark.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: AppTheme.accentEmerald.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentEmerald.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Icon(
              TablerIcons.trending_up,
              color: AppTheme.accentEmerald,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversion Rate',
                  style: TextStyle(
                    color: AppTheme.accentEmerald.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: '$factor',
                        style: TextStyle(
                          color: AppTheme.accentEmerald,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' coins = ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      TextSpan(
                        text: '$currencySymbol 1',
                        style: TextStyle(
                          color: AppTheme.accentEmerald,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
