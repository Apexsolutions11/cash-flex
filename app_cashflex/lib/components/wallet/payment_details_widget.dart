import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cashflex/models/wallet/payment_details_model.dart';

Widget buildPaymentDetailsWidget(
  String methodName,
  PaymentDetails data,
  Color textColor,
  int size,
) {
  switch (methodName) {
    //! UPI
    case 'UPI':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPI ID: ${data.upiId}',
            style: TextStyle(
              color: textColor,
              fontSize: size.sp,
            ),
          ),
          Text(
            'Name: ${data.name}',
            style: TextStyle(
              color: textColor,
              fontSize: size.sp,
            ),
          ),
        ],
      );

    //! Google Play, gCash, Dana, Paypal
    case 'GOOGLE_PLAY':
    case 'GCASH':
    case 'DANA':
    case 'PAYPAL':
    case 'TOUCH_N_GO':
    case 'FLIPKART':
    case 'AMAZON':
      return Text(
        'Email: ${data.email}',
        style: TextStyle(
          color: textColor,
          fontSize: size.sp,
        ),
      );

    //! Bank Transfer
    case 'NEFT':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name: ${data.name}',
            style: TextStyle(
              color: textColor,
              fontSize: size.sp,
            ),
          ),
          Text(
            'Account No: ${data.accNo}',
            style: TextStyle(
              color: textColor,
              fontSize: size.sp,
            ),
          ),
          Text(
            'IFSC: ${data.ifsc}',
            style: TextStyle(
              color: textColor,
              fontSize: size.sp,
            ),
          ),
        ],
      );

    default:
      return const SizedBox.shrink();
  }
}
