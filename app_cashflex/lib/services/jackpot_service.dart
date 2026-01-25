import 'package:flutter/foundation.dart';
import 'package:cashflex/services/local_storage.dart';

/// Service for tracking Lucky Jackpot plays in Firestore (per user, per day).
///
/// This replaces any local-only tracking so that all state lives in the
/// `users` collection in Firestore.
class JackpotService {
  JackpotService._();

  /// Returns `true` if the currently logged-in user has played the jackpot today.
  /// Tracked **locally** on the device (not in Firestore).
  static Future<bool> hasPlayedJackpotToday({required String? userId}) async {
    try {
      return await LocalStorage.hasPlayedGemeeJackpotToday(userId: userId);
    } catch (e, s) {
      debugPrint('Failed to check jackpot played status: $e\n$s');
      return false;
    }
  }

  /// Marks that the currently logged-in user has played the jackpot today.
  /// Stored **locally** on the device (not in Firestore).
  static Future<void> markJackpotPlayedToday({required String? userId}) async {
    try {
      await LocalStorage.setGemeeJackpotPlayedToday(userId: userId);
    } catch (e, s) {
      debugPrint('Failed to mark jackpot played today: $e\n$s');
    }
  }
}


