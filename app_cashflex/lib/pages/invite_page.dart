import 'package:flutter/material.dart';
import 'package:cashflex/utils/constant/constant.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/user_data_model.dart';
import '../providers/user_provider.dart';
import '../providers/layout_provider.dart';
import '../services/referral_service.dart';
import '../services/layout_service.dart';
import '../utils/helper/helper.dart';
import '../utils/helper/toast_manager.dart';
import '../theme/app_theme.dart';

class InvitePage extends ConsumerWidget {
  const InvitePage({super.key});

  Future<String> _buildShareableReferralLink(String referralCode) async {
    final code = referralCode.trim();
    if (code.isEmpty) return '';

    // Build deep link URL using the server URL from constants
    // Extract base URL from backendApiUrl (remove /api suffix)
    String serverUrl = AppConstant.backendApiUrl;
    if (serverUrl.endsWith('/api')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 4);
    }
    // Ensure it's HTTPS
    if (serverUrl.startsWith('http://')) {
      serverUrl = serverUrl.replaceFirst('http://', 'https://');
    }
    if (!serverUrl.startsWith('https://')) {
      serverUrl = 'https://$serverUrl';
    }
    
    // Build deep link: https://cashflex.adzrewards.com/r/ABC123
    final deepLinkUrl = '$serverUrl/r/$code';
    return deepLinkUrl;
  }

  Future<String> _buildPlayStoreReferralLink(String referralCode) async {
    final code = referralCode.trim();
    if (code.isEmpty) return '';

    // Build Play Store link as fallback
    final packageInfo = await PackageInfo.fromPlatform();
    final pkg = packageInfo.packageName;
    final base = 'https://play.google.com/store/apps/details?id=$pkg';

    final encodedReferrer = Uri.encodeComponent('referralCode=$code');
    return '$base&referrer=$encodedReferrer';
  }

  Future<void> _copyReferralLink(UserDataModel? userData) async {
    final code = (userData?.referralCode ?? '').trim();
    if (code.isEmpty) {
      ToastManager.warning('Referral code is not available yet.');
      return;
    }
    // Copy the deep link URL
    final link = await _buildShareableReferralLink(code);
    if (link.isEmpty) {
      ToastManager.error(msg: 'Could not build referral link');
      return;
    }
    await copyData(link);
    ToastManager.success('Referral link copied to clipboard!');
  }

  Future<void> _shareReferralCode(
    BuildContext context,
    String method,
    UserDataModel? userData,
  ) async {
    final referralCode = (userData?.referralCode ?? '').trim();
    if (referralCode.isEmpty) {
      ToastManager.warning('Referral code is not available yet.');
      return;
    }

    String referralLink = '';
    String playStoreLink = '';
    try {
      referralLink = await _buildShareableReferralLink(referralCode);
      playStoreLink = await _buildPlayStoreReferralLink(referralCode);
    } catch (_) {
      // Fallback to the old builder if PackageInfo fails for any reason.
      referralLink = ReferralService.buildPlayStoreReferralLink(referralCode);
      playStoreLink = referralLink;
    }

    if (referralLink.trim().isEmpty) {
      ToastManager.error(msg: 'Could not build referral link');
      return;
    }

    final message =
        'Join ${AppConstant.appName} using my referral code: $referralCode\n\n'
        'Tap this link to download:\n$referralLink\n\n'
        'Or visit Play Store:\n$playStoreLink';

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? (box.localToGlobal(Offset.zero) & box.size)
          : null;

      // `Share.share` already routes to the appropriate apps; method kept for future customization.
      await Share.share(
        message,
        subject: 'Join ${AppConstant.appName}',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      ToastManager.error(msg: 'Unable to open share sheet. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final layoutAsync = ref.watch(layoutConfigProvider);

    final bool showShareVia = layoutAsync.maybeWhen(
      data: (layoutConfig) => LayoutService.shouldShowInviteComponent(
        'invite-share-via',
        layoutConfig,
      ),
      orElse: () => true,
    );

    final bool showHowItWorks = layoutAsync.maybeWhen(
      data: (layoutConfig) => LayoutService.shouldShowInviteComponent(
        'invite-how-it-works',
        layoutConfig,
      ),
      orElse: () => true,
    );

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: AppTheme.paddingLarge,
              child: Row(
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
                      image:
                          userAsync.asData?.value?.photo != null &&
                              userAsync.asData!.value!.photo!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                userAsync.asData!.value!.photo!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        userAsync.asData?.value?.photo == null ||
                            userAsync.asData!.value!.photo!.isEmpty
                        ? Icon(
                            TablerIcons.user,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
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
                          (userAsync.asData?.value?.name ?? 'User')
                              .toUpperCase(),
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
              ),
            ),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(currentUserProvider);
                },
                child: SingleChildScrollView(
                  child: Padding(
                    padding: AppTheme.paddingMedium,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invite Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: AppTheme.paddingLarge,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  TablerIcons.users,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMediumLarge),
                              Text(
                                'Invite Friends & Earn Rewards',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.spacingMediumSmall),
                              Text(
                                'Get $referralSignupBonusCoins coins for each friend you invite',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingLarge),

                        // Referral Stats (moved up)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradient1,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                            boxShadow: AppTheme.cardShadowMedium,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingSmall + 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      TablerIcons.chart_bar,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Your Referral Stats',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingLarge),
                              userAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                error: (_, __) => Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(context,
                                        'Total Invites',
                                        '0',
                                        TablerIcons.users,
                                        Colors.white,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 60,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(context,
                                        'Earned',
                                        '0',
                                        'assets/images/coin.png',
                                        Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                data: (userData) => Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(context,
                                        'Total Invites',
                                        '${userData?.referralCount ?? 0}',
                                        TablerIcons.users,
                                        Colors.white,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 60,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(context,
                                        'Earned',
                                        (userData?.referralEarning ?? 0)
                                            .addComma(),
                                        'assets/images/coin.png',
                                        Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingLarge),

                        // Referral Code (moved down, now shows full link)
                        Text(
                          'Your Referral Link',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        userAsync.when(
                          loading: () => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                              border: Border.all(
                                color: AppTheme.infoBlue.withOpacity(0.3),
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (_, __) => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                              border: Border.all(
                                color: AppTheme.errorRed.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Failed to load referral link',
                              style: TextStyle(color: AppTheme.errorRed),
                            ),
                          ),
                          data: (userData) => FutureBuilder<String>(
                            future: _buildShareableReferralLink(
                              userData?.referralCode ?? '',
                            ),
                            builder: (context, snapshot) {
                              final code = (userData?.referralCode ?? '')
                                  .trim();
                              final link = snapshot.data ?? '';
                              final displayLink = link.isEmpty
                                  ? (code.isEmpty
                                        ? 'Referral code not available'
                                        : 'Loading link...')
                                  : link;

                              return Container(
                                padding: AppTheme.paddingLarge,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                                  border: Border.all(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    width: 1.5,
                                  ),
                                  boxShadow: AppTheme.cardShadowSmall,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppTheme.spacingSmall + 2),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.secondaryCyan,
                                                AppTheme.primaryTeal,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.borderRadiusSmall,
                                            ),
                                          ),
                                          child: const Icon(
                                            TablerIcons.link,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (code.isNotEmpty) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.secondaryCyan
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppTheme.borderRadiusSmall,
                                                        ),
                                                    border: Border.all(
                                                      color: AppTheme.secondaryCyan.withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    code,
                                                    style: TextStyle(
                                                      color: AppTheme.secondaryCyan,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                                                  border: Border.all(
                                                    color: theme.colorScheme.surfaceContainerHighest,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        displayLink,
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          color: link.isEmpty
                                                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                                                              : theme.colorScheme.onSurface,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily:
                                                              'monospace',
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: code.isNotEmpty &&
                                                    link.isNotEmpty &&
                                                    snapshot.connectionState ==
                                                        ConnectionState.done
                                                ? LinearGradient(
                                                    colors: [
                                                      AppTheme.secondaryCyan,
                                                      AppTheme.primaryTeal,
                                                    ],
                                                  )
                                                : null,
                                            color: code.isNotEmpty &&
                                                    link.isNotEmpty &&
                                                    snapshot.connectionState ==
                                                        ConnectionState.done
                                                ? null
                                                : theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                                          ),
                                          child: IconButton(
                                            onPressed:
                                                code.isNotEmpty &&
                                                    link.isNotEmpty &&
                                                    snapshot.connectionState ==
                                                        ConnectionState.done
                                                ? () =>
                                                      _copyReferralLink(userData)
                                                : null,
                                            icon: Icon(
                                              TablerIcons.copy,
                                              color: code.isNotEmpty &&
                                                      link.isNotEmpty &&
                                                      snapshot.connectionState ==
                                                          ConnectionState.done
                                                  ? Colors.white
                                                  : theme.colorScheme.onSurface.withOpacity(0.4),
                                            ),
                                            style: IconButton.styleFrom(
                                              padding: const EdgeInsets.all(AppTheme.spacingMediumSmall),
                                            ),
                                            tooltip: 'Copy link',
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (code.isNotEmpty && link.isNotEmpty) ...[
                                      const SizedBox(height: AppTheme.spacingMediumSmall),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryCyan.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.borderRadiusSmall,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.secondaryCyan.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              TablerIcons.info_circle,
                                              size: 16,
                                              color: AppTheme.secondaryCyan,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Share this link with your friends to earn rewards',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.secondaryCyan,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingLarge),

                        // Share Options
                        if (showShareVia) ...[
                          Text(
                            'Share Via',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              userAsync.maybeWhen(
                                data: (userData) => Expanded(
                                  child: _buildShareOption(context,
                                    'WhatsApp',
                                    TablerIcons.message_circle,
                                    Colors.green,
                                    () => _shareReferralCode(
                                      context,
                                      'whatsapp',
                                      userData,
                                    ),
                                  ),
                                ),
                                orElse: () =>
                                    const Expanded(child: SizedBox.shrink()),
                              ),
                              const SizedBox(width: 12),
                              userAsync.maybeWhen(
                                data: (userData) => Expanded(
                                  child: _buildShareOption(context,
                                    'Telegram',
                                    TablerIcons.send,
                                    Colors.blue,
                                    () => _shareReferralCode(
                                      context,
                                      'telegram',
                                      userData,
                                    ),
                                  ),
                                ),
                                orElse: () =>
                                    const Expanded(child: SizedBox.shrink()),
                              ),
                              const SizedBox(width: 12),
                              userAsync.maybeWhen(
                                data: (userData) => Expanded(
                                  child: _buildShareOption(context,
                                    'More',
                                    TablerIcons.share,
                                    Colors.grey,
                                    () => _shareReferralCode(
                                      context,
                                      'more',
                                      userData,
                                    ),
                                  ),
                                ),
                                orElse: () =>
                                    const Expanded(child: SizedBox.shrink()),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: AppTheme.spacingLarge),

                        // How It Works
                        if (showHowItWorks) ...[
                          Text(
                            'How It Works',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildHowItWorksItem(context,
                            1,
                            'Share your referral code',
                            'Send your unique code to friends',
                            TablerIcons.share,
                          ),
                          _buildHowItWorksItem(context,
                            2,
                            'Friend signs up',
                            'They use your code when registering',
                            TablerIcons.user_plus,
                          ),
                          _buildHowItWorksItem(context,
                            3,
                            'You both earn',
                            'Get $referralSignupBonusCoins coins when they complete first task',
                            TablerIcons.gift,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        child: Ink(
          padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, dynamic icon, Color color) {
    final theme = Theme.of(context);
    final isWhite = color == Colors.white;
    return Column(
      children: [
        icon is String
            ? Image.asset(
                icon,
                width: 28,
                height: 28,
                color: isWhite ? Colors.white : null,
              )
            : Icon(icon as IconData, color: color, size: 28),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: isWhite ? Colors.white : theme.colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isWhite
                ? Colors.white.withOpacity(0.9)
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksItem(
    BuildContext context,
    int step,
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
          width: 1,
        ),
        boxShadow: AppTheme.cardShadowSmall,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryCyan.withOpacity(0.2),
                  AppTheme.primaryTeal.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.secondaryCyan.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: AppTheme.secondaryCyan,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppTheme.secondaryCyan, size: 24),
        ],
      ),
    );
  }
}
