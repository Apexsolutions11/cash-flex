import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../utils/helper/helper.dart';

class WalletCatalog {
  final WalletCatalogData catalog;
  final List<Denomination> denominations;

  WalletCatalog({
    required this.catalog,
    required this.denominations,
  });
}

class WalletCatalogData {
  final String symbol;
  final String id;
  final double curFactor;
  final String? imageUrl;

  WalletCatalogData({
    required this.symbol,
    required this.id,
    required this.curFactor,
    this.imageUrl,
  });

  factory WalletCatalogData.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> data,
  ) {
    final map = data.data() ?? <String, dynamic>{};
    final symbolRaw = map['symbol']?.toString() ?? '';
    final imageUrl = (map['imageUrl'] as String?)?.trim();
    final num? cur = map['curFactor'] as num?;

    return WalletCatalogData(
      symbol: symbolRaw.parseSymbol(),
      id: data.id,
      curFactor: cur?.toDouble() ?? 0,
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
    );
  }
}

class Denomination {
  final bool enabled;
  final int coins;
  final int amount;
  final String id;
  final String? imageUrl;

  Denomination({
    required this.enabled,
    required this.coins,
    required this.amount,
    required this.id,
    this.imageUrl,
  });

  factory Denomination.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> data) =>
      Denomination(
        enabled: (data.data()?['enabled'] as bool?) ?? false,
        coins: (data.data()?['coins'] as num?)?.toInt() ?? 0,
        amount: (data.data()?['amount'] as num?)?.toInt() ?? 0,
        id: data.id,
        imageUrl: ((data.data()?['imageUrl'] as String?)?.trim().isNotEmpty ?? false)
            ? (data.data()?['imageUrl'] as String?)?.trim()
            : null,
      );
}