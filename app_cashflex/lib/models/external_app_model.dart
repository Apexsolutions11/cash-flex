import 'package:cloud_firestore/cloud_firestore.dart';

class ExternalAppModel {
  final bool? enabled;
  final String? photo;
  final String? title;
  final String? description;
  final double? stars;
  final int? coins;
  final String? buttonText;
  final String? playStoreUrl;
  final List<String>? tasks;
  final int? minimumBackgroundTime; // in seconds
  final String? badgeText;
  final String? badgeVariant;

  ExternalAppModel({
    this.enabled,
    this.photo,
    this.title,
    this.description,
    this.stars,
    this.coins,
    this.buttonText,
    this.playStoreUrl,
    this.tasks,
    this.minimumBackgroundTime,
    this.badgeText,
    this.badgeVariant,
  });

  factory ExternalAppModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return ExternalAppModel();
    }

    List<String>? tasksList;
    if (data['tasks'] != null && data['tasks'] is List) {
      tasksList = (data['tasks'] as List).cast<String>();
    }

    return ExternalAppModel(
      enabled: data['enabled'] ?? true,
      photo: data['photo'],
      title: data['title'],
      description: data['description'],
      stars: (data['stars'] as num?)?.toDouble(),
      coins: data['coins'],
      buttonText: data['buttonText'],
      playStoreUrl: data['playStoreUrl'],
      tasks: tasksList,
      minimumBackgroundTime: data['minimumBackgroundTime'] as int?,
      badgeText: (data['badgeText'] as String?)?.trim(),
      badgeVariant: (data['badgeVariant'] as String?)?.trim(),
    );
  }

  bool get isEmpty => title == null || title!.isEmpty || enabled == false;
}

