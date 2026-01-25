import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import '../utils/constant/constant.dart';
import 'device_detection_service.dart';
import 'referral_service.dart';
import 'local_storage.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstant.backendApiUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Get Firebase Auth token for authenticated requests
  static Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  /// Make an authenticated API call
  static Future<Map<String, dynamic>> _makeApiCall(
    String endpoint,
    Map<String, dynamic>? data, {
    String method = 'POST',
  }) async {
    try {
      final token = await _getAuthToken();
      
      final options = Options(
        method: method,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      Response response;
      if (method == 'GET') {
        response = await _dio.get(endpoint, options: options);
      } else {
        response = await _dio.post(
          endpoint,
          data: data,
          options: options,
        );
      }

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        return {
          'response': 'error',
          'message': 'Invalid Response',
        };
      }
    } on DioException catch (e) {
      debugPrint(
        'API call error!\n'
        'Endpoint: $endpoint\n'
        'Status: ${e.response?.statusCode}\n'
        'Message: ${e.message}\n'
        'Response: ${e.response?.data}',
      );

      // Handle error response
      if (e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data as Map);
      }

      return {
        'response': 'error',
        'message': e.message ?? 'Network error',
      };
    } catch (e) {
      debugPrint('Unexpected API error: $e');
      return {
        'response': 'error',
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get server time
  static Future<Map<String, dynamic>> getServerTime() async {
    return await _makeApiCall('/get-server-time', null, method: 'GET');
  }

  /// Collect all user classification data
  static Future<Map<String, dynamic>> _collectUserClassificationData() async {
    final Map<String, dynamic> data = {};
    
    try {
      // Get referral ID from install referrer
      final pendingReferralCode = LocalStorage.getPendingReferralCode();
      if (pendingReferralCode.isNotEmpty) {
        data['referralId'] = pendingReferralCode;
      } else {
        // Try to extract from install referrer directly
        try {
          final ReferrerDetails referrerDetails =
              await AndroidPlayInstallReferrer.installReferrer;
          final String installReferrer = referrerDetails.installReferrer ?? '';
          final extracted = ReferralService.extractReferralCode(installReferrer);
          if (extracted != null && extracted.isNotEmpty) {
            data['referralId'] = extracted;
          }
        } catch (_) {
          // Ignore errors
        }
      }
      
      // Extract all parameters from install referrer for scalable detection
      final allParams = await ReferralService.extractAllTrackingParams();
      if (allParams.isNotEmpty) {
        data['trackingParams'] = allParams;
      }
      
      // Also extract gclid and fbclid for backward compatibility
      final trackingIds = await ReferralService.extractTrackingIds();
      if (trackingIds['gclid'] != null) {
        data['gclid'] = trackingIds['gclid'];
      }
      if (trackingIds['fbclid'] != null) {
        data['fbclid'] = trackingIds['fbclid'];
      }
      
      // Check for local apps
      final hasLocalApps = await DeviceDetectionService.hasLocalApps();
      data['hasLocalApps'] = hasLocalApps;
      
      // Get list of installed apps
      final installedApps = await DeviceDetectionService.getInstalledApps();
      data['installedApps'] = installedApps;
      
      // Check for VPN
      final isVpn = await DeviceDetectionService.isVpnActive();
      data['isVpn'] = isVpn;
      
      // Check for emulator
      final isEmulator = await DeviceDetectionService.isEmulator();
      data['isEmulator'] = isEmulator;
    } catch (e) {
      debugPrint('Error collecting user classification data: $e');
      // Continue with whatever data we have
    }
    
    return data;
  }

  /// Authenticate user with automatic data collection
  static Future<bool> authenticateUser() async {
    final classificationData = await _collectUserClassificationData();
    final response = await _makeApiCall('/authenticate-user', classificationData);
    return response['response'] == 'success';
  }

  /// Set referral code
  static Future<void> setReferral(String referralCode) async {
    await _makeApiCall('/set-referral', {'referralCode': referralCode});
  }

  /// Request payout
  static Future<String> requestPayout(
    String id,
    int leaderboardTimeLeft,
  ) async {
    final response = await _makeApiCall('/request-payout', {'id': id});
    
    if (response['response'] == 'success') {
      return 'success';
    } else if (response['reason'] == 'DAILY_LIMIT') {
      final int currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
      final int timeDifferenceMillis = leaderboardTimeLeft - currentTimeMillis;

      final int hours = (timeDifferenceMillis ~/ (1000 * 60 * 60)) % 24;
      final int minutes = (timeDifferenceMillis ~/ (1000 * 60)) % 60;

      if (hours > 0) {
        return 'Daily payout limit reached. Please try again after $hours hours $minutes minutes.';
      } else {
        return 'Daily payout limit reached. Please try again after $minutes minutes.';
      }
    } else {
      return response['reason'] ?? 'Unknown error';
    }
  }

  /// Follow reward
  static Future<Map<String, dynamic>> followReward(String tag) async {
    return await _makeApiCall('/follow-reward', {'tag': tag});
  }

  /// More apps reward (Install & Earn)
  static Future<Map<String, dynamic>> moreAppReward(String appId) async {
    return await _makeApiCall('/more-app-reward', {'appId': appId});
  }

  /// Rating reward
  static Future<Map<String, dynamic>> ratingReward() async {
    return await _makeApiCall('/rating-reward', {});
  }

  /// Credit signup bonus
  static Future<void> creditSignupBonus() async {
    await _makeApiCall('/credit-signup-bonus', {});
  }

  /// Review task reward
  static Future<Map<String, dynamic>> reviewTaskReward(String name) async {
    return await _makeApiCall('/review-task-reward', {'name': name});
  }

  /// Claim energy
  static Future<void> claimEnergy() async {
    await _makeApiCall('/claim-energy', {});
  }

  /// Claim coins
  static Future<void> claimCoins(int coins, String title) async {
    await _makeApiCall('/claim-coins', {
      'coins': coins,
      'title': title,
    });
  }

  /// Increment game count
  static Future<Map<String, dynamic>> incrementGameCount() async {
    return await _makeApiCall('/increment-game-count', {});
  }
}

