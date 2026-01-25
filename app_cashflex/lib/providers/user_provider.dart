import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/user_data_model.dart';

/// Stream of the current user's `UserDataModel`.
/// Automatically updates all listening UIs when the Firestore document changes.
final currentUserProvider = StreamProvider<UserDataModel?>((ref) {
  final usersCol = FirebaseFirestore.instance.collection('users');

  // IMPORTANT:
  // Do NOT use `FirebaseAuth.instance.currentUser` once at provider creation time.
  // It can be null during app startup or before auth finishes initializing, which
  // would previously return an empty stream and keep the UI stuck in "loading".
  //
  // Using `authStateChanges()` ensures we always emit (at least) a `null` user,
  // and automatically switch to the user's Firestore document stream after sign-in.
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) {
      // Emit a value so Riverpod resolves the loading state.
      return Stream.value(null);
    }

    return usersCol.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserDataModel.dashboardSnapshot(doc);
    });
  });
});


