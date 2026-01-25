import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/auth_service.dart';
import '../services/cloud_functions.dart';
import '../services/offerwall_manager.dart';
import '../services/user_type_detection_service.dart';
import '../utils/constant/constant.dart';
import '../providers/layout_provider.dart';
import 'package:geemee_flutter/geemee_flutter.dart';
import 'main_navigation.dart';
import '../theme/app_theme.dart';

enum DetectionStep { step1, step2, step3, completed }

class DataFetchingPage extends ConsumerStatefulWidget {
  const DataFetchingPage({super.key});

  @override
  ConsumerState<DataFetchingPage> createState() => _DataFetchingPageState();
}

class _DataFetchingPageState extends ConsumerState<DataFetchingPage> {
  DetectionStep _currentStep = DetectionStep.step1;
  UserType? _detectedUserType;

  @override
  void initState() {
    super.initState();
    _startDataFetching();
  }

  Future<void> _startDataFetching() async {
    final user = AuthService.currentUser;
    if (user == null) {
      // Should not happen, but handle gracefully
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
      return;
    }

    try {
      // Step 1: Detect user type (includes IP-API check)
      setState(() {
        _currentStep = DetectionStep.step1;
      });

      debugPrint('[DataFetching] Step 1: Starting user type detection...');
      _detectedUserType = await UserTypeDetectionService.detectUserType();
      debugPrint(
        '[DataFetching] Step 1: User type detected: ${_detectedUserType?.value}',
      );

      if (!mounted) return;

      // Map user type to layout type
      String layoutType;
      switch (_detectedUserType!) {
        case UserType.normal:
          layoutType = 'normal';
          break;
        case UserType.international:
          layoutType = 'international';
          break;
        case UserType.google:
          layoutType = 'google';
          break;
      }

      // Store layout type globally for use throughout the app session
      setLayoutType(layoutType);
      debugPrint('[DataFetching] Layout type determined: $layoutType');

      setState(() {
        _currentStep = DetectionStep.step2;
      });

      // Step 2: Fetch user data and initialize services
      debugPrint('[DataFetching] Step 2: Fetching user data...');
      final userData = await AuthService.fetchUserDataModel();

      setState(() {
        _currentStep = DetectionStep.step3;
      });

      // Step 3: Initialize offerwalls and other services
      debugPrint('[DataFetching] Step 3: Initializing services...');

      // Initialize offerwalls (Adjoe) with Firestore-backed keys
      try {
        if (userData != null) {
          await OfferwallManager.initAdjoe(
            user.uid,
            email: userData.email,
            gender: userData.gender,
            age: userData.age,
          );
        } else {
          await OfferwallManager.initAdjoe(user.uid);
        }
      } catch (_) {
        // Offerwall init failures are non-fatal; continue app startup.
        debugPrint('[DataFetching] Offerwall init failed, continuing...');
      }

      // Set Geemee user ID if SDK is initialized
      if (geemeeAppId.isNotEmpty) {
        try {
          await GeemeeFlutter.setUserId(userId: user.uid);
        } catch (e) {
          debugPrint('[DataFetching] Failed to set Geemee user ID: $e');
        }
      }

      // Authenticate with cloud function
      await CloudFunctions.authenticateUser();

      if (!mounted) return;

      setState(() {
        _currentStep = DetectionStep.completed;
      });

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } catch (e) {
      debugPrint('[DataFetching] Error during data fetching: $e');
      // On error, default to google layout and navigate
      if (mounted) {
        setLayoutType('google');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    }
  }

  double get _progress {
    switch (_currentStep) {
      case DetectionStep.step1:
        return 0.33; // 33%
      case DetectionStep.step2:
        return 0.66; // 66%
      case DetectionStep.step3:
        return 0.99; // 99% (almost complete)
      case DetectionStep.completed:
        return 1.0; // 100%
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 48),

              // App Name
              const Text(
                AppConstant.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 64),

              // Linear Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF3B82F6),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
