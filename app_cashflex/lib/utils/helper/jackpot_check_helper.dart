import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashflex/services/auth_service.dart';
import '../../utils/constant/constant.dart';
import '../../components/common/gemee_jackpot_dialog.dart';
import '../../services/jackpot_service.dart';
import '../../providers/layout_provider.dart';

/// Helper class to check if user needs to play jackpot before proceeding
class JackpotCheckHelper {
  /// Check if user needs to play jackpot. Returns true if check passed (can proceed), false if blocked.
  /// If forceUserToPlayJackpot is enabled and user hasn't played today, shows dialog.
  /// When jackpot is required, this will ONLY show the Geemee offerwall and block
  /// the original action on this tap. The user must tap again after playing.
  static Future<bool> checkAndShowDialogIfNeeded(
    BuildContext context, {
    String? dialogTitle,
    String? dialogMessage,
  }) async {
    // If force play is disabled, always allow
    if (!forceUserToPlayJackpot) {
      return true;
    }

    // FAST CHECK FIRST: If user has already played today (tracked locally), allow immediately
    // This is a fast local storage read, so check it before any slow operations
    final alreadyPlayed = await JackpotService.hasPlayedJackpotToday(
      userId: AuthService.currentUser?.uid,
    );
    if (alreadyPlayed || AuthService.currentUser?.uid == null) {
      return true;
    }

    // Check layout type from provider (determined on splash screen, no recalculation)
    // If current layout is Google layout, do not force jackpot
    try {
      final container = ProviderScope.containerOf(context);
      final layoutType = container.read(layoutTypeProvider);
      if (layoutType == 'google') {
        return true;
      }
    } catch (_) {
      // On any error reading layout from provider, fall back to normal jackpot logic
    }

    // User needs to play - show dialog (launches Geemee offerwall)
    await GemeeJackpotDialog.show(
      context,
      title: dialogTitle,
      message: dialogMessage,
      barrierDismissible: false,
    );

    // IMPORTANT: Always block the original action on this tap.
    // After a successful play, the local flag is set, so the *next* tap
    // will skip the dialog and allow the action.
    return false;
  }

  /// Legacy helper (no longer used).
  /// Kept for backward compatibility; Firestore checks are done in
  /// [checkAndShowDialogIfNeeded].
  static bool canProceedWithoutDialog() {
    // If force play is disabled, always allow
    if (!forceUserToPlayJackpot) {
      return true;
    }
    // When force play is enabled, we rely on the async helper instead.
    return true;
  }
}
