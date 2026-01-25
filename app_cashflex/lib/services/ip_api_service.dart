import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constant/constant.dart';

/// Model for IP API response
class IpApiResponse {
  final String? ip;
  final String? country;
  final String? countryCode;
  final String? isp;
  final String? org;
  final String? region;
  final String? regionName;
  final String? city;
  final String? zip;
  final double? lat;
  final double? lon;
  final String? timezone;
  final String? asNumber;
  final String? query;
  final String? status;

  IpApiResponse({
    this.ip,
    this.country,
    this.countryCode,
    this.isp,
    this.org,
    this.region,
    this.regionName,
    this.city,
    this.zip,
    this.lat,
    this.lon,
    this.timezone,
    this.asNumber,
    this.query,
    this.status,
  });

  factory IpApiResponse.fromJson(Map<String, dynamic> json) {
    return IpApiResponse(
      ip: json['query'] as String? ?? json['ip'] as String?,
      country: json['country'] as String?,
      countryCode: json['countryCode'] as String?,
      isp: json['isp'] as String?,
      org: json['org'] as String?,
      region: json['region'] as String?,
      regionName: json['regionName'] as String?,
      city: json['city'] as String?,
      zip: json['zip'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      timezone: json['timezone'] as String?,
      asNumber: json['as'] as String?,
      query: json['query'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'query': query,
      'country': country,
      'countryCode': countryCode,
      'isp': isp,
      'org': org,
      'region': region,
      'regionName': regionName,
      'city': city,
      'zip': zip,
      'lat': lat,
      'lon': lon,
      'timezone': timezone,
      'as': asNumber,
      'status': status,
    };
  }
}

/// Service to interact with IP-API
class IpApiService {
  IpApiService._();

  /// Get user's IP address first, then fetch details
  static Future<String?> _getUserIpAddress() async {
    try {
      // First, get IP address using a simple IP detection service
      final dio = Dio();
      final ipResponse = await dio.get(
        'https://api.ipify.org?format=json',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (ipResponse.statusCode == 200 && ipResponse.data != null) {
        final data = ipResponse.data as Map<String, dynamic>;
        return data['ip'] as String?;
      }
    } catch (e) {
      debugPrint('[IP-API] Error getting user IP address: $e');
    }
    return null;
  }

  /// Fetch IP details from IP-API
  static Future<IpApiResponse?> fetchIpDetails() async {
    try {
      // Get user's IP address first
      final userIp = await _getUserIpAddress();
      if (userIp == null || userIp.isEmpty) {
        debugPrint('[IP-API] Could not determine user IP address');
        return null;
      }

      // Build URL dynamically: {baseUrl}/{ip}?key={apiKey}
      final url = '$ipApiBaseUrl$userIp?key=$ipApiKey';
      debugPrint('[IP-API] Fetching from URL: $url');

      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['status'] == 'success' || data['status'] == null) {
          final ipResponse = IpApiResponse.fromJson(data);
          debugPrint('[IP-API] Successfully fetched IP details: ${ipResponse.ip}');
          return ipResponse;
        } else {
          debugPrint('[IP-API] API returned non-success status: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('[IP-API] Invalid response: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[IP-API] Error fetching IP details: $e');
      return null;
    }
  }

  /// Check if "google" appears anywhere in the IP API response (case-insensitive)
  static bool containsGoogle(IpApiResponse? ipResponse) {
    if (ipResponse == null) return false;

    // Convert entire response to JSON string and check for "google" (case-insensitive)
    try {
      final jsonString = ipResponse.toJson().toString().toLowerCase();
      final containsGoogle = jsonString.contains('google');
      
      debugPrint('[IP-API] Checking for "google" in entire response: $containsGoogle');
      if (containsGoogle) {
        debugPrint('[IP-API] Google found in response: ${ipResponse.toJson()}');
      }
      
      return containsGoogle;
    } catch (e) {
      debugPrint('[IP-API] Error checking for Google in response: $e');
      return false;
    }
  }
}

