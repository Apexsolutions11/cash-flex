package com.cash.flex

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cash.flex/package_checker"

    // Ensure all plugins (including webview_flutter_android used by youtube_player_iframe)
    // are registered on the engine. This avoids Pigeon "channel-error" issues.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Method channel for checking installed packages without QUERY_ALL_PACKAGES permission
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hasAnyPackageInstalled") {
                val packages = call.argument<List<String>>("packages")
                if (packages != null) {
                    val hasAny = PackageChecker.hasAnyPackageInstalled(this, packages)
                    result.success(hasAny)
                } else {
                    result.error("INVALID_ARGUMENT", "Packages list is null", null)
                }
            } else if (call.method == "getInstalledPackages") {
                val packages = call.argument<List<String>>("packages")
                if (packages != null) {
                    val installedPackages = PackageChecker.getInstalledPackages(this, packages)
                    result.success(installedPackages)
                } else {
                    result.error("INVALID_ARGUMENT", "Packages list is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
