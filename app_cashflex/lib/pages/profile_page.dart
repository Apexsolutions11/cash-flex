import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_data_model.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../utils/helper/toast_manager.dart';
import '../theme/app_theme.dart';

import 'auth_page.dart';
import 'edit_profile_page.dart';
import 'wallet_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final UserDataModel? userData = userAsync.asData?.value;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMediumLarge, vertical: AppTheme.spacingMediumLarge),
            child: Column(
              children: [
                _buildHeader(context, userData),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildProfileCard(context, userData),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildMenu(context, ref, userData),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildLogoutButton(context),
                const SizedBox(height: AppTheme.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserDataModel? userData) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                border: Border.all(
                  color: theme.colorScheme.surfaceContainerHighest,
                  width: 2,
                ),
                image: userData?.photo != null && userData!.photo!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(userData.photo!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: userData?.photo == null || userData!.photo!.isEmpty
                  ? Icon(
                      TablerIcons.user,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                (userData?.name ?? 'User').toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserDataModel? userData) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: AppTheme.paddingLarge,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
        boxShadow: AppTheme.cardShadowMedium,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.2),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                image: userData?.photo != null && userData!.photo!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(userData.photo!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: userData?.photo == null || userData!.photo!.isEmpty
                  ? Icon(
                      TablerIcons.user,
                      color: Colors.white,
                      size: 40,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMediumSmall),
          Text(
            userData?.name ?? 'Guest User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            userData?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBox(
                userData?.balance?.toString() ?? '0',
                'Coins',
                icon: TablerIcons.coin,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, {IconData? icon}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMediumSmall, horizontal: AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: AppTheme.spacingXS),
          ],
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(
    BuildContext context,
    WidgetRef ref,
    UserDataModel? userData,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
          width: 1,
        ),
        boxShadow: AppTheme.cardShadowSmall,
      ),
      child: Column(
        children: [
          _buildMenuItem(context,
            'Account Settings',
            TablerIcons.settings,
            AppTheme.primaryTeal,
            () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(userData: userData),
                ),
              );
              if (result == true) {
                ref.invalidate(currentUserProvider);
              }
            },
            showDivider: true,
          ),
          _buildMenuItem(context,
            'My Wallet',
            TablerIcons.wallet,
            AppTheme.accentEmerald,
            () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletPage()));
            },
            showDivider: true,
          ),
          _buildMenuItem(context,
            'Privacy & Security',
            TablerIcons.shield_check,
            AppTheme.secondaryCyan,
            () async {
              final url =
                  "https://sites.google.com/view/cashflexprivacypolicy/home"
                      .trim();
              if (url.isNotEmpty) {
                await launchUrl(
                  Uri.parse(url.startsWith('http') ? url : 'https://$url'),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                ToastManager.warning('Privacy policy not available');
              }
            },
            showDivider: true,
          ),
          _buildMenuItem(context,
            'Help & Support',
            TablerIcons.help,
            AppTheme.warningOrange,
            () async {
              final uri = Uri.tryParse('mailto:Support@cashflex.com');
              if (uri != null) {
                await launchUrl(uri);
              } else {
                ToastManager.error(msg: 'Contact info missing');
              }
            },
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool showDivider = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: AppTheme.paddingMedium,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall + 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  TablerIcons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () async {
          try {
            await AuthService.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            }
          } catch (e) {
            ToastManager.error(msg: 'Logout failed');
          }
        },
        child: Container(
          padding: AppTheme.paddingVerticalMedium,
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            border: Border.all(
              color: theme.colorScheme.error.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                TablerIcons.logout,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
