import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mintegral/flutter_mintegral.dart';

import '../utils/constant/constant.dart';

class MintegralAdService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// Initialize Mintegral SDK
  static Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Mintegral SDK already initialized');
      return true;
    }

    if (_isInitializing) {
      debugPrint('Mintegral SDK initialization already in progress');
      return false;
    }

    if (mintegralAppId.isEmpty || mintegralAppKey.isEmpty) {
      debugPrint('Mintegral SDK keys are missing. Skipping initialization.');
      return false;
    }

    _isInitializing = true;

    final completer = Completer<bool>();

    Mintegral.instance.initialize(
      appId: mintegralAppId,
      appKey: mintegralAppKey,
      onInitSuccess: () {
        _isInitialized = true;
        _isInitializing = false;
        debugPrint('Mintegral SDK initialized successfully');
        if (!completer.isCompleted) completer.complete(true);
      },
      onInitFail: (error) {
        _isInitializing = false;
        debugPrint('Mintegral SDK initialization failed: $error');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future;
  }

  /// Show interstitial ad.
  /// Returns true if ad was shown successfully, false otherwise.
  static Future<bool> showInterstitialAd() async {
    if (mintegralInterstitialPlacementId.isEmpty ||
        mintegralInterstitialUnitId.isEmpty) {
      debugPrint('Mintegral interstitial placement/unit ID is not configured');
      return false;
    }

    final completer = Completer<bool>();

    InterstitialAd.load(
      placementId: mintegralInterstitialPlacementId,
      unitId: mintegralInterstitialUnitId,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (_) {
              debugPrint('Mintegral interstitial ad shown');
            },
            onAdDismissedFullScreenContent: (_, RewardInfo rewardInfo) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (_, String error) {
              debugPrint('Mintegral interstitial ad failed to show: $error');
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (String error) {
          debugPrint('Mintegral interstitial ad failed to load: $error');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Check if Mintegral is configured and initialized
  static bool get isConfigured =>
      mintegralAppId.isNotEmpty &&
      mintegralAppKey.isNotEmpty &&
      mintegralInterstitialPlacementId.isNotEmpty &&
      mintegralInterstitialUnitId.isNotEmpty;

  static bool get isInitialized => _isInitialized;
}
