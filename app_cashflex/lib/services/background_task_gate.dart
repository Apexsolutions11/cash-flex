import 'dart:async';
import 'package:flutter/material.dart';

/// A small helper that gates an action behind "stay in background for N seconds".
///
/// This is used for tasks like Follow/Review/MoreApps where the actual reward
/// is granted by the backend endpoints (not `claimCoins`, which has limits).
class BackgroundTaskGate {
  BackgroundTaskGate._();
  static final BackgroundTaskGate instance = BackgroundTaskGate._();

  DateTime? _backgroundStartTime;
  Timer? _checkTimer;
  bool _isTracking = false;
  int _minimumTime = 0;
  BuildContext? _context;
  Future<void> Function()? _onSuccess;
  VoidCallback? _onFailure;
  _GateLifecycleObserver? _observer;

  bool start({
    required int minimumBackgroundTime,
    required BuildContext context,
    required Future<void> Function() onSuccess,
    VoidCallback? onFailure,
  }) {
    if (_isTracking) return false;
    _isTracking = true;
    _minimumTime = minimumBackgroundTime < 0 ? 0 : minimumBackgroundTime;
    _context = context;
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _backgroundStartTime = null;

    _observer = _GateLifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_observer!);

    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAppState();
    });
    return true;
  }

  void stop() {
    _isTracking = false;
    _backgroundStartTime = null;
    _checkTimer?.cancel();
    _checkTimer = null;
    _minimumTime = 0;
    _context = null;
    _onSuccess = null;
    _onFailure = null;

    if (_observer != null) {
      WidgetsBinding.instance.removeObserver(_observer!);
      _observer = null;
    }
  }

  void _checkAppState() {
    if (!_isTracking) return;

    final s = WidgetsBinding.instance.lifecycleState;
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      _backgroundStartTime ??= DateTime.now();
    } else if (s == AppLifecycleState.resumed) {
      if (_backgroundStartTime != null) {
        _onResumed();
      }
    }
  }

  Future<void> _onResumed() async {
    if (!_isTracking || _backgroundStartTime == null) return;

    final seconds = DateTime.now().difference(_backgroundStartTime!).inSeconds;
    _backgroundStartTime = null;

    final ctx = _context;
    final onSuccess = _onSuccess;
    final onFailure = _onFailure;
    final min = _minimumTime;

    // Stop before running callbacks to avoid duplicates.
    stop();

    if (seconds >= min) {
      if (onSuccess != null) {
        await onSuccess();
      }
    } else {
      onFailure?.call();
      if (ctx != null && ctx.mounted) {
        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Task not completed'),
            content: const Text(
              'The task was not completed correctly. Please ensure that you fully complete all required actions in order to proceed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _GateLifecycleObserver extends WidgetsBindingObserver {
  final BackgroundTaskGate gate;
  _GateLifecycleObserver(this.gate);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    gate._checkAppState();
  }
}
