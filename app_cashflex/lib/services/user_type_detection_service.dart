import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ip_api_service.dart';
import '../services/device_detection_service.dart';
import '../services/auth_service.dart';
import '../utils/constant/constant.dart';

/// User type enum
enum UserType { google, normal, international }

extension UserTypeExtension on UserType {
  String get value {
    switch (this) {
      case UserType.google:
        return 'google';
      case UserType.normal:
        return 'normal';
      case UserType.international:
        return 'international';
    }
  }
}

/// Service to detect user type with priority-based logic
class UserTypeDetectionService {
  UserTypeDetectionService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Detect user type with priority-based logic
  /// Priority:
  /// 0. Check for forced layouts from admin panel (highest priority)
  /// 1. Check ISP and org from IP-API - if both are Google -> Google user (no further checking)
  /// 2. If normal/international, check device packages -> decide userType
  /// 3. Check if emulator -> Google, otherwise normal
  static Future<UserType> detectUserType() async {
    final user = AuthService.currentUser;
    if (user == null) {
      debugPrint(
        '[UserType Detection] User not logged in, defaulting to google',
      );
      return UserType.google;
    }

    try {
      // Step 0: Check for forced layouts from admin panel
      debugPrint('[UserType Detection] Step 0: Checking for forced layouts...');

      if (forceNormalLayout) {
        debugPrint(
          '[UserType Detection] Step 0: Force normal layout enabled → Normal user (no further checking)',
        );
        return UserType.normal;
      }

      if (forceGoogleLayout) {
        debugPrint(
          '[UserType Detection] Step 0: Force google layout enabled → Google user (no further checking)',
        );
        return UserType.google;
      }

      if (forceInternationalLayout) {
        debugPrint(
          '[UserType Detection] Step 0: Force international layout enabled → International user (no further checking)',
        );
        return UserType.international;
      }

      debugPrint(
        '[UserType Detection] Step 0: No forced layout detected, proceeding with detection...',
      );

      // Step 1: Check IP-API for Google anywhere in response
      debugPrint('[UserType Detection] Step 1: Checking IP-API...');
      final ipResponse = await IpApiService.fetchIpDetails();
      log('IPRESONSE: ${ipResponse?.toJson()}');

      // If IP API fails, directly assign as Google user and stop
      if (ipResponse == null) {
        debugPrint(
          '[UserType Detection] Step 1: IP API failed -> Google user (no further checking)',
        );
        await _storeUserData(
          user.uid,
          ipResponse: null,
          userType: UserType.google,
          installedApps: const [],
          isEmulator: false,
        );
        return UserType.google;
      }

      // Check if "google" appears anywhere in the entire response (case-insensitive)
      final containsGoogle = IpApiService.containsGoogle(ipResponse);

      if (containsGoogle) {
        debugPrint(
          '[UserType Detection] Step 1: Google found anywhere in IP API response -> Google user (no further checking)',
        );
        await _storeUserData(
          user.uid,
          ipResponse: ipResponse,
          userType: UserType.google,
          installedApps: const [],
          isEmulator: false,
        );
        return UserType.google;
      }

      debugPrint(
        '[UserType Detection] Step 1: No Google found in IP API response, continuing to Step 2...',
      );

      // Step 2: Check device packages
      debugPrint('[UserType Detection] Step 2: Checking device packages...');
      final installedApps = await DeviceDetectionService.getInstalledApps();

      if (installedApps.isEmpty) {
        debugPrint(
          '[UserType Detection] Step 2: No local apps found -> Google user',
        );
        await _storeUserData(
          user.uid,
          ipResponse: ipResponse,
          userType: UserType.google,
          installedApps: installedApps,
          isEmulator: false,
        );
        return UserType.google;
      }

      debugPrint(
        '[UserType Detection] Step 2: Local apps found: ${installedApps.join(", ")}, continuing to Step 3...',
      );

      // Step 3: Check if emulator
      debugPrint(
        '[UserType Detection] Step 3: Checking if device is emulator...',
      );
      final isEmulator = await DeviceDetectionService.isEmulator();

      if (isEmulator) {
        debugPrint(
          '[UserType Detection] Step 3: Emulator detected -> Google user',
        );
        await _storeUserData(
          user.uid,
          ipResponse: ipResponse,
          userType: UserType.google,
          installedApps: installedApps,
          isEmulator: isEmulator,
        );
        return UserType.google;
      }

      // Final decision: Normal user
      debugPrint(
        '[UserType Detection] Step 3: Not emulator, local apps found -> Normal user',
      );
      await _storeUserData(
        user.uid,
        ipResponse: ipResponse,
        userType: UserType.normal,
        installedApps: installedApps,
        isEmulator: isEmulator,
      );
      return UserType.normal;
    } catch (e) {
      debugPrint('[UserType Detection] Error during detection: $e');
      // On error, default to google
      await _storeUserData(
        user.uid,
        ipResponse: null,
        userType: UserType.google,
        installedApps: const [],
        isEmulator: false,
      );
      return UserType.google;
    }
  }

