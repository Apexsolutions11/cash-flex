import 'package:flutter/material.dart';
import 'package:cashflex/components/wallet/alert_popup.dart';
import 'package:cashflex/models/wallet/wallet_catalog_model.dart';

import '../../../../../services/api_service.dart';


Future<void> handlePaymentRequest(
  BuildContext context,
  int? selectedIndex,
  int balance,
  WalletCatalog catalog,
  int leaderboardTimeLeft,
) async {
  if (selectedIndex == null) {
    showPaymentAlertPopup(
      context,
      'Alert',
      'Please select a voucher first',
    );
    return;
  }

  final selectedDenomination = catalog.denominations[selectedIndex];

  if (balance < selectedDenomination.coins) {
    showPaymentAlertPopup(
      context,
      'Insufficient coins',
      'You need ${selectedDenomination.coins - balance} more coins to redeem this reward.',
    );
    return;
  }

  try {
    final String res = await ApiService.requestPayout(
      selectedDenomination.id,
      leaderboardTimeLeft,
    );

    if (!context.mounted) return;

    if (res == 'success') {
      showPaymentAlertPopup(
        context,
        'Withdrawal Requested',
        'Your request has been submitted successfully. You will receive the payment within 5 to 30 minutes.',
      );
    } else {
      showPaymentAlertPopup(
        context,
        'Failed to place order',
        res,
      );
    }
  } catch (e) {
    showPaymentAlertPopup(
      context,
      'Error',
      'Something went wrong. Please try again later.',
    );
  }
}