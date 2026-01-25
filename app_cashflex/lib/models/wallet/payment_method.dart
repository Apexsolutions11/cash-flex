import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String title;
  final String? imageUrl;

  PaymentMethod({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  factory PaymentMethod.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? <String, dynamic>{};

    final title = (map['title'] as String?) ?? '';
    final imageUrl = (map['imageUrl'] as String?)?.trim();

    return PaymentMethod(
      id: doc.id,
      title: title,
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
    );
  }
}