// This file is deprecated. Use ApiService instead.
// Keeping for backward compatibility - redirecting to ApiService
import 'api_service.dart' as api;

class CloudFunctions {
  // Redirect all calls to ApiService for backward compatibility
  static Future<Map<String, dynamic>> getServerTime() async =>
      await api.ApiService.getServerTime();

  static Future<void> setReferral(String referralCode) async =>
      await api.ApiService.setReferral(referralCode);

  static Future<String> requestPayout(
    String id,
    int leaderboardTimeLeft,
  ) async =>
      await api.ApiService.requestPayout(id, leaderboardTimeLeft);

  static Future<Map<String, dynamic>> followReward(String tag) async =>
      await api.ApiService.followReward(tag);

  static Future<bool> authenticateUser() async =>
      await api.ApiService.authenticateUser();

  static Future<Map<String, dynamic>> ratingReward() async =>
      await api.ApiService.ratingReward();

  static Future<void> creditSignupBonus() async =>
      await api.ApiService.creditSignupBonus();

  static Future<Map<String, dynamic>> reviewTaskReward(String name) async =>
      await api.ApiService.reviewTaskReward(name);

  static Future<void> claimEnergy() async =>
      await api.ApiService.claimEnergy();

  static Future<void> claimCoins(int coins, String title) async =>
      await api.ApiService.claimCoins(coins, title);
}
