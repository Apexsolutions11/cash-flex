import 'package:cloud_firestore/cloud_firestore.dart';

class Social {
  final String id;
  final String tag;
  final String type;
  final String link;
  final String name;
  final bool active;
  final int coins;
  final int minBackgroundTime;
  final String? country; // Optional: restrict to specific country
  final String? state; // Optional: restrict to specific state/region

  Social({
    required this.id,
    required this.tag,
    required this.type,
    required this.link,
    required this.name,
    required this.active,
    required this.coins,
    required this.minBackgroundTime,
    this.country,
    this.state,
  });

  factory Social.fromDocument(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return Social(
      id: snap.id,
      tag: (data['tag'] as String?) ?? snap.id,
      type: (data['type'] as String?) ?? '',
      link: (data['link'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      active: (data['active'] as bool?) ?? true,
      coins: (data['coins'] as num?)?.toInt() ?? 10,
      minBackgroundTime: (data['minBackgroundTime'] as num?)?.toInt() ?? 30,
      country: data['country'] as String?,
      state: data['state'] as String?,
    );
  }

  /// Check if this social is available for the given country and state
  /// Returns true if:
  /// - No country/state restrictions (global)
  /// - Country matches and no state restriction
  /// - Country matches and state matches
  bool isAvailableFor(String? userCountry, String? userState) {
    // If no restrictions, available to everyone
    if (country == null && state == null) {
      return true;
    }

    // If country restriction exists, must match
    if (country != null) {
      if (userCountry == null ||
          country!.toLowerCase() != userCountry.toLowerCase()) {
        return false;
      }

      // If state restriction exists, must match
      if (state != null) {
        if (userState == null ||
            state!.toLowerCase() != userState.toLowerCase()) {
          return false;
        }
      }
    }

    return true;
  }
}
