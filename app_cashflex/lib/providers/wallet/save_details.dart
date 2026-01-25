import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cashflex/models/wallet/payment_details_model.dart';
import 'package:cashflex/models/wallet/payment_method.dart';

import '../../../../../utils/helper/toast_manager.dart';

Future<void> saveDetails(
  BuildContext context,
  GlobalKey<FormState> paymentDetailsKey,
  String uid,
  PaymentMethod paymentMethod,
  TextEditingController nameCon,
  TextEditingController emailCon,
  TextEditingController upiCon,
  TextEditingController accCon,
  TextEditingController ifscCon,
) async {
  if (paymentDetailsKey.currentState!.validate()) {
    final Map<String, dynamic> details = PaymentDetails(
      email: emailCon.text.trim(),
      upiId: upiCon.text.trim(),
      name: nameCon.text.trim(),
      accNo: accCon.text.trim(),
      ifsc: ifscCon.text.trim(),
    ).toSnapshot(
      PaymentMethodEnum.values.firstWhere(
        (e) => e.name == paymentMethod.id,
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        paymentMethod.id: details,
      }, SetOptions(merge: true));
      ToastManager.success('Details saved successfully');
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ToastManager.error();
    }
  } else {
    ToastManager.warning(
      'Please correct the errors in the form.',
    );
  }
}