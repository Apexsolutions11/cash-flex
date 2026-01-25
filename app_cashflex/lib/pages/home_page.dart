import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../components/home/home_wallet_card.dart';
import '../components/common/app_badge.dart';
import '../components/home/dynamic_home_content.dart';
import '../components/home/external_app_1_card.dart';
import '../components/home/external_app_2_card.dart';
import '../pages/follow_and_earn_page.dart';
import '../utils/constant/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/layout_provider.dart';
import '../services/layout_service.dart';
import '../services/jackpot_service.dart';
import '../utils/navigation/bottom_nav_controller.dart';
import '../utils/helper/toast_manager.dart';
import '../theme/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _reminderTimer;
  final Random _random = Random();
  int? _previousBalance;
  bool _isInitialLoad = true;
  bool _listenerSetup = false;
  int _toastCount = 0; // Track number of toasts shown on home screen

  @override
  void initState() {
    super.initState();
    _startReminderTimer();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _startReminderTimer() {
    // Cancel any existing timer
    _reminderTimer?.cancel();

    // Async check against Firestore, then schedule reminders only if needed
    _scheduleReminderIfNeeded();
  }

  Future<void> _scheduleReminderIfNeeded() async {
    // Check layout type - don't show geemee reminder if Google layout is applied
    try {
      final container = ProviderScope.containerOf(context);
      final layoutType = container.read(layoutTypeProvider);
      if (layoutType == 'google') {
        return;
      }
    } catch (_) {
      // On any error reading layout from provider, fall back to normal reminder logic
    }

    // Check if user has already played today - if so, don't show reminders
    final hasPlayed = await JackpotService.hasPlayedJackpotToday(
      userId: AuthService.currentUser?.uid,
    );
    if (hasPlayed || AuthService.currentUser?.uid == null) {
      return;
    }

    // Random interval between 4.5 to 5.5 minutes (270-330 seconds)
    final randomSeconds = 270 + _random.nextInt(61); // 270-330 seconds

    _reminderTimer = Timer(Duration(seconds: randomSeconds), () async {
      if (!mounted) return;

      // Check layout type again before showing reminder
      try {
        final container = ProviderScope.containerOf(context);
        final layoutType = container.read(layoutTypeProvider);
        if (layoutType == 'google') {
          return;
        }
      } catch (_) {
        // On any error reading layout from provider, fall back to normal reminder logic
      }

      final playedNow = await JackpotService.hasPlayedJackpotToday(
        userId: AuthService.currentUser?.uid,
      );
      if (!playedNow) {
        _showGemeeJackpotReminder();
        // Restart timer for next reminder
        _startReminderTimer();
      }
    });
  }

  Uri? _normalizeHowToEarnUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // If admin provides just the 11-char YouTube video ID.
    final idOnly = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idOnly.hasMatch(trimmed)) {
      return Uri.parse('https://www.youtube.com/watch?v=$trimmed');
    }

    // If no scheme, assume https.
    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }

  void _showGemeeJackpotReminder() {
    if (!mounted) return;

    final reminders = [
      "🎰 Don't forget to play the Gemee Jackpot today! It's required to redeem your coins.",
      "💰 Play the Gemee Jackpot now to unlock coin redemption!",
      "🎁 Remember to visit the Gemee Jackpot card - it's required for redeeming!",
      "⭐ Play Gemee Jackpot today to continue redeeming your rewards!",
      "🎯 Quick reminder: Play the Gemee Jackpot to enable coin redemption!",
    ];

    final randomReminder = reminders[_random.nextInt(reminders.length)];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            boxShadow: AppTheme.cardShadowMedium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF14B8A6),
                      Color(0xFF10B981),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        TablerIcons.bell,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Reminder',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      randomReminder,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              'Later',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Ink(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF14B8A6),
                                    Color(0xFF10B981),
                                  ],
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Got it',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Profile and Rate Us
              Padding(
                padding: AppTheme.paddingMedium,
                child: Row(
                  children: [
                    // Profile Picture
                    userAsync.when(
                      data: (userData) {
                        final hasPhoto =
                            userData?.photo != null &&
                            (userData!.photo!.isNotEmpty);

                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF14B8A6),
                                Color(0xFF10B981),
                              ],
                            ),
                            image: hasPhoto
                                ? DecorationImage(
                                    image: NetworkImage(userData.photo!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: !hasPhoto
                              ? const Icon(
                                  TablerIcons.bolt,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        );
                      },
                      loading: () => Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF14B8A6),
                              Color(0xFF10B981),
                            ],
                          ),
                        ),
                        child: const Icon(
                          TablerIcons.user,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      error: (_, __) => Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF14B8A6),
                              Color(0xFF10B981),
                            ],
                          ),
                        ),
                        child: const Icon(
                          TablerIcons.user,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Username
                    Expanded(
                      child: userAsync.when(
                        data: (userData) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WELCOME',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              userData?.name?.toUpperCase() ??
                                  AuthService.currentUser?.displayName
                                      ?.toUpperCase() ??
                                  'USER',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(
                          height: 16,
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, __) => Text(
                          'USER',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                  // TOP ROW - Featured Games: Scratch & Earn + Fruit Match
                  // These are fixed position but respect admin enable/disable settings
                  Consumer(
                    builder: (context, ref, child) {
                      final layoutAsync = ref.watch(layoutConfigProvider);
                      return layoutAsync.when(
                        data: (layoutConfig) {
                          final showApp1 = LayoutService.shouldShowHomepageComponent(
                            'promo-app-1',
                            layoutConfig,
                          );
                          final showApp2 = LayoutService.shouldShowHomepageComponent(
                            'promo-app-2',
                            layoutConfig,
                          );

                          // If both disabled, don't show row
                          if (!showApp1 && !showApp2) {
                            return const SizedBox.shrink();
                          }

                          // Show row with enabled apps
                          return Padding(
                            padding: AppTheme.paddingHorizontalMedium,
                            child: Row(
                              children: [
                                if (showApp1)
                                  Expanded(
                                    child: ExternalApp1Card(isFeatured: true, height: 140),
                                  ),
                                if (showApp1 && showApp2)
                                  SizedBox(width: AppTheme.spacingMediumSmall),
                                if (showApp2)
                                  Expanded(
                                    child: ExternalApp2Card(isFeatured: true, height: 140),
                                  ),
                              ],
                            ),
                          );
                        },
                        loading: () => Padding(
                          padding: AppTheme.paddingHorizontalMedium,
                          child: Row(
                            children: [
                              Expanded(
                                child: ExternalApp1Card(isFeatured: true, height: 140),
                              ),
                              SizedBox(width: AppTheme.spacingMediumSmall),
                              Expanded(
                                child: ExternalApp2Card(isFeatured: true, height: 140),
                              ),
                            ],
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),

              SizedBox(height: AppTheme.spacingLarge),

              // SECOND ROW - Wallet + Quick Actions
              Padding(
                padding: AppTheme.paddingHorizontalMedium,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT SIDE - Wallet Card (50% width)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          // Setup balance listener only once
                          if (!_listenerSetup) {
                            _listenerSetup = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ref.listen(currentUserProvider, (previous, next) {
                                next.whenData((userData) {
                                  final currentBalance = userData?.balance ?? 0;

                                  // Check for balance increase and show toast (max 2 toasts)
                                  if (!_isInitialLoad && _previousBalance != null) {
                                    if (currentBalance > _previousBalance! &&
                                        _toastCount < 2) {
                                      final coinsEarned =
                                          currentBalance - _previousBalance!;
                                      ToastManager.success(
                                        '🎉 You earned $coinsEarned coins!',
                                      );
                                      _toastCount++;
                                    }
                                  }

                                  // Update previous balance
                                  _previousBalance = currentBalance;
                                  _isInitialLoad = false;
                                });
                              });
                            });
                          }

                          return userAsync.when(
                            data: (userData) => HomeWalletCard(
                              balance: userData?.balance ?? 0,
                              onTap: () =>
                                  BottomNavScope.maybeOf(context)?.goToWallet(),
                            ),
                            loading: () => HomeWalletCard(
                              balance: 0,
                              onTap: () =>
                                  BottomNavScope.maybeOf(context)?.goToWallet(),
                            ),
                            error: (_, __) => HomeWalletCard(
                              balance: 0,
                              onTap: () =>
                                  BottomNavScope.maybeOf(context)?.goToWallet(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingMediumSmall),
                    // RIGHT SIDE - Watch & Earn + Follow & Earn (stacked vertically)
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final layoutAsync = ref.watch(layoutConfigProvider);
                          return layoutAsync.when(
                            data: (layoutConfig) {
                              final shouldShow =
                                  LayoutService.shouldShowHomepageComponent(
                                    'how-to-earn-follow-us',
                                    layoutConfig,
                                  );
                              if (!shouldShow) {
                                return const SizedBox.shrink();
                              }
                              final cfg = layoutConfig == null
                                  ? null
                                  : LayoutService.findComponentConfig(
                                      'how-to-earn-follow-us',
                                      layoutConfig.pageLayout.homepage,
                                    );
                              final hasBadge =
                                  cfg != null &&
                                  ((cfg.badgeText?.trim().isNotEmpty ?? false) ||
                                      (cfg.badgeVariant?.trim().isNotEmpty ?? false));

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    children: [
                                      // Watch & Earn button
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.accentGradient,
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                                          boxShadow: AppTheme.cardShadowSmall,
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final raw = howToEarnYoutubeUrl.trim();
                                            final uri = _normalizeHowToEarnUri(raw);
                                            if (uri == null) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('How to earn link is not configured.')),
                                                );
                                              }
                                              return;
                                            }
                                            final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            if (!ok && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Could not open the How to earn link.')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                                          label: const Text(
                                            'Watch & Earn',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: AppTheme.spacingSmall),
                                      // Follow & Earn button
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.cardGradient2,
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                                          boxShadow: AppTheme.cardShadowSmall,
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => const FollowAndEarnPage(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
                                          label: const Text(
                                            'Follow & Earn',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasBadge)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IgnorePointer(
                                        child: AppBadge(
                                          text: cfg.badgeText,
                                          variant: cfg.badgeVariant,
                                          small: true,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                                  ),
                                ),
                                SizedBox(height: AppTheme.spacingSmall),
                                Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.cardGradient2,
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                                  ),
                                ),
                              ],
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingLarge),

              // Dynamic Content based on Layout Configuration
              const DynamicHomeContent(),

              SizedBox(height: AppTheme.spacingXXL * 2), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
