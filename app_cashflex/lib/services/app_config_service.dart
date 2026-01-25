import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cashflex/services/local_storage.dart';
import 'package:cashflex/utils/constant/constant.dart';

class AppConfigService {
  AppConfigService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load app configuration from Firestore and populate global constants.
  ///
  /// This uses `admin/tokens.appDataToken` for a cheap cache check:
  /// - If the token is unchanged, we just apply the last saved `appData`
  ///   from local storage (if available).
  /// - If the token changed or local cache is missing, we fetch `admin/appData`,
  ///   persist it to local storage, and then apply it.
  static Future<void> load() async {
    try {
      // 1. Read latest appData token from Firestore
      final tokensSnap =
          await _firestore.collection('admin').doc('tokens').get();
      final remoteToken = tokensSnap.data()?['appDataToken'] as String? ?? '';

      final localToken = LocalStorage.getAppDataToken();

      Map<String, dynamic>? appData;

      // 2. Decide whether to reuse cached app data or fetch fresh
      if (remoteToken.isNotEmpty &&
          localToken.isNotEmpty &&
          remoteToken == localToken) {
        appData = LocalStorage.getAppData();
      }

      if (appData == null) {
        // 3. Fetch fresh app data from Firestore
        final appDataSnap =
            await _firestore.collection('admin').doc('appData').get();

        appData = appDataSnap.data();

        if (appData != null) {
          await LocalStorage.setAppData(appData);
          await LocalStorage.setAppDataToken(remoteToken);
        }
      }

      if (appData != null) {
        _applyAppData(appData);
      }
    } catch (e, s) {
      debugPrint('Failed to load app config: $e\n$s');

      // Fallback: try to apply whatever is in local storage
      try {
        final cached = LocalStorage.getAppData();
        if (cached != null) {
          _applyAppData(cached);
        }
      } catch (_) {
        // Ignore – we'll just use default values from constants.
      }
    }
  }

