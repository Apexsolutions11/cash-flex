import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/follow_us_model.dart';
import '../components/follow_earn_bottom_sheet.dart';
import '../utils/constant/constant.dart';
import '../providers/user_provider.dart';

class FollowAndEarnPage extends ConsumerWidget {
  const FollowAndEarnPage({super.key});

  void _showBottomSheet(
    BuildContext context, {
    required String url,
    required String socialName,
    required int coins,
    required int minBackgroundTime,
    required String taskId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FollowEarnBottomSheet(
        url: url,
        socialName: socialName,
        coins: coins,
        minBackgroundTime: minBackgroundTime,
        taskId: taskId,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'instagram':
        return LucideIcons.instagram;
      case 'facebook':
        return LucideIcons.facebook;
      case 'twitter':
        return LucideIcons.twitter;
      case 'youtube':
        return LucideIcons.youtube;
      case 'telegram':
        return LucideIcons.send;
      default:
        return LucideIcons.link;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'telegram':
        return const Color(0xFF0088CC);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow & Earn'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          final userCountry = user?.country;
          final userState = user?.regionName;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('socials')
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No social links available',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              // Filter socials based on user's country and state
              final allSocials = snapshot.data!.docs
                  .map(
                    (doc) => Social.fromDocument(
                      doc as DocumentSnapshot<Map<String, dynamic>>,
                    ),
                  )
                  .toList();

              final socials = allSocials
                  .where(
                    (social) => social.isAvailableFor(userCountry, userState),
                  )
                  .toList();

              if (socials.isEmpty) {
                return const Center(
                  child: Text(
                    'No social links available for your location',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: socials.length,
                itemBuilder: (context, index) {
                  final social = socials[index];
                  final icon = _getIconForType(social.type);
                  final color = _getColorForType(social.type);
                  final int effectiveCoins = followTaskDefaultCoins > 0
                      ? followTaskDefaultCoins
                      : social.coins;
                  final int effectiveMinTime = followTaskMinBackgroundTime > 0
                      ? followTaskMinBackgroundTime
                      : social.minBackgroundTime;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      title: Text(
                        social.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const SizedBox(height: 4),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/coin.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$effectiveCoins',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showBottomSheet(
                              context,
                              url: social.link,
                              socialName: social.name,
                              coins: effectiveCoins,
                              minBackgroundTime: effectiveMinTime,
                              taskId: social.id,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Follow'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading user data: $error')),
      ),
    );
  }
}
