import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';
import '../models/user_data_model.dart';
import '../theme/app_theme.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  int leaderboardTimeLeft = 0;

  @override
  void initState() {
    super.initState();
    _calculateLeaderboardTimeLeft();
  }

  void _calculateLeaderboardTimeLeft() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    leaderboardTimeLeft = tomorrow.millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<UserDataModel>>(
                stream: LeaderboardService.getLeaderboardStream(limit: 50),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    final errorMessage = error?.toString() ?? 'Unknown error occurred';
                    
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.alert_circle,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error Loading Leaderboard',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: AppTheme.paddingMedium,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Error Details:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    errorMessage,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Please try again later',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final leaderboardData = snapshot.data ?? [];
                  if (leaderboardData.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.trophy_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Rankings Yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to appear on the leaderboard!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Find current user's rank
                  final currentUserId = AuthService.currentUser?.uid;
                  // ignore: unused_local_variable
                  int userRank = 0;
                  // ignore: unused_local_variable
                  UserDataModel? currentUserData;

                  for (int i = 0; i < leaderboardData.length; i++) {
                    if (leaderboardData[i].userId == currentUserId) {
                      userRank = i + 1;
                      currentUserData = leaderboardData[i];
                      break;
                    }
                  }

                  final top3 = leaderboardData.take(3).toList();
                  final rest = leaderboardData.skip(3).toList();

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: _buildBanner(),
                        ),
                      ),

                      if (top3.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            child: _buildTop3Podium(top3),
                          ),
                        ),

                      // Section Header for Rankings
                      if (rest.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                                  ),
                                  child: Icon(
                                    TablerIcons.list_numbers,
                                    color: AppTheme.primaryTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'All Rankings',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Rankings List (Rank 4+)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final user = rest[index];
                            final rank = index + 4;
                            final isCurrentUser = user.userId == currentUserId;
                            return _buildRankItem(
                              rank,
                              user.name ?? 'Unknown',
                              user.coins ?? 0,
                              user.photo,
                              isCurrentUser,
                            );
                          }, childCount: rest.length),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: StreamBuilder<UserDataModel?>(
        stream: _getCurrentUserDataStream(),
        builder: (context, snapshot) {
          final userData = snapshot.data;
          return Row(
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
        },
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXL, horizontal: AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
        boxShadow: AppTheme.cardShadowMedium,
      ),
      child: Column(
        children: [
          Container(
            padding: AppTheme.paddingMedium,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.trophy,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMediumLarge),
          Text(
            'Leaderboard',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Podium(List<UserDataModel> top3) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 280, // Increased height to ensure rank 1 is visible
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none, // Allow overflow to show rank 1
          children: [
            // 2nd Place (Left) - rendered first so rank 1 appears on top
            if (top3.length > 1)
              Positioned(
                left: 0,
                bottom: 0,
                child: _buildPodiumItem(
                  top3[1],
                  2,
                  AppTheme.leaderboardPodium2Gradient,
                ),
              ),

            // 3rd Place (Right) - rendered second
            if (top3.length > 2)
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildPodiumItem(
                  top3[2],
                  3,
                  AppTheme.leaderboardPodium3Gradient,
                ),
              ),

            // 1st Place (Center & Higher) - rendered last so it's on top
            if (top3.isNotEmpty)
              Positioned(
                bottom: 50, // Lifted up to be clearly visible
                left: 0,
                right: 0,
                child: Center(
                  child: _buildPodiumItem(
                    top3[0],
                    1,
                    AppTheme.leaderboardPodium1Gradient,
                    isFirst: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(
    UserDataModel user,
    int rank,
    LinearGradient gradient, {
    bool isFirst = false,
  }) {
    // Container size variables
    final double cardWidth = isFirst ? 120 : 100;
    final theme = Theme.of(context);

    return Container(
      width: cardWidth,
      padding: EdgeInsets.symmetric(
        vertical: isFirst ? AppTheme.spacingMediumLarge : AppTheme.spacingMedium,
        horizontal: AppTheme.spacingMediumSmall,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: isFirst ? 2.5 : 2,
        ),
        boxShadow: AppTheme.cardShadowMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank Badge with medal icon
          Container(
            width: isFirst ? 36 : 32,
            height: isFirst ? 36 : 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isFirst ? 16 : 14,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMediumSmall),

          // Crown for 1st place
          if (isFirst) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall - 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TablerIcons.crown,
                color: Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Avatar
          Container(
            width: isFirst ? 56 : 48,
            height: isFirst ? 56 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: isFirst ? 3 : 2,
              ),
              image: user.photo != null && user.photo!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(user.photo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.photo == null || user.photo!.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Text(
                        (user.name?.isNotEmpty ?? false)
                            ? user.name![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isFirst ? 20 : 18,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),

          // Name
          Text(
            user.name?.split(' ').first ?? 'User',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isFirst ? 14 : 13,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Coins with better styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/coin.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${user.coins ?? 0}',
                  style: TextStyle(
                    fontSize: isFirst ? 13 : 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(
    int rank,
    String name,
    int coins,
    String? photoUrl,
    bool isCurrentUser,
  ) {
    final theme = Theme.of(context);
    final isTopRank = rank <= 10; // Highlight top 10 ranks
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.primaryTeal
              : isTopRank
                  ? AppTheme.primaryTeal.withOpacity(0.3)
                  : theme.colorScheme.surfaceContainerHighest,
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: isTopRank || isCurrentUser
            ? AppTheme.cardShadowSmall
            : [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Rank Number with improved design
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isTopRank || isCurrentUser
                  ? AppTheme.primaryGradient
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.onSurface.withOpacity(0.1),
                        theme.colorScheme.onSurface.withOpacity(0.15),
                      ],
                    ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              boxShadow: isTopRank || isCurrentUser
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                color: isTopRank || isCurrentUser
                    ? Colors.white
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),

          // Avatar with border
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: photoUrl == null || photoUrl.isEmpty
                  ? (isTopRank || isCurrentUser
                      ? AppTheme.primaryGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.onSurface.withOpacity(0.2),
                            theme.colorScheme.onSurface.withOpacity(0.3),
                          ],
                        ))
                  : null,
              border: Border.all(
                color: isCurrentUser
                    ? AppTheme.primaryTeal
                    : isTopRank
                        ? AppTheme.primaryTeal.withOpacity(0.4)
                        : theme.colorScheme.surfaceContainerHighest,
                width: isCurrentUser ? 2.5 : 2,
              ),
              image: photoUrl != null && photoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null || photoUrl.isEmpty
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: isTopRank || isCurrentUser
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rank #$rank',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Coins Pill with improved design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isTopRank || isCurrentUser
                  ? AppTheme.primaryGradient
                  : AppTheme.cardGradient2,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              boxShadow: AppTheme.cardShadowSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/coin.png',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF8E44AD), // Purple
      Color(0xFF2980B9), // Blue
      Color(0xFFE67E22), // Orange
      Color(0xFF27AE60), // Green
    ];
    return colors[index % colors.length];
  }

  Stream<UserDataModel?> _getCurrentUserDataStream() async* {
    while (true) {
      final userData = await AuthService.fetchUserDataModel();
      yield userData;
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
