import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'home_page.dart';
import 'wallet_page.dart';
import 'leaderboard_page.dart';
import 'invite_page.dart';
import 'profile_page.dart';
import '../utils/navigation/bottom_nav_controller.dart';
import '../theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late final BottomNavController _controller = BottomNavController();

  static const List<Widget> _pages = [
    HomePage(),
    InvitePage(),
    LeaderboardPage(),
    WalletPage(),
    ProfilePage(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavScope(
      controller: _controller,
      child: ValueListenableBuilder<int>(
        valueListenable: _controller,
        builder: (context, currentIndex, _) {
          return Scaffold(
            body: IndexedStack(index: currentIndex, children: _pages),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(TablerIcons.home, 'Home', 0, currentIndex),
                      _buildNavItem(
                        TablerIcons.user_plus,
                        'Invite',
                        1,
                        currentIndex,
                      ),
                      _buildNavItem(
                        TablerIcons.trophy,
                        'Rank',
                        2,
                        currentIndex,
                      ),
                      _buildNavItem(
                        TablerIcons.wallet,
                        'Wallet',
                        3,
                        currentIndex,
                      ),
                      _buildNavItem(
                        TablerIcons.user,
                        'Profile',
                        4,
                        currentIndex,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;
    // Active color: Teal (Primary), Inactive: Slate
    final activeColor = AppTheme.primaryTeal;
    final inactiveColor = AppTheme.textTertiary;

    return GestureDetector(
      onTap: () => _controller.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : inactiveColor,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
