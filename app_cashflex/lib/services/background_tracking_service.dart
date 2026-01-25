import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BackgroundTrackingService {
  BackgroundTrackingService._();
  
  static final BackgroundTrackingService instance = BackgroundTrackingService._();
  
  DateTime? _backgroundStartTime;
  Timer? _checkTimer;
  bool _isTracking = false;
  int? _minimumTime;
  int? _coinsToAward;
  String? _appTitle;
  VoidCallback? _onAwarded;
  BuildContext? _context;
  _AppLifecycleObserver? _observer;
  
  /// Start tracking background time for a promotion app
  /// Returns true if tracking started, false if already tracking
  bool startTracking({
    required int minimumBackgroundTime,
    required int coins,
    required String appTitle,
    required BuildContext context,
    VoidCallback? onAwarded,
  }) {
    if (_isTracking) {
      debugPrint('Background tracking already in progress');
      return false;
    }
    
    _minimumTime = minimumBackgroundTime;
    _coinsToAward = coins;
    _appTitle = appTitle;
    _onAwarded = onAwarded;
    _context = context;
    _isTracking = true;
    _backgroundStartTime = null;
    
    debugPrint('Started tracking background time for $appTitle (min: ${minimumBackgroundTime}s, coins: $coins)');
    
    // Listen to app lifecycle changes
    _observer = _AppLifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_observer!);
    
    // Also set up a periodic check as backup
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAppState();
    });
    
    return true;
  }
  
  /// Check app state periodically (backup method)
  void _checkAppState() {
    if (!_isTracking) return;
    
    final appLifecycleState = WidgetsBinding.instance.lifecycleState;
    
    if (appLifecycleState == AppLifecycleState.paused || 
        appLifecycleState == AppLifecycleState.inactive) {
      if (_backgroundStartTime == null) {
        _onAppPaused();
      }
    } else if (appLifecycleState == AppLifecycleState.resumed) {
      if (_backgroundStartTime != null) {
        _onAppResumed();
      }
    }
  }
  
  /// Stop tracking
  void stopTracking() {
    if (!_isTracking) return;
    
    _isTracking = false;
    _backgroundStartTime = null;
    _checkTimer?.cancel();
    _checkTimer = null;
    _minimumTime = null;
    _coinsToAward = null;
    _appTitle = null;
    _onAwarded = null;
    _context = null;
    
    // Remove observer
    if (_observer != null) {
      WidgetsBinding.instance.removeObserver(_observer!);
      _observer = null;
    }
    
    debugPrint('Stopped background tracking');
  }
  
  /// Called when app goes to background
  void _onAppPaused() {
    if (!_isTracking || _backgroundStartTime != null) return;
    
    _backgroundStartTime = DateTime.now();
    debugPrint('App went to background at $_backgroundStartTime');
  }
  
  /// Called when app comes to foreground
  void _onAppResumed() {
    if (!_isTracking || _backgroundStartTime == null) return;
    
    final backgroundDuration = DateTime.now().difference(_backgroundStartTime!);
    final backgroundSeconds = backgroundDuration.inSeconds;
    
    debugPrint('App resumed. Background time: ${backgroundSeconds}s (required: $_minimumTime s)');
    
    final minTime = _minimumTime ?? 0;
    final coins = _coinsToAward ?? 0;
    
    // Reset background start time
    _backgroundStartTime = null;
    
    // Check if requirement met
    if (backgroundSeconds >= minTime && coins > 0) {
      _awardCoins();
    } else {
      _showFailureDialog();
    }
  }
  
  /// Award coins to user
  Future<void> _awardCoins() async {
    if (_coinsToAward == null || _appTitle == null || _context == null) return;
    
    final coins = _coinsToAward!;
    final appTitle = _appTitle!;
    final onAwardedCallback = _onAwarded;
    final context = _context!;
    
    // Stop tracking before awarding to prevent duplicate awards
    stopTracking();
    
    try {
      debugPrint('Awarding $coins coins for $appTitle (background time requirement met)');
      await ApiService.claimCoins(coins, 'PROMOTION_APP_REWARD');
      
      // Show success dialog
      if (context.mounted) {
        _showSuccessDialog(context, coins, appTitle);
      }
      
      onAwardedCallback?.call();
    } catch (e) {
      debugPrint('Error awarding coins: $e');
      if (context.mounted) {
        _showErrorDialog(context);
      }
    }
  }
  
  /// Show success dialog
  void _showSuccessDialog(BuildContext context, int coins, String appTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Congratulations!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have successfully completed the required tasks and earned $coins coins!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Great!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show failure dialog
  void _showFailureDialog() {
    if (_context == null || !_context!.mounted) return;
    
    final context = _context!;
    
    stopTracking();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.info_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Task Not Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The required tasks are mandatory. Failing to complete them will not grant the reward. Please try again and ensure you complete all the tasks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show error dialog
  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to claim coins. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get current background time (if tracking)
  int? getCurrentBackgroundTime() {
    if (!_isTracking || _backgroundStartTime == null) return null;
    return DateTime.now().difference(_backgroundStartTime!).inSeconds;
  }
  
  bool get isTracking => _isTracking;
}

/// App lifecycle observer for tracking background time
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final BackgroundTrackingService _service;
  
  _AppLifecycleObserver(this._service);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _service._onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _service._onAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}

