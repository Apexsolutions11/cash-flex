import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../utils/helper/helper.dart';
import 'payment_details_model.dart';

class EarningHistoryModel {
  final String provider;
  final int rewardAmount;
  final Timestamp timestamp;
  final String? orderId;

  EarningHistoryModel({
    required this.provider,
    required this.rewardAmount,
    required this.timestamp,
    this.orderId,
  });

  factory EarningHistoryModel.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> data,
  ) =>
      EarningHistoryModel(
        provider: data['provider'],
        rewardAmount: data['rewardAmount'],
        timestamp: data['timestamp'],
        orderId: data['orderId'] as String?,
      );
}

class WithdrawalHistoryModel {
  final int amount;
  final int coins;
  final String orderId;
  final String status;
  final String symbol;
  final Timestamp timestamp;
  final int timestampMs;
  final String paymentMethod;
  final PaymentDetails methodDetails;

  WithdrawalHistoryModel({
    required this.amount,
    required this.coins,
    required this.orderId,
    required this.status,
    required this.symbol,
    required this.timestamp,
    required this.timestampMs,
    required this.paymentMethod,
    required this.methodDetails,
  });

  factory WithdrawalHistoryModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    PaymentMethodEnum? paymentMethodEnum;
    PaymentDetails? methodDetails;

    for (String key in data.keys) {
      if (PaymentMethodEnum.values.any((e) => e.name == key)) {
        paymentMethodEnum = PaymentMethodEnum.values.firstWhere(
          (e) => e.name == key,
        );
        methodDetails = PaymentDetails.fromSnapshot(
          data[key],
          paymentMethodEnum,
        );
        break;
      }
    }

    if (paymentMethodEnum == null || methodDetails == null) {
      throw Exception('Unknown payment method');
    }

    return WithdrawalHistoryModel(
      amount: data['amount'],
      coins: data['coins'],
      orderId: data['orderId'],
      status: data['status'],
      symbol: data['symbol'].toString().parseSymbol(),
      timestamp: data['timestamp'],
      timestampMs: data['timestampMs'],
      paymentMethod: paymentMethodEnum.name,
      methodDetails: methodDetails,
    );
  }
}