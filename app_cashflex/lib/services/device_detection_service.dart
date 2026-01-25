import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import '../utils/constant/constant.dart' as constants;
import '../models/user_data_model.dart';
import 'referral_service.dart';
import 'local_storage.dart';

class DeviceDetectionService {
  static const MethodChannel _channel = MethodChannel('com.cash.flex/package_checker');
  /// Check if device is an emulator
  static Future<bool> isEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Check for emulator indicators
      final fingerprint = androidInfo.fingerprint.toLowerCase();
      final model = androidInfo.model.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();
      final device = androidInfo.device.toLowerCase();
      final product = androidInfo.product.toLowerCase();
      final hardware = androidInfo.hardware.toLowerCase();

      // Emulator detection patterns
      final emulatorPatterns = [
        'generic',
        'unknown',
        'google_sdk',
        'emulator',
        'android sdk built for x86',
        'genymotion',
        'sdk',
        'vbox86',
        'simulator',
        'goldfish',
        'ranchu',
      ];

      // Check fingerprint
      for (final pattern in emulatorPatterns) {
        if (fingerprint.contains(pattern)) {
          return true;
        }
      }

      // Check model
      if (model.contains('google_sdk') ||
          model.contains('emulator') ||
          model.contains('android sdk built for x86')) {
        return true;
      }

      // Check manufacturer
      if (manufacturer.contains('genymotion')) {
        return true;
      }

      // Check brand and device
      if (brand.startsWith('generic') && device.startsWith('generic')) {
        return true;
      }

      // Check product
      if (product == 'google_sdk' ||
          product.contains('sdk') ||
          product.contains('vbox86') ||
          product.contains('emulator') ||
          product.contains('simulator')) {
        return true;
      }

      // Check hardware
      if (hardware.contains('goldfish') || hardware.contains('ranchu')) {
        return true;
      }

