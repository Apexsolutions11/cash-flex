import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../pages/review_offers_page.dart';
import '../../utils/helper/jackpot_check_helper.dart';

class ReviewOffersCard extends StatelessWidget {
  const ReviewOffersCard({super.key});

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
            MaterialPageRoute(builder: (context) => const ReviewOffersPage()),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient1,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          boxShadow: AppTheme.cardShadowSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Offers',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Earn coins by reviewing apps',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/review.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
