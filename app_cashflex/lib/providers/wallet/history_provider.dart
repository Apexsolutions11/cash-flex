import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashflex/models/wallet/history_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashflex/utils/helper/toast_manager.dart';
import 'package:flutter/material.dart';

final FirebaseFirestore _firebase = FirebaseFirestore.instance;

// Track seen orderIds per userId to detect new rewards
final Map<String, Set<String>> _seenOrderIds = {};
final Map<String, bool> _isInitialLoad = {};

final withdrawalHistoryProvider =
    StreamProvider.family<List<WithdrawalHistoryModel>, String>(
      (ref, String uid) => _firebase
          .collection('users')
          .doc(uid)
          .collection('transactionHistory')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => WithdrawalHistoryModel.fromSnapshot(doc))
                .toList(),
          ),
    );

final earningHistoryProvider = StreamProvider.family<List<EarningHistoryModel>, String>((
  ref,
  String uid,
) {
  // Initialize tracking for this user
  if (!_seenOrderIds.containsKey(uid)) {
    _seenOrderIds[uid] = {};
    _isInitialLoad[uid] = true;
  }

  return _firebase
      .collection('users')
      .doc(uid)
      .collection('rewardHistory')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        final earnings = snapshot.docs
            .map((doc) => EarningHistoryModel.fromSnapshot(doc))
            .toList();

        // Show toast for new rewards
        if (earnings.isNotEmpty) {
          // On initial load, mark all existing rewards as seen
          if (_isInitialLoad[uid] == true) {
            for (final earning in earnings) {
              final identifier =
                  earning.orderId ??
                  '${earning.timestamp.seconds}_${earning.provider}_${earning.rewardAmount}';
              _seenOrderIds[uid]!.add(identifier);
            }
            _isInitialLoad[uid] = false;
          } else {
            // Check for new rewards
            for (final earning in earnings) {
              final identifier =
                  earning.orderId ??
                  '${earning.timestamp.seconds}_${earning.provider}_${earning.rewardAmount}';

              if (!_seenOrderIds[uid]!.contains(identifier)) {
                // New reward detected - show toast
                // Use postFrameCallback to ensure toast is shown outside of stream processing
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ToastManager.success(
                    '🎉 You earned ${earning.rewardAmount} coins from ${earning.provider}!',
                  );
                });
                _seenOrderIds[uid]!.add(identifier);
                // Only show toast for the first new reward found
                break;
              }
            }
          }
        }

        return earnings;
      });
});
