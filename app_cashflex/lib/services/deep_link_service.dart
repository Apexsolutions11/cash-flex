import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'local_storage.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Initialize deep link service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _appLinks = AppLinks();
      _isInitialized = true;

      // Handle initial link (if app was opened via deep link)
      final initialLink = await _appLinks?.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      // Listen for deep links while app is running
      _linkSubscription = _appLinks?.uriLinkStream.listen(
        _handleDeepLink,
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize deep link service: $e');
    }
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    try {
      debugPrint('Received deep link: $uri');

      // Extract referral code from path: /r/{code}
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty &&
          pathSegments[0] == 'r' &&
          pathSegments.length >= 2) {
        final referralCode = pathSegments[1];
        if (referralCode.isNotEmpty) {
          _processReferralCode(referralCode);
        }
      }

      // Also check query parameters
      final queryParams = uri.queryParameters;
      final referralCodeFromQuery =
          queryParams['referralCode'] ??
          queryParams['code'] ??
          queryParams['ref'];
      if (referralCodeFromQuery != null && referralCodeFromQuery.isNotEmpty) {
        _processReferralCode(referralCodeFromQuery);
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  /// Process referral code from deep link
  Future<void> _processReferralCode(String code) async {
    try {
      final trimmedCode = code.trim();
      if (trimmedCode.isEmpty) return;

      debugPrint('Processing referral code from deep link: $trimmedCode');

      // Validate referral code format (6 alphanumeric characters)
      final referralCodeRegex = RegExp(r'^[A-Za-z0-9]{6}$');
      if (!referralCodeRegex.hasMatch(trimmedCode)) {
        debugPrint('Invalid referral code format: $trimmedCode');
        return;
      }

      // Store referral code for later use (when user signs up/logs in)
      await LocalStorage.setPendingReferralCode(trimmedCode);
      debugPrint('Stored pending referral code: $trimmedCode');
    } catch (e) {
      debugPrint('Error processing referral code: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}
