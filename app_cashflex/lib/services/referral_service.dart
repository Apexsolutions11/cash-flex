import 'dart:math';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../utils/constant/constant.dart';
import 'cloud_functions.dart';
import 'local_storage.dart';

class ReferralService {
  static final Random _random = Random();

  static const String _possibleChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  static final Dio _dio = Dio();

  static final RegExp _referralCodeRegex = RegExp(r'^[A-Za-z0-9]{6}$');

  /// Build a Play Store link that embeds the referral code using the Install Referrer API.
  /// This ensures the referrer arrives in `AndroidPlayInstallReferrer.installReferrer`.
  static String buildPlayStoreReferralLink(String referralCode) {
    final code = referralCode.trim();
    if (code.isEmpty) return playstoreLink;

    // Use a structured payload so we can parse it reliably later.
    // Play Store expects `referrer` value to be URL-encoded.
    final encodedReferrer = Uri.encodeComponent('referralCode=$code');
    final separator = playstoreLink.contains('?') ? '&' : '?';
    return '$playstoreLink${separator}referrer=$encodedReferrer';
  }

  static bool _looksLikeReferralCode(String value) {
    final v = value.trim();
    return _referralCodeRegex.hasMatch(v);
  }

  /// Extract referral code from the raw Install Referrer string.
  /// Supports formats:
  /// - "ABC123"
  /// - "referralCode=ABC123"
  /// - "utm_source=referral&utm_content=ABC123"
  /// - "referrer=referralCode%3DABC123" (encoded)
  static String? extractReferralCode(String installReferrer) {
    final raw = installReferrer.trim();
    if (raw.isEmpty) return null;

    // Decode up to a few times (handles nested encoding).
    final candidates = <String>{raw};
    String decoded = raw;
    for (var i = 0; i < 3; i++) {
      try {
        final next = Uri.decodeComponent(decoded);
        if (next == decoded) break;
        decoded = next;
        candidates.add(decoded);
      } catch (_) {
        break;
      }
    }

    for (final c in candidates) {
      final s = c.trim();
      if (s.isEmpty) continue;

      // Direct code
      if (_looksLikeReferralCode(s)) return s;

      // If string contains a leading "referrer=", strip it and retry.
      if (s.startsWith('referrer=')) {
        final inner = s.substring('referrer='.length).trim();
        final extracted = extractReferralCode(inner);
        if (extracted != null) return extracted;
      }

      // If this looks like a URL, use its query portion.
      String query = s;
      try {
        if (s.contains('://')) {
          query = Uri.parse(s).query;
        } else if (s.contains('?')) {
          query = s.split('?').last;
        }
      } catch (_) {
        // ignore, try as raw query below
      }

      if (!query.contains('=')) continue;

      Map<String, String> params = {};
      try {
        params = Uri.splitQueryString(query);
      } catch (_) {
        // ignore invalid query strings
        continue;
      }

      // If `referrer` param is present, it may contain another query string (encoded or not)
      final nestedReferrer = params['referrer'];
      if (nestedReferrer != null && nestedReferrer.trim().isNotEmpty) {
        final extracted = extractReferralCode(nestedReferrer);
        if (extracted != null) return extracted;
      }

      const keys = <String>[
        'referralCode',
        'referral_code',
        'ref',
        'code',
        'inviter',
        'invite',
        'utm_content',
        'utm_term',
      ];

      for (final k in keys) {
        final v = params[k];
        if (v == null || v.trim().isEmpty) continue;
        if (_looksLikeReferralCode(v)) return v.trim();

        // Sometimes the value itself is another query string.
        final extracted = extractReferralCode(v);
        if (extracted != null) return extracted;
      }
    }

    return null;
  }

  /// Extract gclid and fbclid from install referrer
  /// Returns a map with 'gclid' and 'fbclid' keys, or null if not found
  /// @deprecated Use extractAllTrackingParams() instead for scalable parameter detection
  static Future<Map<String, String?>> extractTrackingIds() async {
    try {
      final ReferrerDetails referrerDetails =
          await AndroidPlayInstallReferrer.installReferrer;
      final String installReferrer = referrerDetails.installReferrer ?? '';
      
      if (installReferrer.isEmpty) {
        return {'gclid': null, 'fbclid': null};
      }

      // Parse the install referrer string
      String? gclid;
      String? fbclid;

      // Try to parse as URL query string
      try {
        final uri = Uri.parse('?$installReferrer');
        gclid = uri.queryParameters['gclid'];
        fbclid = uri.queryParameters['fbclid'];
      } catch (_) {
        // If parsing fails, try direct string search
        if (installReferrer.contains('gclid=')) {
          final match = RegExp(r'gclid=([^&]+)').firstMatch(installReferrer);
          gclid = match?.group(1);
        }
        if (installReferrer.contains('fbclid=')) {
          final match = RegExp(r'fbclid=([^&]+)').firstMatch(installReferrer);
          fbclid = match?.group(1);
        }
      }

      return {
        'gclid': gclid?.trim().isEmpty == false ? gclid : null,
        'fbclid': fbclid?.trim().isEmpty == false ? fbclid : null,
      };
    } catch (e) {
      debugPrint('Error extracting tracking IDs: $e');
      return {'gclid': null, 'fbclid': null};
    }
  }

