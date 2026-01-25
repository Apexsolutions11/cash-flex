import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewTask {
  final String link;
  final String id;
  final String img;
  final String description;
  final bool enabled;
  final int coins;
  final int minBackgroundTime;

  ReviewTask({
    required this.link,
    required this.id,
    required this.img,
    required this.description,
    required this.enabled,
    required this.coins,
    required this.minBackgroundTime,
  });

  factory ReviewTask.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> data,
  ) =>
      ReviewTask(
        link: (data.data()['link'] as String?) ?? '',
        img: (data.data()['img'] as String?) ?? '',
        id: data.id,
        description: (data.data()['description'] as String?) ?? '',
        enabled: (data.data()['enabled'] as bool?) ?? true,
        coins: (data.data()['coins'] as num?)?.toInt() ?? 150,
        minBackgroundTime: (data.data()['minBackgroundTime'] as num?)?.toInt() ?? 60,
      );
}