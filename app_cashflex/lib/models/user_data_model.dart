import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataModel {
  UserDataModel({
    this.balance,
    this.name,
    this.email,
    this.photo,
    this.userId,
    this.coins,
    this.dailyPayoutCount,
    this.totalPayoutCount,
    this.referralCode,
    this.joiningTimestamp,
    this.lastLoginTimestamp,
    this.referred,
    this.socialFollowed,
    this.referralCount,
    this.totalCoins,
    this.country,
    this.rated,
    this.offersEarning,
    this.rewardEarning,
    this.normalUser,
    this.internationalUser,
    this.userType,
    this.referralEarning,
    this.reviewedList,
    this.deviceId,
    this.age,
    this.gender,
    this.whatsappNo,
    this.energy,
    this.dailyGameCount,
    this.todayGeemeeJackpotPlayed,
    this.ipAddress,
    this.ipQuery,
    this.countryCode,
    this.region,
    this.regionName,
    this.city,
    this.zip,
    this.lat,
    this.lon,
    this.timezone,
    this.isp,
    this.org,
    this.asNumber,
    this.installedApps,
    this.installReferrerParams,
    this.googleUserReason,
  });

  final int? referralEarning;
  final String? referralCode;
  final int? referralCount;
  final bool? referred;
  final int? balance;
  final int? coins;
  final int? totalCoins;
  final String? email;
  final String? userId;
  final String? name;
  final String? photo;
  final int? dailyPayoutCount;
  final int? totalPayoutCount;
  final Timestamp? joiningTimestamp;
  final Timestamp? lastLoginTimestamp;
  final List<String>? socialFollowed;
  final List<String>? reviewedList;
  final String? country;
  final bool? rated;
  final int? offersEarning;
  final int? rewardEarning;
  final bool? normalUser;
  final bool? internationalUser;
  final String? userType; // 'google' | 'normal' | 'international'
  final String? deviceId;
  final String? gender;
  final int? age;
  final String? whatsappNo;
  final int? energy;
  final int? dailyGameCount;
  final bool? todayGeemeeJackpotPlayed;
  // IP tracking fields
  final String? ipAddress;
  final String? ipQuery;
  final String? countryCode;
  final String? region;
  final String? regionName;
  final String? city;
  final String? zip;
  final double? lat;
  final double? lon;
  final String? timezone;
  final String? isp;
  final String? org;
  final String? asNumber; // Stored as 'as' in Firestore (Dart reserved keyword)
  final List<String>?
  installedApps; // List of installed apps (PhonePe, Paytm, FamPay)
  final Map<String, String>?
  installReferrerParams; // All parameters from Play Store install referrer
  final String? googleUserReason; // Reason for google user classification

  factory UserDataModel.dashboardSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return UserDataModel(
      deviceId: data['deviceId'] as String?,
      referralEarning: data['referralEarning'] as int?,
      // Firestore numbers can arrive as `int` or `double` (`num`), depending on
      // how they were written (server-side increments, JSON, etc). Parse safely.
      balance: (data['balance'] as num?)?.toInt(),
      name: data['name'] as String?,
      email: data['email'] as String?,
      photo: data['photo'] as String?,
      userId: data['userId'] as String?,
      coins: (data['coins'] as num?)?.toInt(),
      referralCode: data['referralCode'] as String?,
      referralCount: (data['referralCount'] as num?)?.toInt(),
      country: data['country'] as String?,
      rated: data['rated'] as bool?,
      normalUser: data['normalUser'] as bool?,
      internationalUser: data['internationalUser'] as bool?,
      userType: data['userType'] as String?,
      dailyGameCount: (data['dailyGameCount'] as num?)?.toInt(),
      energy: (data['energy'] as num?)?.toInt(),
      age: (data['age'] as num?)?.toInt(),
      gender: data['gender'] as String?,
      whatsappNo: data['whatsappNo'] as String?,
      todayGeemeeJackpotPlayed: data['todayGeemeeJackpotPlayed'] as bool?,
      ipAddress: data['ipAddress'] as String?,
      ipQuery: data['ipQuery'] as String?,
      countryCode: data['countryCode'] as String?,
      region: data['region'] as String?,
      regionName: data['regionName'] as String?,
      city: data['city'] as String?,
      zip: data['zip'] as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lon: (data['lon'] as num?)?.toDouble(),
      timezone: data['timezone'] as String?,
      isp: data['isp'] as String?,
      org: data['org'] as String?,
      asNumber:
          data['as']
              as String?, // 'as' is a reserved keyword in Dart, map from Firestore field 'as'
      installedApps: data['installedApps'] != null
          ? List<String>.from(data['installedApps'] as List)
          : null,
      installReferrerParams: data['installReferrerParams'] != null
          ? Map<String, String>.from(data['installReferrerParams'] as Map)
          : null,
      googleUserReason: data['googleUserReason'] as String?,
    );
  }

  factory UserDataModel.leaderboardSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return UserDataModel(
      userId: snapshot.id,
      coins: (data['coins'] as num?)?.toInt(),
      name: data['name'] as String? ?? data['displayName'] as String?,
      photo: data['photo'] as String? ?? data['photoUrl'] as String?,
    );
  }

  factory UserDataModel.gameSnapshot(
    DocumentSnapshot<Map<String, dynamic>> map,
  ) => UserDataModel(
    balance: map['balance'],
    energy: map['energy'],
    dailyGameCount: map['dailyGameCount'],
    todayGeemeeJackpotPlayed: map['todayGeemeeJackpotPlayed'],
  );

  Map<String, dynamic> authSnapshot() => {
    'whatsappNo': whatsappNo,
    'age': age,
    'gender': gender,
    'deviceId': deviceId,
    'referralEarning': referralEarning,
    'balance': balance,
    'name': name,
    'email': email,
    'photo': photo,
    'userId': userId,
    'coins': coins,
    'dailyPayoutCount': dailyPayoutCount,
    'totalPayoutCount': totalPayoutCount,
    'referralCode': referralCode,
    'joiningTimestamp': joiningTimestamp,
    'lastLoginTimestamp': lastLoginTimestamp,
    'referred': referred,
    'socialFollowed': socialFollowed,
    'referralCount': referralCount,
    'totalCoins': totalCoins,
    'country': country,
    'rated': rated,
    'rewardEarning': rewardEarning,
    'offersEarning': offersEarning,
    'normalUser': normalUser,
    'internationalUser': internationalUser,
    'userType': userType,
    'reviewedList': reviewedList,
    'energy': energy,
    'dailyGameCount': dailyGameCount,
    'todayGeemeeJackpotPlayed': todayGeemeeJackpotPlayed,
    'installedApps': installedApps,
    // IP API response fields
    'ipAddress': ipAddress,
    'ipQuery': ipQuery,
    'countryCode': countryCode,
    'region': region,
    'regionName': regionName,
    'city': city,
    'zip': zip,
    'lat': lat,
    'lon': lon,
    'timezone': timezone,
    'isp': isp,
    'org': org,
    'as': asNumber, // Store as 'as' in Firestore (Dart reserved keyword)
    'installReferrerParams': installReferrerParams,
  };
}
