import 'package:cloud_firestore/cloud_firestore.dart';

import 'payment_details_model.dart';

class BalancePaymentDetailsModel {
  final int balance;
  final PaymentDetails paymentDetails;
  final String country;

  BalancePaymentDetailsModel({
    required this.balance,
    required this.paymentDetails,
    required this.country,
  });

  factory BalancePaymentDetailsModel.fromSnapshot(
    DocumentSnapshot snapshot,
    String method,
  ) {
    final Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    PaymentMethodEnum paymentMethodEnum = PaymentMethodEnum.values.firstWhere(
      (e) => e.name == method,
      orElse: () => throw ArgumentError(
        'Unsupported PaymentMethodEnum: $method',
      ),
    );

    PaymentDetails paymentDetails = data.containsKey(method)
        ? PaymentDetails.fromSnapshot(
            data[method],
            paymentMethodEnum,
          )
        : PaymentDetails();

    return BalancePaymentDetailsModel(
      country: data['country'],
      balance: data['balance'],
      paymentDetails: paymentDetails,
    );
  }
}