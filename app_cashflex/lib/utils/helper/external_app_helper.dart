import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import '../../models/external_app_model.dart';
import '../../services/device_detection_service.dart';

/// Helper class for external app operations
class ExternalAppHelper {
  /// Extract package name from Play Store URL
  /// Example: https://play.google.com/store/apps/details?id=com.example.app
  /// Returns: com.example.app
  static String? extractPackageNameFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      // Check if it's a Play Store URL
      if (uri.host.contains('play.google.com') ||
          uri.host.contains('market.android.com')) {
        // Extract package name from 'id' query parameter
        final packageName = uri.queryParameters['id'];
        if (packageName != null && packageName.isNotEmpty) {
          return packageName;
        }
      }
    } catch (e) {
      debugPrint('Error extracting package name from URL: $e');
    }
    return null;
  }

  /// Launch app directly by package name using external_app_launcher
  /// Returns true if app was launched, false otherwise
  static Future<bool> launchAppDirectly(String packageName) async {
    try {
      await LaunchApp.openApp(
        androidPackageName: packageName,
        openStore: false, // Don't open Play Store if app is not installed
      );
      debugPrint('Successfully launched app: $packageName');
      return true;
    } catch (e) {
      debugPrint('Error launching app $packageName: $e');
      return false;
    }
  }

  /// Handle external app card tap
  /// 1. Extract package name from Play Store URL
  /// 2. Check if app is installed
  /// 3. If installed, launch directly
  /// 4. If not installed, return false to show modal
  static Future<bool> handleAppCardTap(ExternalAppModel app) async {
    // Only works on Android
    if (!Platform.isAndroid) {
      return false;
    }

    final playStoreUrl = app.playStoreUrl;
    if (playStoreUrl == null || playStoreUrl.isEmpty) {
      return false;
    }

    // Step 1: Extract package name from Play Store URL
    final packageName = extractPackageNameFromUrl(playStoreUrl);
    if (packageName == null || packageName.isEmpty) {
      debugPrint('Could not extract package name from URL: $playStoreUrl');
      return false;
    }

    // Step 2: Check if app is installed
    try {
      final isInstalled = await DeviceDetectionService.isPackageInstalled(
        packageName,
      );
      debugPrint('App $packageName is installed: $isInstalled');

      // Step 3: If installed, launch directly
      if (isInstalled) {
        final launched = await launchAppDirectly(packageName);
        if (launched) {
          return true; // App launched, don't show modal
        }
      }
    } catch (e) {
      debugPrint('Error checking/launching app: $e');
    }

    // Step 4: If not installed or launch failed, return false to show modal
    return false;
  }
}