  /// Store user data to Firestore (matches UserDataModel structure)
  static Future<void> _storeUserData(
    String userId, {
    required IpApiResponse? ipResponse,
    required UserType userType,
    required List<String> installedApps,
    required bool isEmulator,
  }) async {
    try {
      log(
        '[UserType Detection] Starting to store user data for userId: $userId',
      );
      final userDoc = _firestore.collection('users').doc(userId);

      final updateData = <String, dynamic>{
        'userType': userType.value,
        'installedApps': installedApps,
        'isEmulator': isEmulator,
      };

      // Add IP details if available
      if (ipResponse != null) {
        log(
          '[UserType Detection] IP Response country value: ${ipResponse.country}',
        );
        log(
          '[UserType Detection] IP Response countryCode value: ${ipResponse.countryCode}',
        );

        // Only add non-null values to avoid overwriting with null
        if (ipResponse.ip != null) updateData['ipAddress'] = ipResponse.ip;
        if (ipResponse.query != null) updateData['ipQuery'] = ipResponse.query;
        if (ipResponse.country != null) {
          updateData['country'] = ipResponse.country;
        }
        if (ipResponse.countryCode != null) {
          updateData['countryCode'] = ipResponse.countryCode;
        }
        if (ipResponse.region != null) updateData['region'] = ipResponse.region;
        if (ipResponse.regionName != null) {
          updateData['regionName'] = ipResponse.regionName;
        }
        if (ipResponse.city != null) updateData['city'] = ipResponse.city;
        if (ipResponse.zip != null) updateData['zip'] = ipResponse.zip;
        if (ipResponse.lat != null) updateData['lat'] = ipResponse.lat;
        if (ipResponse.lon != null) updateData['lon'] = ipResponse.lon;
        if (ipResponse.timezone != null) {
          updateData['timezone'] = ipResponse.timezone;
        }
        if (ipResponse.isp != null) updateData['isp'] = ipResponse.isp;
        if (ipResponse.org != null) updateData['org'] = ipResponse.org;
        if (ipResponse.asNumber != null) updateData['as'] = ipResponse.asNumber;

        log(
          '[UserType Detection] After adding IP data, country in updateData: ${updateData['country']}',
        );
      }

      log('[UserType Detection] Data to store: $updateData');
      log(
        '[UserType Detection] Country value being stored: ${updateData['country']}',
      );
      log(
        '[UserType Detection] Country type: ${updateData['country'].runtimeType}',
      );
      log('[UserType Detection] Document path: users/$userId');

      // Always use set with merge - this works whether document exists or not
      await userDoc.set(updateData, SetOptions(merge: true));

      log('[UserType Detection] Successfully stored user data to Firestore');
      debugPrint(
        '[UserType Detection] Stored user data to Firestore: userType=${userType.value}, isp=${ipResponse?.isp}, country=${ipResponse?.country}, installedApps=${installedApps.length}, isEmulator=$isEmulator',
      );

      // Verify the write by reading back
      final verifyDoc = await userDoc.get();
      if (verifyDoc.exists) {
        final data = verifyDoc.data();
        log('[UserType Detection] Verification: Document exists after write');
        log(
          '[UserType Detection] Verification: userType = ${data?['userType']}',
        );
        log('[UserType Detection] Verification: isp = ${data?['isp']}');
        log('[UserType Detection] Verification: country = ${data?['country']}');
        log(
          '[UserType Detection] Verification: countryCode = ${data?['countryCode']}',
        );
        log(
          '[UserType Detection] Verification: Full document data keys: ${data?.keys.toList()}',
        );
      } else {
        log(
          '[UserType Detection] WARNING: Document does not exist after write!',
        );
      }
    } catch (e, stackTrace) {
      log('[UserType Detection] ERROR storing user data: $e');
      log('[UserType Detection] Stack trace: $stackTrace');
      debugPrint('[UserType Detection] Error storing user data: $e');
      debugPrint('[UserType Detection] Stack trace: $stackTrace');

      // Retry with set merge as fallback
      try {
        log('[UserType Detection] Retrying with set merge...');
        final userDoc = _firestore.collection('users').doc(userId);
        final retryData = <String, dynamic>{
          'userType': userType.value,
          'installedApps': installedApps,
          'isEmulator': isEmulator,
        };

        if (ipResponse != null) {
          // Only add non-null values to avoid overwriting with null
          if (ipResponse.ip != null) retryData['ipAddress'] = ipResponse.ip;
          if (ipResponse.query != null) retryData['ipQuery'] = ipResponse.query;
          if (ipResponse.country != null) {
            retryData['country'] = ipResponse.country;
          }
          if (ipResponse.countryCode != null) {
            retryData['countryCode'] = ipResponse.countryCode;
          }
          if (ipResponse.region != null) {
            retryData['region'] = ipResponse.region;
          }
          if (ipResponse.regionName != null) {
            retryData['regionName'] = ipResponse.regionName;
          }
          if (ipResponse.city != null) retryData['city'] = ipResponse.city;
          if (ipResponse.zip != null) retryData['zip'] = ipResponse.zip;
          if (ipResponse.lat != null) retryData['lat'] = ipResponse.lat;
          if (ipResponse.lon != null) retryData['lon'] = ipResponse.lon;
          if (ipResponse.timezone != null) {
            retryData['timezone'] = ipResponse.timezone;
          }
          if (ipResponse.isp != null) retryData['isp'] = ipResponse.isp;
          if (ipResponse.org != null) retryData['org'] = ipResponse.org;
          if (ipResponse.asNumber != null) {
            retryData['as'] = ipResponse.asNumber;
          }
        }

        log('[UserType Detection] Retry data: $retryData');
        await userDoc.set(retryData, SetOptions(merge: true));
        log('[UserType Detection] Retry successful');
      } catch (retryError, retryStack) {
        log('[UserType Detection] Retry failed: $retryError');
        log('[UserType Detection] Retry stack trace: $retryStack');
        debugPrint('[UserType Detection] Retry failed: $retryError');
        debugPrint('[UserType Detection] Retry stack trace: $retryStack');
      }
    }
  }
}
