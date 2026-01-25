import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cashflex/models/more_apps_model.dart';

class LocalStorage {
  static final GetStorage _storage = GetStorage();
  static const String _pendingReferralCodeKey = 'pendingReferralCode';

  //! Init SDK
  static Future<void> init() async {
    try {
      await GetStorage.init();
    } catch (e) {
      debugPrint('Failed to init local storage: $e');
    }
  }

  //! App Data Token
  static Future<void> setAppDataToken(String appDataToken) async {
    try {
      await _storage.write('appDataToken', appDataToken);
    } catch (e) {
      debugPrint('Failed to set App Data Token: $e');
    }
  }

  static String getAppDataToken() => _storage.read('appDataToken') ?? '';

  //! App Data
  static Future<void> setAppData(Map<String, dynamic> appData) async {
    try {
      await _storage.write('appData', jsonEncode(appData));
    } catch (e) {
      debugPrint('Failed to set App Data: $e');
      setAppDataToken('');
    }
  }

  static Map<String, dynamic>? getAppData() {
    final dynamic dataString = _storage.read('appData');
    if (dataString != null) {
      return jsonDecode(dataString) as Map<String, dynamic>;
    }
    return null;
  }

  //! Get and set more apps data
  static void setMoreAppsData(List<MoreAppsDataModel> apps) {
    final List<Map<String, dynamic>> jsonData = apps
        .map(
          (app) => app.toJson(),
        )
        .toList();
    final Map<String, Object> dataWithTimestamp = {
      'timestamp': DateTime.now().toIso8601String(),
      'data': jsonData,
    };
    _storage.write(
      'moreAppsData',
      jsonEncode(dataWithTimestamp),
    );
  }

  static List<MoreAppsDataModel> getMoreAppsData() {
    final dynamic jsonData = _storage.read('moreAppsData');
    if (jsonData != null) {
      final Map<String, dynamic> decodedData = jsonDecode(jsonData);
      final DateTime timestamp = DateTime.parse(decodedData['timestamp']);
      final List<dynamic> appsData = decodedData['data'];

      if (DateTime.now().difference(timestamp).inDays > 4) {
        return [];
      }

      return appsData
          .map(
            (data) => MoreAppsDataModel.fromJson(data),
          )
          .toList();
    }
    return [];
  }

  //! Notification Permission Rejection Status
  static Future<void> setHasRejectedNotification(bool hasRejected) async {
    try {
      await _storage.write('hasRejectedNotification', hasRejected);
    } catch (e) {
      debugPrint('Failed to set hasRejectedNotification: $e');
    }
  }

  static bool getHasRejectedNotification() {
    return _storage.read('hasRejectedNotification') ?? false;
  }

  //! Per-device identifier (stored locally, not a hardware ID)
  static Future<void> setDeviceId(String id) async {
    try {
      await _storage.write('deviceId', id);
    } catch (e) {
      debugPrint('Failed to set deviceId: $e');
    }
  }

  static String getDeviceId() {
    return _storage.read('deviceId') ?? '';
  }

  /// Referral code captured from Play Install Referrer (Android) before login.
  /// We cache it so we can apply it after the user signs up/logs in.
  static Future<void> setPendingReferralCode(String code) async {
    try {
      await _storage.write(_pendingReferralCodeKey, code.trim());
    } catch (e) {
      debugPrint('Failed to set pending referral code: $e');
    }
  }

  static String getPendingReferralCode() {
    return (_storage.read(_pendingReferralCodeKey) as String?)?.trim() ?? '';
  }

  static Future<void> clearPendingReferralCode() async {
    try {
      await _storage.remove(_pendingReferralCodeKey);
    } catch (e) {
      debugPrint('Failed to clear pending referral code: $e');
    }
  }

  //! Layout Type Cache (determined once per app session)
  static Future<void> setCachedLayoutType(String layoutType) async {
    try {
      await _storage.write('cachedLayoutType', layoutType);
    } catch (e) {
      debugPrint('Failed to set cached layout type: $e');
    }
  }

  static String? getCachedLayoutType() {
    return _storage.read('cachedLayoutType') as String?;
  }

  static Future<void> clearCachedLayoutType() async {
    try {
      await _storage.remove('cachedLayoutType');
    } catch (e) {
      debugPrint('Failed to clear cached layout type: $e');
    }
  }

  //! Gemee Jackpot Played Today
  /// Marks that the given user has played the Gemee Jackpot today.
  /// If userId is null/empty, we still store a device-level flag for backward compatibility.
  static Future<void> setGemeeJackpotPlayedToday({required String? userId}) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final key = _jackpotKeyForUser(userId);
      await _storage.write(key, dateKey);
    } catch (e) {
      debugPrint('Failed to set gemee jackpot played date: $e');
    }
  }

  /// Checks if the current user has played the Gemee Jackpot today.
  /// If userId is null, falls back to the legacy device-level flag.
  static Future<bool> hasPlayedGemeeJackpotToday({required String? userId}) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';

      // Check user-specific key first (when userId is available)
      final key = _jackpotKeyForUser(userId);
      final storedDate = _storage.read(key) as String?;
      if (storedDate == dateKey) {
        return true;
      }

      // Backwards compatibility: also check legacy device-level key
      final legacyDate = _storage.read('gemeeJackpotPlayedDate') as String?;
      return legacyDate == dateKey;
    } catch (e) {
      debugPrint('Failed to check gemee jackpot played date for user: $e');
      return false;
    }
  }

  static String _jackpotKeyForUser(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      return 'gemeeJackpotPlayedDate';
    }
    return 'gemeeJackpotPlayedDate_${userId.trim()}';
  }
}
