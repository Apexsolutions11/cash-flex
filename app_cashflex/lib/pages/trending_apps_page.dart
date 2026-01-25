import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/more_apps_model.dart';
import '../components/more_apps_bottom_sheet.dart';
import '../utils/constant/constant.dart';

class TrendingAppsPage extends StatelessWidget {
  const TrendingAppsPage({super.key});

  void _showBottomSheet(
    BuildContext context, {
    required String url,
    required String appName,
    required int coins,
    required int minBackgroundTime,
    required String appId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoreAppsBottomSheet(
        url: url,
        appName: appName,
        coins: coins,
        minBackgroundTime: minBackgroundTime,
        appId: appId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Apps'),
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('moreApps')
            .where('active', isEqualTo: true)
            .orderBy('rank')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No trending apps available',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final apps = snapshot.data!.docs
              .map(
                (doc) => MoreAppsDataModel.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              if (!app.active) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // App Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          image: app.imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(app.imageUrl),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                )
                              : null,
                        ),
                        child: app.imageUrl.isEmpty
                            ? const Icon(
                                TablerIcons.device_mobile,
                                size: 32,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // App Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              app.appName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/coin.png',
                                  width: 18,
                                  height: 18,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${(moreAppsDefaultCoins > 0 ? moreAppsDefaultCoins : app.coins)} Coins',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Install Button
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBottomSheet(
                            context,
                            url: app.clickUrl,
                            appName: app.appName,
                            coins: moreAppsDefaultCoins > 0
                                ? moreAppsDefaultCoins
                                : app.coins,
                            minBackgroundTime: moreAppsMinBackgroundTime > 0
                                ? moreAppsMinBackgroundTime
                                : app.minBackgroundTime,
                            appId: app.id,
                          ),
                          icon: const Icon(TablerIcons.download, size: 16),
                          label: const Text('Install'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
