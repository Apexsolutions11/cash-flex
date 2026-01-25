class MoreAppsDataModel {
  final String id;
  final int coins;
  final int minBackgroundTime;
  final String appName;
  final String clickUrl;
  final String imageUrl;
  final bool active;
  final String bundleId;
  final int rank;

  MoreAppsDataModel({
    required this.id,
    required this.coins,
    required this.minBackgroundTime,
    required this.appName,
    required this.clickUrl,
    required this.imageUrl,
    required this.active,
    required this.bundleId,
    required this.rank,
  });

  factory MoreAppsDataModel.fromJson(Map<String, dynamic> json) =>
      MoreAppsDataModel(
        id: (json['id'] as String?) ?? '',
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        minBackgroundTime: (json['minBackgroundTime'] as num?)?.toInt() ?? 120,
        appName: (json['appName'] as String?) ?? '',
        clickUrl: (json['clickUrl'] as String?) ?? '',
        imageUrl: (json['imageUrl'] as String?) ?? '',
        active: (json['active'] as bool?) ?? true,
        bundleId: (json['bundleId'] as String?) ?? '',
        rank: (json['rank'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coins': coins,
        'minBackgroundTime': minBackgroundTime,
        'appName': appName,
        'clickUrl': clickUrl,
        'imageUrl': imageUrl,
        'active': active,
        'bundleId': bundleId,
        'rank': rank,
      };
}