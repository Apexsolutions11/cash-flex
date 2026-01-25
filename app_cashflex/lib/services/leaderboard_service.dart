import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data_model.dart';

class LeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch leaderboard data from Firestore
  static Future<List<UserDataModel>> fetchLeaderboardData({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('coins', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserDataModel.leaderboardSnapshot(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get leaderboard stream for real-time updates
  static Stream<List<UserDataModel>> getLeaderboardStream({int limit = 50}) {
    return _firestore
        .collection('users')
        .orderBy('coins', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserDataModel.leaderboardSnapshot(doc))
            .toList());
  }
}

