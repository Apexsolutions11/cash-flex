import 'package:flutter/material.dart';
import '../../pages/trending_apps_page.dart';
import '../../utils/helper/jackpot_check_helper.dart';
import '../../theme/app_theme.dart';

class TrendingAppsCard extends StatelessWidget {
  const TrendingAppsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final canProceed = await JackpotCheckHelper.checkAndShowDialogIfNeeded(
          context,
        );
        if (!canProceed) return;

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const TrendingAppsPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: AppTheme.cardShadowSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'More Apps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/coin.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Install & Win Rewards',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/trending_apps.png',
              width: 110,
              height: 99,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