  /// Extract all parameters from install referrer
  /// Returns a map of all parameter names and their values found in the install referrer
  /// This is used for scalable parameter detection based on admin-defined parameters
  static Future<Map<String, String>> extractAllTrackingParams() async {
    try {
      final ReferrerDetails referrerDetails =
          await AndroidPlayInstallReferrer.installReferrer;
      final String installReferrer = referrerDetails.installReferrer ?? '';
      
      if (installReferrer.isEmpty) {
        return {};
      }

      Map<String, String> params = {};

      // Try to parse as URL query string
      try {
        final uri = Uri.parse('?$installReferrer');
        uri.queryParameters.forEach((key, value) {
          if (value.trim().isNotEmpty) {
            params[key.toLowerCase()] = value.trim();
          }
        });
      } catch (_) {
        // If parsing fails, try to extract parameters using regex
        // Match pattern: param=value
        final regex = RegExp(r'([^&=]+)=([^&]*)');
        final matches = regex.allMatches(installReferrer);
        for (final match in matches) {
          final key = match.group(1)?.trim().toLowerCase() ?? '';
          final value = match.group(2)?.trim() ?? '';
          if (key.isNotEmpty && value.isNotEmpty) {
            // Decode URL-encoded values
            try {
              params[key] = Uri.decodeComponent(value);
            } catch (_) {
              params[key] = value;
            }
          }
        }
      }

      // Also check nested referrer parameter if present
      final nestedReferrer = params['referrer'];
      if (nestedReferrer != null && nestedReferrer.isNotEmpty) {
        try {
          final nestedUri = Uri.parse('?$nestedReferrer');
          nestedUri.queryParameters.forEach((key, value) {
            if (value.trim().isNotEmpty) {
              params[key.toLowerCase()] = value.trim();
            }
          });
        } catch (_) {
          // Try regex extraction for nested referrer
          final regex = RegExp(r'([^&=]+)=([^&]*)');
          final matches = regex.allMatches(nestedReferrer);
          for (final match in matches) {
            final key = match.group(1)?.trim().toLowerCase() ?? '';
            final value = match.group(2)?.trim() ?? '';
            if (key.isNotEmpty && value.isNotEmpty) {
              try {
                params[key] = Uri.decodeComponent(value);
              } catch (_) {
                params[key] = value;
              }
            }
          }
        }
      }

      return params;
    } catch (e) {
      debugPrint('Error extracting all tracking params: $e');
      return {};
    }
  }

  /// Prefetch and cache install referral code as early as possible (Android only).
  /// This allows us to apply it later when the user signs up/logs in.
  static Future<void> prefetchAndCacheInstallReferralCode() async {
    try {
      // If already cached, don't re-fetch.
      final existing = LocalStorage.getPendingReferralCode();
      if (existing.isNotEmpty) return;

      final ReferrerDetails referrerDetails =
          await AndroidPlayInstallReferrer.installReferrer;
      final String installReferrer = referrerDetails.installReferrer ?? '';
      final extracted = extractReferralCode(installReferrer);
      if (extracted != null && extracted.trim().isNotEmpty) {
        await LocalStorage.setPendingReferralCode(extracted.trim());
      }
    } catch (e) {
      // Non-fatal (iOS / missing plugin / Play Store not available)
      debugPrint('Referral prefetch failed: $e');
    }
  }

  //! Generate Unique Referral Code
  static Future<String> generateReferralCode() async {
    while (true) {
      final String referralCode = List.generate(
        6,
        (index) => _possibleChars[_random.nextInt(_possibleChars.length)],
      ).join();

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('referralCode', isEqualTo: referralCode)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return referralCode;
      }
    }
  }

  //! Activate user account
  static Future<void> activateUserAccount(String referralCode) async {
    try {
      // Prefer cached referrer code (captured on first app startup).
      String extractedCode = LocalStorage.getPendingReferralCode();
      if (extractedCode.isEmpty) {
        final ReferrerDetails referrerDetails =
            await AndroidPlayInstallReferrer.installReferrer;
        final String installReferrer = referrerDetails.installReferrer ?? '';
        extractedCode = extractReferralCode(installReferrer) ?? '';
      }

      // If we have a valid referral code and it's not the current user's own code,
      // activate referral. Otherwise credit signup bonus.
      if (extractedCode.isNotEmpty &&
          extractedCode.trim() != referralCode.trim()) {
        await CloudFunctions.setReferral(extractedCode.trim());
        await LocalStorage.clearPendingReferralCode();
        return;
      }

      await CloudFunctions.creditSignupBonus();
      await LocalStorage.clearPendingReferralCode();
    } catch (e) {
      debugPrint('Error fetching install referrer: $e');
      await CloudFunctions.creditSignupBonus();
      await LocalStorage.clearPendingReferralCode();
    }
  }

  //! Save referral details
  static Future<void> saveReferralDetails(
    String name,
    String email,
    String userId,
  ) async {
    try {
      final ipRes = await _dio.get(AppConstant.ipApiUrl);

      if (ipRes.data['status'] == 'success') {
        final ReferrerDetails referrerDetails =
            await AndroidPlayInstallReferrer.installReferrer;

        final String installReferrer = referrerDetails.installReferrer ?? '';

        final refRes = await _dio.post(
          AppConstant.referralUrl,
          data: {
            'userName': name,
            'userEmail': email,
            'userId': userId,
            'packageName': packageName,
            'city': ipRes.data['city'] ?? '',
            'country': ipRes.data['country'] ?? '',
            'countryCode': ipRes.data['countryCode'] ?? '',
            'lat': ipRes.data['lat'] ?? 0.0,
            'lon': ipRes.data['lon'] ?? 0.0,
            'region': ipRes.data['region'] ?? '',
            'regionName': ipRes.data['regionName'] ?? '',
            'installReferrer': installReferrer,
          },
        );

        if (refRes.statusCode == 200) {
          debugPrint('Referral data posted successfully!');
        } else {
          debugPrint('Failed to post referral data: ${refRes.statusCode}');
        }
      } else {
        debugPrint('Failed to fetch location data');
      }
    } catch (e) {
      debugPrint('Error occurred: $e');
    }
  }
}