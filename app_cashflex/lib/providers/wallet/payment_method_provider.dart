import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashflex/models/wallet/payment_method.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';



final paymentMethodProvider =
    FutureProvider.family<List<PaymentMethod>, String>(
  (ref, country) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('walletCatalog')
        .where('enabled', isEqualTo: true)
        .snapshots()
        .first
        .timeout(const Duration(seconds: 8));

    final filteredDocs = querySnapshot.docs.where((doc) {
      // Excluded countries
      final exCountries = (doc.data()['ex_country'] as List<dynamic>?) ?? const [];
      if (exCountries.contains(country)) return false;

      return true;
    }).toList();

    return filteredDocs
        .map((doc) => PaymentMethod.fromDocument(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ))
        .toList();
  },
);