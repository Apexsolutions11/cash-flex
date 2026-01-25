import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/external_app_model.dart';

final externalApp1Provider = StreamProvider<ExternalAppModel>((ref) {
  return FirebaseFirestore.instance
      .collection('admin')
      .doc('app1')
      .snapshots()
      .map((doc) => ExternalAppModel.fromDocument(doc));
});

final externalApp2Provider = StreamProvider<ExternalAppModel>((ref) {
  return FirebaseFirestore.instance
      .collection('admin')
      .doc('app2')
      .snapshots()
      .map((doc) => ExternalAppModel.fromDocument(doc));
});

final externalApp3Provider = StreamProvider<ExternalAppModel>((ref) {
  return FirebaseFirestore.instance
      .collection('admin')
      .doc('app3')
      .snapshots()
      .map((doc) => ExternalAppModel.fromDocument(doc));
});

final externalApp4Provider = StreamProvider<ExternalAppModel>((ref) {
  return FirebaseFirestore.instance
      .collection('admin')
      .doc('app4')
      .snapshots()
      .map((doc) => ExternalAppModel.fromDocument(doc));
});

