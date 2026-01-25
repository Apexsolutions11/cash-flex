import 'package:adjoe/extensions.dart';
import 'package:adjoe/gender.dart';
import 'package:adjoe/options.dart';
import 'package:adjoe/playtime.dart';
import 'package:adjoe/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constant/constant.dart';
import '../utils/helper/toast_manager.dart';

class OfferwallManager {
  static bool _areParametersValid(String uid, String key) =>
      uid.isNotEmpty && key.isNotEmpty;
  
  //! Adjoe SDK
  static Future<void> initAdjoe(
    String uid, {
    String? email,
    String? gender,
    int? age,
  }) async {
    if (!_areParametersValid(uid, adjoeHash)) {
      debugPrint('Adjoe SDK initialization skipped: Missing UID or Adjoe Hash');
      return;
    }

    try {
      if (await Playtime.isInitialized() == false) {
        final PlaytimeOptions options = PlaytimeOptions();
        options.userId = uid;

        // Attach optional profile data when available
        final hasProfileData =
            (email != null && email.isNotEmpty) ||
            (gender != null && gender.isNotEmpty) ||
            (age != null && age > 0);

        if (hasProfileData) {
          final PlaytimeExtensions extensions = PlaytimeExtensions();
          final PlaytimeUserProfile userProfile = PlaytimeUserProfile();

          if (email != null && email.isNotEmpty) {
            extensions.subId1 = email;
          }

          if (gender != null && gender.isNotEmpty) {
            final lower = gender.toLowerCase();
            userProfile.gender = lower == 'male'
                ? PlaytimeGender.MALE
                : lower == 'female'
                    ? PlaytimeGender.FEMALE
                    : PlaytimeGender.UNKNOWN;
          }

          if (age != null && age > 0) {
            final DateTime birthday =
                DateTime.now().subtract(Duration(days: age * 365));
            userProfile.birthday = birthday;
          }

          options.extensions = extensions;
          options.userProfile = userProfile;
        }

        await Playtime.init(adjoeHash, options);
      } else {
        debugPrint('Adjoe SDK already initialized');
      }
    } catch (e) {
      debugPrint('Error during Adjoe initialization: $e');
    }
  }

  static Future<void> showAdjoe(String uid) async {
    ToastManager.info('Loading...');

    if (!_areParametersValid(uid, adjoeHash)) {
      debugPrint(
        'Adjoe Offerwall skipped: Missing UID or Adjoe Hash',
      );
      return;
    }

    try {
      // Ensure SDK is initialized before showing catalog
      if (await Playtime.isInitialized() == false) {
        await initAdjoe(uid);
      }

      Playtime.showCatalog();
    } on MissingPluginException catch (e) {
      debugPrint('Adjoe plugin not available: $e');
      ToastManager.error(
        msg: 'Playtime is not available on this device.',
      );
    } catch (e) {
      debugPrint('Error showing Adjoe offerwall: $e');
      ToastManager.error(
        msg: 'Failed to open playtime. Please try again.',
      );
    }
  }

}