  static void _applyAppData(Map<String, dynamic> data) {
    try {
      // Max accounts per device
      final dynamic maxAcc = data['maxAccountsPerDevice'];
      if (maxAcc is int) {
        maxAccountPerDevice = maxAcc;
      } else if (maxAcc is num) {
        maxAccountPerDevice = maxAcc.toInt();
      }

      // Review & chatbot
      final dynamic reviewFlag = data['reviewEnabled'];
      if (reviewFlag is bool) {
        reviewEnabled = reviewFlag;
      }

      final dynamic chatbotValue = data['chatbot'];
      if (chatbotValue is String) {
        chatbot = chatbotValue;
      }

      // Mintegral keys
      final dynamic mtgAppId = data['mintegralAppId'];
      if (mtgAppId is String) {
        mintegralAppId = mtgAppId;
      }

      final dynamic mtgAppKey = data['mintegralAppKey'];
      if (mtgAppKey is String) {
        mintegralAppKey = mtgAppKey;
      }

      final dynamic mtgInterstitialPlacementId =
          data['mintegralInterstitialPlacementId'];
      if (mtgInterstitialPlacementId is String) {
        mintegralInterstitialPlacementId = mtgInterstitialPlacementId;
      }

      final dynamic mtgInterstitialUnitId =
          data['mintegralInterstitialUnitId'];
      if (mtgInterstitialUnitId is String) {
        mintegralInterstitialUnitId = mtgInterstitialUnitId;
      }

      // Adjoe & Tenjin
      final dynamic adjoe = data['adjoeHash'];
      if (adjoe is String) {
        adjoeHash = adjoe;
      }

      final dynamic tenjin = data['tenjinSdkKey'];
      if (tenjin is String) {
        tenjinSdkKey = tenjin;
      }

      // Geemee
      final dynamic geemeeAppIdValue = data['geemeeAppId'];
      if (geemeeAppIdValue is String) {
        geemeeAppId = geemeeAppIdValue;
      }

      final dynamic geemeePlacementId = data['geemeeOfferwallPlacementId'];
      if (geemeePlacementId is String) {
        geemeeOfferwallPlacementId = geemeePlacementId;
      }

      // How to Earn video (YouTube URL)
      final dynamic howToEarnUrl = data['howToEarnYoutubeUrl'];
      if (howToEarnUrl is String) {
        howToEarnYoutubeUrl = howToEarnUrl;
      }

      // Coin conversion rates (coins per 1 unit)
      // - India: coins per ₹1 (INR)
      // - Foreign: coins per $1 (USD)
      final dynamic inrFactor = data['indiaCoinCurFactor'];
      if (inrFactor is int) {
        indiaCoinCurFactor = inrFactor;
      } else if (inrFactor is num) {
        indiaCoinCurFactor = inrFactor.toInt();
      }

      final dynamic usdFactor = data['foreignCoinCurFactor'];
      if (usdFactor is int) {
        foreignCoinCurFactor = usdFactor;
      } else if (usdFactor is num) {
        foreignCoinCurFactor = usdFactor.toInt();
      }

      // Contact Us mailto link (admin-configurable)
      final dynamic contactValue = data['contactUsMailto'];
      if (contactValue is String) {
        final trimmed = contactValue.trim();
        if (trimmed.isEmpty) {
          contactUsMailto = AppConstant.contactUs;
        } else if (trimmed.startsWith('mailto:')) {
          contactUsMailto = trimmed;
        } else if (trimmed.contains('@') && !trimmed.contains(' ')) {
          // Allow admin to enter just an email like "support@x.com"
          contactUsMailto = 'mailto:$trimmed';
        } else {
          // If they entered some other scheme, keep as-is and let launcher handle it
          contactUsMailto = trimmed;
        }
      }

      // Privacy Policy URL (admin-configurable)
      final dynamic privacyPolicyValue = data['privacyPolicyUrl'];
      if (privacyPolicyValue is String) {
        final trimmed = privacyPolicyValue.trim();
        if (trimmed.isEmpty) {
          privacyPolicyUrl = AppConstant.privacyPolicy;
        } else {
          privacyPolicyUrl = trimmed;
        }
      }

      // Task defaults + instruction templates
      final dynamic followCoins = data['followTaskDefaultCoins'];
      if (followCoins is int) {
        followTaskDefaultCoins = followCoins;
      } else if (followCoins is num) {
        followTaskDefaultCoins = followCoins.toInt();
      }
      final dynamic followTime = data['followTaskMinBackgroundTime'];
      if (followTime is int) {
        followTaskMinBackgroundTime = followTime;
      } else if (followTime is num) {
        followTaskMinBackgroundTime = followTime.toInt();
      }
      final dynamic followInstr = data['followTaskInstructions'];
      if (followInstr is String) {
        followTaskInstructions = followInstr;
      }

      final dynamic reviewCoinsValue = data['reviewTaskDefaultCoins'];
      if (reviewCoinsValue is int) {
        reviewTaskDefaultCoins = reviewCoinsValue;
      } else if (reviewCoinsValue is num) {
        reviewTaskDefaultCoins = reviewCoinsValue.toInt();
      }
      final dynamic reviewTimeValue = data['reviewTaskMinBackgroundTime'];
      if (reviewTimeValue is int) {
        reviewTaskMinBackgroundTime = reviewTimeValue;
      } else if (reviewTimeValue is num) {
        reviewTaskMinBackgroundTime = reviewTimeValue.toInt();
      }
      final dynamic reviewInstrValue = data['reviewTaskInstructions'];
      if (reviewInstrValue is String) {
        reviewTaskInstructions = reviewInstrValue;
      }

      final dynamic moreAppsCoinsValue = data['moreAppsDefaultCoins'];
      if (moreAppsCoinsValue is int) {
        moreAppsDefaultCoins = moreAppsCoinsValue;
      } else if (moreAppsCoinsValue is num) {
        moreAppsDefaultCoins = moreAppsCoinsValue.toInt();
      }
      final dynamic moreAppsTimeValue = data['moreAppsMinBackgroundTime'];
      if (moreAppsTimeValue is int) {
        moreAppsMinBackgroundTime = moreAppsTimeValue;
      } else if (moreAppsTimeValue is num) {
        moreAppsMinBackgroundTime = moreAppsTimeValue.toInt();
      }
      final dynamic moreAppsInstrValue = data['moreAppsInstructions'];
      if (moreAppsInstrValue is String) {
        moreAppsInstructions = moreAppsInstrValue;
      }

      final dynamic rateCoinsValue = data['rateUsCoins'];
      if (rateCoinsValue is int) {
        rateUsCoins = rateCoinsValue;
      } else if (rateCoinsValue is num) {
        rateUsCoins = rateCoinsValue.toInt();
      }
      final dynamic rateCardValue = data['rateUsCardText'];
      if (rateCardValue is String) {
        rateUsCardText = rateCardValue;
      }
      final dynamic rateDialogValue = data['rateUsDialogText'];
      if (rateDialogValue is String) {
        rateUsDialogText = rateDialogValue;
      }

      // Daily game limit
      final dynamic dailyGameLimitValue = data['dailyGameLimit'];
      if (dailyGameLimitValue is int) {
        dailyGameLimit = dailyGameLimitValue;
      } else if (dailyGameLimitValue is num) {
        dailyGameLimit = dailyGameLimitValue.toInt();
      }

      // Geemee offerwall reward coins
      final dynamic geemeeRewardCoinsValue = data['geemeeOfferwallRewardCoins'];
      if (geemeeRewardCoinsValue is int) {
        geemeeOfferwallRewardCoins = geemeeRewardCoinsValue;
      } else if (geemeeRewardCoinsValue is num) {
        geemeeOfferwallRewardCoins = geemeeRewardCoinsValue.toInt();
      }

      // Referral signup bonus coins
      final dynamic referralSignupBonusValue = data['referralSignupBonusCoins'];
      if (referralSignupBonusValue is int) {
        referralSignupBonusCoins = referralSignupBonusValue;
      } else if (referralSignupBonusValue is num) {
        referralSignupBonusCoins = referralSignupBonusValue.toInt();
      }

      // Force user to play jackpot
      final dynamic forceJackpotValue = data['forceUserToPlayJackpot'];
      if (forceJackpotValue is bool) {
        forceUserToPlayJackpot = forceJackpotValue;
      }

      // Layout flags
      final dynamic normalLayoutFlag = data['normalLayoutEnabled'];
      if (normalLayoutFlag is bool) {
        normalLayoutEnabled = normalLayoutFlag;
      }

      final dynamic internationalLayoutFlag = data['internationalLayoutEnabled'];
      if (internationalLayoutFlag is bool) {
        internationalLayoutEnabled = internationalLayoutFlag;
      }

      // Force layout flags
      final dynamic forceNormalFlag = data['forceNormalLayout'];
      if (forceNormalFlag is bool) {
        forceNormalLayout = forceNormalFlag;
      }

      final dynamic forceGoogleFlag = data['forceGoogleLayout'];
      if (forceGoogleFlag is bool) {
        forceGoogleLayout = forceGoogleFlag;
      }

      final dynamic forceInternationalFlag = data['forceInternationalLayout'];
      if (forceInternationalFlag is bool) {
        forceInternationalLayout = forceInternationalFlag;
      }

      // Redeem page notice
      final dynamic redeemNoticeValue = data['redeemNotice'];
      if (redeemNoticeValue is String) {
        redeemNotice = redeemNoticeValue;
      }

      // IP API Configuration
      final dynamic ipApiBaseUrlValue = data['ipApiBaseUrl'];
      if (ipApiBaseUrlValue is String && ipApiBaseUrlValue.trim().isNotEmpty) {
        ipApiBaseUrl = ipApiBaseUrlValue.trim();
        // Ensure it ends with / if it's a base URL
        if (!ipApiBaseUrl.endsWith('/')) {
          ipApiBaseUrl = '$ipApiBaseUrl/';
        }
      }

      final dynamic ipApiKeyValue = data['ipApiKey'];
      if (ipApiKeyValue is String && ipApiKeyValue.trim().isNotEmpty) {
        ipApiKey = ipApiKeyValue.trim();
      }
    } catch (e, s) {
      debugPrint('Failed to apply app data: $e\n$s');
    }
  }
}


