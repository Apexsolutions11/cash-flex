import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../pages/general_quiz_page.dart';
import '../../utils/helper/jackpot_check_helper.dart';

class GeneralQuizCard extends StatelessWidget {
  const GeneralQuizCard({super.key});

  Future<void> _navigateToQuiz(BuildContext context) async {
    final canProceed = await JackpotCheckHelper.checkAndShowDialogIfNeeded(
      context,
    );
    if (!canProceed) return;

    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const GeneralQuizPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      child: GestureDetector(
        onTap: () => _navigateToQuiz(context),
        child: Container(
          height: 170,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient2,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            boxShadow: AppTheme.cardShadowSmall,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Star rating bar at top left (pill-shaped)
              Positioned(
                top: 8,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Icon(
                            TablerIcons.star,
                            size: 12,
                            color: index < 4
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Coin icon at top right
              Positioned(
                top: 8,
                right: 8,
                child: Image.asset(
                  'assets/images/coin.png',
                  width: 20,
                  height: 20,
                ),
              ),
              // Title text on top left, below stars
              Positioned(
                top: 40,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'General Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              // Brain icon at bottom right - flush with corner
              Positioned(
                bottom: -8,
                right: -8,
                child: Icon(
                  TablerIcons.brain,
                  size: 120,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
