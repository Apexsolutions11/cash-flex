import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cashflex/models/wallet/wallet_catalog_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


final walletCatalogProvider = FutureProvider.family<WalletCatalog, String>(
  (ref, method) async {
    final DocumentReference<Map<String, dynamic>> doc =
        FirebaseFirestore.instance.collection('walletCatalog').doc(method);

    final sw = Stopwatch()..start();
    debugPrint('[WalletCatalog] Start fetch: method=$method');

    try {
      // Use snapshots().first to avoid indefinite hangs on poor connectivity.
      // Add a timeout so the UI can surface an error + retry instead of spinning forever.
      debugPrint('[WalletCatalog] Fetch catalog doc... method=$method');
      final docSnap =
          await doc.snapshots().first.timeout(const Duration(seconds: 8));
      debugPrint(
        '[WalletCatalog] Catalog doc received: method=$method exists=${docSnap.exists} in ${sw.elapsedMilliseconds}ms',
      );
      if (!docSnap.exists) {
        throw Exception('Payment method not found');
      }

      final catalogData = WalletCatalogData.fromSnapshot(docSnap);

      debugPrint('[WalletCatalog] Fetch denominations... method=$method');
      final denomSnap = await doc
          .collection('denominations')
          .snapshots()
          .first
          .timeout(const Duration(seconds: 8));

      final denominations =
          denomSnap.docs.map((e) => Denomination.fromSnapshot(e)).toList();
      debugPrint(
        '[WalletCatalog] Denominations received: method=$method count=${denominations.length} in ${sw.elapsedMilliseconds}ms',
      );

    denominations.sort(
      (a, b) => a.amount.compareTo(b.amount),
    );

    return WalletCatalog(
      catalog: catalogData,
      denominations: denominations,
    );
    } catch (e, st) {
      debugPrint(
        '[WalletCatalog] ERROR: method=$method after ${sw.elapsedMilliseconds}ms\n$e\n$st',
      );
      rethrow;
    } finally {
      sw.stop();
    }
  },
);