import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashflex/models/wallet/balance_payment_detail_model.dart';
import 'package:cashflex/models/wallet/payment_details_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef BalancePaymentDetailsParams = ({String uid, String method});

final balancePaymentDetailsProvider =
    StreamProvider.family<BalancePaymentDetailsModel, BalancePaymentDetailsParams>(
  (ref, params) => FirebaseFirestore.instance
      .collection('users')
      .doc(params.uid)
      // Including metadata changes helps ensure we get an initial event from cache quickly,
      // even on slower networks (prevents spurious TimeoutException: "No stream event").
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) {
          try {
            final String method = params.method;

            // If user doc doesn't exist or has no data yet, return a safe default model.
            final data = snapshot.data();
            if (!snapshot.exists || data == null) {
              return BalancePaymentDetailsModel(
                balance: 0,
                paymentDetails: PaymentDetails(),
                country: '',
              );
            }

            // Balance & country are always safe to default.
            // Firestore might store numbers as int or double, so handle num.
            final int balance = (data['balance'] as num?)?.toInt() ?? 0;
            final String country = (data['country'] as String?) ?? '';

            // Parse payment details only if method matches our enum; otherwise keep empty.
            PaymentDetails details = PaymentDetails();
            try {
              final methodEnum = PaymentMethodEnum.values.firstWhere(
                (e) => e.name == method,
                orElse: () => throw ArgumentError('Unsupported method: $method'),
              );
              if (data.containsKey(method) && data[method] is Map<String, dynamic>) {
                details = PaymentDetails.fromSnapshot(
                  Map<String, dynamic>.from(data[method] as Map),
                  methodEnum,
                );
              }
            } catch (_) {
              // Unsupported method or malformed data → keep empty details.
            }

            return BalancePaymentDetailsModel(
              balance: balance,
              paymentDetails: details,
              country: country,
            );
          } catch (e) {
            // Surface a readable error to the UI.
            throw Exception('Failed to parse balance/payment details: $e');
          }
        },
      ),
);