      return false;
    } catch (e) {
      // Fallback: check the constant
      return constants.isEmulator;
    }
  }

  /// Check if VPN is active
  static Future<bool> isVpnActive() async {
    try {
      final response = await Dio().get(constants.AppConstant.ipApiUrl);
      final ipApiResponse = response.data;

      if (ipApiResponse['status'] != 'success') {
        return false;
      }

      // Check for VPN indicators
      final String? proxy = ipApiResponse['proxy'] as String?;
      final String? hosting = ipApiResponse['hosting'] as String?;
      final String? isp = ipApiResponse['isp'] as String?;

      // VPN detection logic
      if (proxy == 'yes' || proxy == 'true') {
        return true;
      }

      // Check for common VPN ISP keywords
      final ispLower = (isp ?? '').toLowerCase();
      final vpnKeywords = [
        'vpn',
        'proxy',
        'tor',
        'hosting',
        'datacenter',
        'server',
      ];

      for (final keyword in vpnKeywords) {
        if (ispLower.contains(keyword)) {
          return true;
        }
      }

      // If hosting is true, likely a VPN/datacenter
      if (hosting == 'yes' || hosting == 'true') {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasUpiApps() async {
    try {
      final List<String> upiPackages = [
        'com.phonepe.app', // PhonePe
        'net.one97.paytm', // Paytm
        'com.google.android.apps.nfc.payment', // Google Pay
        'com.amazon.mobile.android.payment', // Amazon Pay
        'com.mobikwik_new', // Mobikwik
        'com.freecharge.android', // Freecharge
        'com.airtel.airtel', // Airtel Thanks
        'com.axis.mobile', // Axis Pay
        'com.hdfc.smartbuy', // HDFC PayZapp
        'com.icici.bank', // ICICI iMobile
        'com.sbi.SBIFreedomPlus', // SBI Pay
        'com.bhimupi', // BHIM UPI
        'com.whatsapp', // WhatsApp Pay (if available)
        'com.google.android.apps.nbu.paisa.user', //
        'com.kotak811mobilebankingapp.instantsavingsupiscanandpayrecharge',
        'com.postpe.app',
      ];

      final installedPackages = await _channel.invokeMethod<List>('getInstalledPackages', {
        'packages': upiPackages,
      });

      final foundPackages = installedPackages
          ?.map((e) => e.toString())
          .toList() ?? <String>[];

      if (foundPackages.isNotEmpty) {
        developer.log(
          'UPI apps detected: ${foundPackages.join(", ")}',
          name: 'DeviceDetectionService',
        );
      } else {
        developer.log(
          'No UPI apps detected. Checked: ${upiPackages.join(", ")}',
          name: 'DeviceDetectionService',
        );
      }

      return foundPackages.isNotEmpty;
    } catch (e) {
      developer.log(
        'Error checking UPI apps: $e',
        name: 'DeviceDetectionService',
        error: e,
      );
      return false;
    }
  }

  static Future<String?> getUserCountry() async {
    try {
      final response = await Dio().get(constants.AppConstant.ipApiUrl);
      final ipApiResponse = response.data;

      if (ipApiResponse['status'] == 'success') {
        return ipApiResponse['countryCode'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasLocalApps() async {
    try {
      final List<String> localAppPackages = [
        'com.phonepe.app', // PhonePe
        'net.one97.paytm', // Paytm
        'com.fampay.fampay', // FamPay
      ];

      developer.log(
        'Checking for local apps: ${localAppPackages.join(", ")}',
        name: 'DeviceDetectionService',
      );

      final installedPackages = await _channel.invokeMethod<List>('getInstalledPackages', {
        'packages': localAppPackages,
      });

      final foundPackages = installedPackages
          ?.map((e) => e.toString())
          .toList() ?? <String>[];

      if (foundPackages.isNotEmpty) {
        developer.log(
          'Local apps detected: ${foundPackages.join(", ")}',
          name: 'DeviceDetectionService',
        );
      } else {
        developer.log(
          'No local apps detected. Checked: ${localAppPackages.join(", ")}',
          name: 'DeviceDetectionService',
        );
      }

      return foundPackages.isNotEmpty;
    } catch (e) {
      developer.log(
        'Error checking local apps: $e',
        name: 'DeviceDetectionService',
        error: e,
      );
      return false;
    }
  }

  /// Get list of installed apps from the tracked packages
  /// Returns a list of package names that are installed
  static Future<List<String>> getInstalledApps() async {
    try {
      final List<String> trackedAppPackages = [
        'com.phonepe.app', // PhonePe
        'net.one97.paytm', // Paytm
        'com.fampay.fampay', // FamPay
      ];

      final installedPackages = await _channel.invokeMethod<List>('getInstalledPackages', {
        'packages': trackedAppPackages,
      });

      final foundPackages = installedPackages
          ?.map((e) => e.toString())
          .toList() ?? <String>[];

      return foundPackages;
    } catch (e) {
      developer.log(
        'Error getting installed apps: $e',
        name: 'DeviceDetectionService',
        error: e,
      );
      return <String>[];
    }
  }

  /// Check if a specific package is installed
  /// Returns true if the package is installed, false otherwise
  static Future<bool> isPackageInstalled(String packageName) async {
    try {
      final installedPackages = await _channel.invokeMethod<List>(
        'getInstalledPackages',
        {
          'packages': [packageName],
        },
      );

      final foundPackages = installedPackages
          ?.map((e) => e.toString())
          .toList() ?? <String>[];

      return foundPackages.contains(packageName);
    } catch (e) {
      developer.log(
        'Error checking if package is installed: $e',
        name: 'DeviceDetectionService',
        error: e,
      );
      return false;
    }
  }

  static Future<String?> detectGoogleUserReason(UserDataModel? userData) async {
    if (userData == null) {
      debugPrint(
        '[User Classification] User data is null, cannot determine classification',
      );
      return null;
    }

    final userId = userData.userId ?? 'unknown';
    final email = userData.email ?? '';

    if (userData.internationalUser == true) {
      debugPrint(
        '[User Classification] User $userId: INTERNATIONAL_USER (has gclid/fbclid)',
      );
      return null; // Not a googleUser, so no reason needed
    }

    // Check if user is normal user
    if (userData.normalUser == true) {
      debugPrint('[User Classification] User $userId: NORMAL_USER');
      return null; // Not a googleUser, so no reason needed
    }

    // User is googleUser (normalUser = false), detect the reason
    String? reason;

    try {
      // Priority 1: Check for referral ID
      final pendingReferralCode = LocalStorage.getPendingReferralCode();
      String? referralId = pendingReferralCode;

      if (referralId.isEmpty) {
        try {
          final ReferrerDetails referrerDetails =
              await AndroidPlayInstallReferrer.installReferrer;
          final String installReferrer = referrerDetails.installReferrer ?? '';
          final extracted = ReferralService.extractReferralCode(
            installReferrer,
          );
          if (extracted != null && extracted.isNotEmpty) {
            referralId = extracted;
          }
        } catch (_) {
          // Ignore errors
        }
      }

      if (referralId != null && referralId.isNotEmpty) {
        // User has referral ID but is still googleUser - this shouldn't happen normally
        // but could be due to backend override
        reason = 'Has referral ID but marked as googleUser (backend override)';
        debugPrint(
          '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
        );
        return reason;
      }

      // Priority 2: Check for gclid/fbclid
      final trackingIds = await ReferralService.extractTrackingIds();
      if (trackingIds['gclid'] != null || trackingIds['fbclid'] != null) {
        // This should have been caught by internationalUser check, but just in case
        reason = 'Has gclid/fbclid but not marked as international user';
        debugPrint(
          '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
        );
        return reason;
      }

      // Priority 3: Check for VPN
      final isVpn = await isVpnActive();
      if (isVpn) {
        reason = 'VPN detected';
        debugPrint(
          '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
        );
        return reason;
      }

      // Priority 4: Check for emulator
      final isEmulatorDevice = await isEmulator();
      if (isEmulatorDevice) {
        reason = 'Emulator detected';
        debugPrint(
          '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
        );
        return reason;
      }

      // Priority 5: Check for local apps
      final hasLocalAppsInstalled = await hasLocalApps();
      if (!hasLocalAppsInstalled) {
        reason =
            'No local apps detected (missing: phonepay, paytm, fampay)';
        debugPrint(
          '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
        );
        return reason;
      }

      // Priority 6: Check email domain
      if (email.isNotEmpty && !email.endsWith('@gmail.com')) {
        reason = 'Non-Gmail email detected: $email';
        debugPrint(
          '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
        );
        return reason;
      }

      // Priority 7: Check ISP from IP API (if available)
      try {
        final response = await Dio().get(constants.AppConstant.ipApiUrl);
        final ipApiResponse = response.data;

        if (ipApiResponse['status'] == 'success') {
          final String? isp = ipApiResponse['isp'] as String?;
          if (isp != null && isp.toLowerCase().contains('google')) {
            reason = 'Google ISP detected: $isp';
            debugPrint(
              '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
            );
            return reason;
          }
        } else {
          reason = 'IP API response status was not success';
          debugPrint(
            '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
          );
          return reason;
        }
      } catch (e) {
        reason = 'Error fetching IP data: $e';
        debugPrint(
          '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
        );
        return reason;
      }

      // Fallback reason
      reason = 'Unknown reason (default classification)';
      debugPrint(
        '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
      );
      return reason;
    } catch (e) {
      reason = 'Error detecting reason: $e';
      debugPrint(
        '[User Classification] User $userId: GOOGLE_USER - Reason: $reason',
      );
      return reason;
    }
  }
}
