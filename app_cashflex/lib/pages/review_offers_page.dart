import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_task_model.dart';
import '../components/review_earn_bottom_sheet.dart';
import '../utils/constant/constant.dart';

class ReviewOffersPage extends StatelessWidget {
  const ReviewOffersPage({super.key});

  void _showBottomSheet(
    BuildContext context, {
    required String url,
    required String appName,
    required int coins,
    required int minBackgroundTime,
    required String taskId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewEarnBottomSheet(
        url: url,
        appName: appName,
        coins: coins,
        minBackgroundTime: minBackgroundTime,
        taskId: taskId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Offers'),
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviewTask')
            .where('enabled', isEqualTo: true)
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
                'No review tasks available',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final reviews = snapshot.data!.docs
              .map(
                (doc) => ReviewTask.fromSnapshot(
                  doc as QueryDocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // App Icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              image: review.img.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(review.img),
                                      fit: BoxFit.cover,
                                      onError: (_, __) {},
                                    )
                                  : null,
                            ),
                            child: review.img.isEmpty
                                ? const Icon(
                                    TablerIcons.device_mobile,
                                    size: 32,
                                    color: Colors.white70,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'App Review',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  review.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/coin.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reward: ${(reviewTaskDefaultCoins > 0 ? reviewTaskDefaultCoins : review.coins)} Coins',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _showBottomSheet(
                              context,
                              url: review.link,
                              appName: review.description,
                              coins: reviewTaskDefaultCoins > 0
                                  ? reviewTaskDefaultCoins
                                  : review.coins,
                              minBackgroundTime: reviewTaskMinBackgroundTime > 0
                                  ? reviewTaskMinBackgroundTime
                                  : review.minBackgroundTime,
                              taskId: review.id,
                            ),
                            icon: const Icon(TablerIcons.star, size: 18),
                            label: const Text('Review Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
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
