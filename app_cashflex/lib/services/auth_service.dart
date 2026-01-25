import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_data_model.dart';
import '../services/local_storage.dart';
import '../services/referral_service.dart';
import '../services/device_detection_service.dart';
import '../utils/constant/constant.dart';
import 'cloud_functions.dart';
import 'package:geemee_flutter/geemee_flutter.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure we have a stable per-device identifier
      final String localDeviceId = await _getOrCreateDeviceId();

      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Save user data to Firestore (and enforce per-device limits)
      await _saveUserData(userCredential.user!, localDeviceId);
      
      // Set Geemee user ID if SDK is initialized
      if (geemeeAppId.isNotEmpty) {
        try {
          await GeemeeFlutter.setUserId(userId: userCredential.user!.uid);
        } catch (e) {
          debugPrint('Failed to set Geemee user ID: $e');
        }
      }
      
      // Authenticate user with cloud function
      await CloudFunctions.authenticateUser();
      
      return userCredential;
    } catch (e) {
      try {
        // Ensure we clean up any partial sign-in state
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (_) {
        // Ignore sign-out errors here
      }
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Save user data to Firestore
  static Future<void> _saveUserData(User user, String localDeviceId) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      // Extract all install referrer parameters
      Map<String, String> installReferrerParams = {};
      try {
        installReferrerParams = await ReferralService.extractAllTrackingParams();
        debugPrint('[AuthService] Extracted install referrer params: $installReferrerParams');
      } catch (e) {
        debugPrint('[AuthService] Error extracting install referrer params: $e');
      }

      if (!docSnapshot.exists) {
        // Enforce maximum accounts per device for NEW users only
        if (localDeviceId.isNotEmpty) {
          final existingForDevice = await _firestore
              .collection('users')
              .where('deviceId', isEqualTo: localDeviceId)
              .get();

          if (existingForDevice.docs.length >= maxAccountPerDevice) {
            throw Exception(
              'You have reached the maximum number of accounts allowed on this device.',
            );
          }
        }

        // Generate a unique referral code for this new user
        final String referralCode =
            await ReferralService.generateReferralCode();
        // New user - create document
        await userDoc.set({
          'userId': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'photo': user.photoURL ?? '',
          'joiningTimestamp': FieldValue.serverTimestamp(),
          'lastLoginTimestamp': FieldValue.serverTimestamp(),
          'deviceId': localDeviceId,
          'coins': 0,
          'balance': 0,
          'referralCount': 0,
          'dailyPayoutCount': 0,
          'totalPayoutCount': 0,
          'energy': 0,
          'dailyGameCount': 0,
          'referralCode': referralCode,
          'installReferrerParams': installReferrerParams.isNotEmpty ? installReferrerParams : null,
        });

        // Track referral / signup bonus based on install referrer
        await ReferralService.activateUserAccount(referralCode);

        // Post referral metadata to external analytics (best-effort)
        await ReferralService.saveReferralDetails(
          user.displayName ?? '',
          user.email ?? '',
          user.uid,
        );
      } else {
        // Existing user - update last login and basic info
        final existingData = docSnapshot.data() ?? {};
        String? referralCode = existingData['referralCode'] as String?;

        // Backfill referral code for legacy users that don't have one yet
        referralCode ??= await ReferralService.generateReferralCode();

        // Update install referrer params if not already set or if new params are available
        final existingParams = docSnapshot.data()?['installReferrerParams'] as Map<String, dynamic>?;
        final updateData = <String, dynamic>{
          'lastLoginTimestamp': FieldValue.serverTimestamp(),
          'name': user.displayName ?? docSnapshot.data()?['name'] ?? '',
          'photo': user.photoURL ?? docSnapshot.data()?['photo'] ?? '',
          if (localDeviceId.isNotEmpty)
            'deviceId': localDeviceId,
          'referralCode': referralCode,
        };
        
        // Only update install referrer params if they don't exist or if we have new params
        if (existingParams == null || existingParams.isEmpty) {
          if (installReferrerParams.isNotEmpty) {
            updateData['installReferrerParams'] = installReferrerParams;
          }
        }
        
        await userDoc.update(updateData);
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  /// Returns a stable, app-local identifier for this device/installation.
  /// This is **not** a hardware ID and is stored only in local storage.
  static Future<String> _getOrCreateDeviceId() async {
    // If already in memory, reuse it
    if (deviceId.isNotEmpty) {
      return deviceId;
    }

    // Try to read from local storage
    final stored = LocalStorage.getDeviceId();
    if (stored.isNotEmpty) {
      deviceId = stored;
      return stored;
    }

    // Generate a new pseudo-random ID and persist it
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 24; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    final newId = buffer.toString();

    deviceId = newId;
    await LocalStorage.setDeviceId(newId);
    return newId;
  }

  // Fetch user data from Firestore
  static Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  // Fetch user data as UserDataModel
  static Future<UserDataModel?> fetchUserDataModel() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = UserDataModel.dashboardSnapshot(userDoc);
        
        // Automatically detect and log googleUser reason after fetching
        // This runs asynchronously and doesn't block the return
        DeviceDetectionService.detectGoogleUserReason(userData).catchError((e) {
          debugPrint('Error detecting googleUser reason: $e');
          return null;
        });
        
        return userData;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data model: $e');
      return null;
    }
  }

  /// Ensures the currently logged-in user has a referral code.
  /// Returns the existing or newly generated referral code, or null if unavailable.
  static Future<String?> ensureReferralCodeForCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) return null;

      final data = docSnapshot.data() ?? {};
      final existing = data['referralCode'];

      if (existing is String && existing.isNotEmpty) {
        return existing;
      }

      // Generate and persist a new unique referral code
      final String referralCode = await ReferralService.generateReferralCode();

      await userDocRef.set(
        {
          'referralCode': referralCode,
        },
        SetOptions(merge: true),
      );

      return referralCode;
    } catch (e) {
      debugPrint('Error ensuring referral code: $e');
      return null;
    }
  }

  // Update user profile data
  static Future<void> updateUserProfile({
    String? name,
    String? gender,
    int? age,
    String? whatsappNo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = _firestore.collection('users').doc(user.uid);
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (gender != null) updateData['gender'] = gender;
      if (age != null) updateData['age'] = age;
      if (whatsappNo != null) updateData['whatsappNo'] = whatsappNo;

      if (updateData.isNotEmpty) {
        await userDoc.update(updateData);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}

