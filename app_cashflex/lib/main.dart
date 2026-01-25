import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'package:cashflex/services/local_storage.dart';
import 'package:cashflex/services/app_config_service.dart';
import 'package:cashflex/services/notification_service.dart';
import 'package:cashflex/services/connectivity_service.dart';
import 'package:cashflex/services/referral_service.dart';
import 'package:cashflex/services/deep_link_service.dart';
import 'package:cashflex/utils/constant/constant.dart';
import 'package:cashflex/services/mintegral_ad_service.dart';
import 'package:geemee_flutter/geemee_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/splash_page.dart';
import 'pages/no_internet_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await LocalStorage.init();

  try {
    await AppConfigService.load();
  } catch (e) {
    debugPrint('AppConfigService.load failed: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('NotificationService.init failed: $e');
  }

  try {
    await ReferralService.prefetchAndCacheInstallReferralCode();
  } catch (_) {}

  try {
    await DeepLinkService.instance.initialize();
  } catch (_) {}

  if (geemeeAppId.isNotEmpty) {
    try {
      await GeemeeFlutter.initSDK(appKey: geemeeAppId);
    } catch (e) {
      debugPrint('Failed to initialize Geemee SDK: $e');
    }
  }

  if (MintegralAdService.isConfigured) {
    try {
      await MintegralAdService.initialize();
    } catch (e) {
      debugPrint('Failed to initialize Mintegral SDK: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: AppConstant.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashPage(),
        routes: {'/no-internet': (context) => const NoInternetPage()},
        builder: (context, child) {
          return ConnectivityWrapper(child: child ?? const SizedBox());
        },
      ),
    );
  }
}

/// Widget that monitors connectivity and automatically navigates
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  @override
  void initState() {
    super.initState();
    // Start listening after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startConnectivityMonitoring();
    });
  }

  void _startConnectivityMonitoring() {
    if (!mounted) return;

    final connectivityService = ConnectivityService.instance;
    connectivityService.startListening(context);
  }

  @override
  void dispose() {
    ConnectivityService.instance.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
