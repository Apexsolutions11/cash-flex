import 'package:flutter/foundation.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import '../services/layout_service.dart';
import '../services/device_detection_service.dart';
import '../utils/constant/constant.dart';
import '../services/referral_service.dart';
import '../services/local_storage.dart';
import '../services/auth_service.dart';

/// Service to determine layout type based on user classification rules
/// Now checks userType from Firestore first, then falls back to calculation if not present
class LayoutCacheService {
  LayoutCacheService._();

  /// Determine layout type based on userType from Firestore or classification rules
  /// Priority:
  /// 1. Check for forced layouts (highest priority)
  /// 2. Check userType from Firestore (if user is logged in and userType exists)
  /// 3. Fall back to calculation logic (for backward compatibility or when userType doesn't exist)
  static Future<LayoutType> determineAndCacheLayout() async {
    try {
      // Check for forced layouts first (bypasses all detection logic)
      if (forceNormalLayout) {
        debugPrint('[Layout Detection] Force normal layout enabled');
        return 'normal';
      }
      if (forceGoogleLayout) {
        debugPrint('[Layout Detection] Force google layout enabled');
        return 'google';
      }
      if (forceInternationalLayout) {
        debugPrint('[Layout Detection] Force international layout enabled');
        return 'international';
      }

      // Check if user is logged in and fetch userType from Firestore
      if (AuthService.isLoggedIn) {
        try {
          final userData = await AuthService.fetchUserDataModel();
          if (userData?.userType != null && userData!.userType!.isNotEmpty) {
            final userType = userData.userType!.toLowerCase();
            debugPrint('[Layout Detection] Using userType from Firestore: $userType');
            
            // Map userType to layout type
            switch (userType) {
              case 'normal':
                return 'normal';
              case 'international':
                return 'international';
              case 'google':
              default:
                return 'google';
            }
          }
        } catch (e) {
          debugPrint('[Layout Detection] Error fetching userType from Firestore: $e');
          // Fall through to calculation logic
        }
      }

      // Fallback: Calculate layout using rules (for backward compatibility or when userType doesn't exist)
      debugPrint('[Layout Detection] userType not found in Firestore, using calculation logic');

      // Rule 1: Check if Emulator/VPN detected -> GoogleUser
      final bool isEmulatorDevice = await DeviceDetectionService.isEmulator();
      final bool isVpn = await DeviceDetectionService.isVpnActive();
      
      if (isEmulatorDevice) {
        debugPrint('[Layout Detection] Rule 1: Emulator detected -> GoogleUser (google layout)');
        return 'google';
      }
      
      if (isVpn) {
        debugPrint('[Layout Detection] Rule 1: VPN detected -> GoogleUser (google layout)');
        return 'google';
      }

      // Rule 5: Check if user came from google/facebook campaigns (gclid or fbclid) -> international user
      // This should be checked early as it's a specific campaign source
      final trackingIds = await ReferralService.extractTrackingIds();
      if (trackingIds['gclid'] != null || trackingIds['fbclid'] != null) {
        debugPrint('[Layout Detection] Rule 5: gclid/fbclid detected -> International User (international layout)');
        return 'international';
      }

      // Rule 4: Check if user came from referral -> Normal User
      String referralId = LocalStorage.getPendingReferralCode();
      if (referralId.isEmpty) {
        try {
          final ReferrerDetails referrerDetails =
              await AndroidPlayInstallReferrer.installReferrer;
          final String installReferrer = referrerDetails.installReferrer ?? '';
          final extracted = ReferralService.extractReferralCode(installReferrer);
          if (extracted != null) {
            referralId = extracted;
          }
        } catch (_) {
          // Ignore errors
        }
      }
      
      if (referralId.isNotEmpty) {
        debugPrint('[Layout Detection] Rule 4: Referral ID detected ($referralId) -> Normal User (normal layout)');
        return 'normal';
      }

      // Rule 2: Check if Not a single app found among (phonepay, paytm, fampay) -> GoogleUser
      final bool hasLocalApps = await DeviceDetectionService.hasLocalApps();
      
      if (!hasLocalApps) {
        debugPrint('[Layout Detection] Rule 2: No local apps found -> GoogleUser (google layout)');
        return 'google';
      }

      // Rule 3: If any app is found && not an emulator -> normal user
      // (We already checked emulator above, so if we reach here, it's not an emulator)
      // (We already checked no apps above, so if we reach here, apps are found)
      debugPrint('[Layout Detection] Rule 3: Local apps found and not emulator -> Normal User (normal layout)');
      return 'normal';
    } catch (e) {
      debugPrint('[Layout Detection] Error determining layout: $e');
      // On any error, default to google layout (Rule 6: All other cases -> GoogleUser)
      debugPrint('[Layout Detection] Error occurred -> GoogleUser (google layout)');
      return 'google';
    }
  }

  /// Get layout type (checks Firestore userType first, then calculates)
  static Future<LayoutType> getCachedLayoutType() async {
    return await determineAndCacheLayout();
  }

  /// Clear cache (no-op since userType is stored in Firestore, kept for backward compatibility)
  static Future<void> clearCache() async {
    debugPrint('[Layout Detection] clearCache called (userType is stored in Firestore)');
  }
}

