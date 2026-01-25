int maxAccountPerDevice = 2;

String deviceId = '';

bool updateAvailable = false;

bool reviewEnabled = false;

String chatbot = '';

bool validUser = false;

bool isEmulator = false;

// Feature flags
bool moreAppsEnabled = true;
bool followUsTasksEnabled = true;
bool reviewTasksEnabled = true;

// Layout flags
bool normalLayoutEnabled = false;
bool internationalLayoutEnabled = false;

// Force layout flags (bypasses all detection logic)
bool forceNormalLayout = false;
bool forceGoogleLayout = false;
bool forceInternationalLayout = false;

//! Mintegral
String mintegralAppId = '';
String mintegralAppKey = '';
String mintegralInterstitialPlacementId = '';
String mintegralInterstitialUnitId = '';

String adjoeHash = '';
String tenjinSdkKey = '';

//! Geemee
String geemeeAppId = '';
String geemeeOfferwallPlacementId = '';

// How to Earn (optional YouTube video URL shown on top of the page)
String howToEarnYoutubeUrl = '';

// Contact Us (mailto link). Default comes from AppConstant.contactUs but can be overridden by admin/appData.
String contactUsMailto = AppConstant.contactUs;

// Privacy Policy URL. Default comes from AppConstant.privacyPolicy but can be overridden by admin/appData.
String privacyPolicyUrl = AppConstant.privacyPolicy;

// Coin conversion rates (admin/appData)
//
// These represent "coins per 1 unit" of currency:
// - India: coins per ₹1 (INR)
// - Foreign: coins per $1 (USD)
//
// If 0, the app will hide the conversion-rate hint in the Redeem UI.
int indiaCoinCurFactor = 0;
int foreignCoinCurFactor = 0;

// Redeem page notice/warning (admin/appData)
// If empty, no notice will be displayed on the Redeem page.
String redeemNotice = '';

// Global task defaults + instruction templates (admin/appData)
int followTaskDefaultCoins = 10;
int followTaskMinBackgroundTime = 30;
String followTaskInstructions = '';

int reviewTaskDefaultCoins = 150;
int reviewTaskMinBackgroundTime = 60;
String reviewTaskInstructions = '';

// If 0, use per-app coins from `moreApps` docs.
int moreAppsDefaultCoins = 0;
int moreAppsMinBackgroundTime = 120;
String moreAppsInstructions = '';

int rateUsCoins = 50;
String rateUsCardText = '';
String rateUsDialogText = '';

// Daily game limit (admin/appData)
// Maximum number of games a user can play per day
int dailyGameLimit = 10;

// Geemee offerwall reward coins (admin/appData)
// Coins awarded when user successfully views Geemee offerwall from Jackpot card
int geemeeOfferwallRewardCoins = 10;

// Referral signup bonus coins (admin/appData)
// Coins awarded to the referrer when a friend signs up using their referral code
int referralSignupBonusCoins = 100;

// Force user to play jackpot (admin/appData)
// If enabled, users must play the Lucky Jackpot before accessing home components and redeeming coins
bool forceUserToPlayJackpot = false;


// IP API Configuration (admin/appData)
String ipApiBaseUrl = AppConstant.ipApiBaseUrl;
String ipApiKey = AppConstant.ipApiKey;

String appName = '';
String packageName = '';

String playstoreLink =
    'https://play.google.com/store/apps/details?id=$packageName';

String inviteText =
    '🚀 Ready to turn tasks into treasures? Join $appName now on Google Play! 🎉 Complete exciting challenges, earn epic rewards, and start your journey to success today! 💎📲 #$appName #RewardYourWay';

mixin AppConstant {
  static const String appName = 'Cash Flex';
  // IP API configuration (can be overridden from admin/appData)
  static const String ipApiBaseUrl = 'https://pro.ip-api.com/json/';
  static const String ipApiKey = 'CSkfd5JdFbyfF8V';
  static String ipApiUrl =
      'https://pro.ip-api.com/json?key=CSkfd5JdFbyfF8V'; // Legacy fallback

  static const String hostUrl = 'https://www.adzeagle.com/';

  static const String backendApiUrl = 'https://cashflex.adzrewards.com/api';

  static const String hostAppUrl = 'https://www.adzeagle.com/cashflex/';

  static const String contactUs = 'mailto:team.cashsamurai@gmail.com';

  static const String fetchPromoApps =
      'https://server.adzeagle.com/api/universal/all-apps';

  static const String referralUrl =
      'https://analytics.adzeagle.com/api/v1/init-user/';

  static const String quizWhizUrl = 'https://quizwhiz.vercel.app/game.html';

  static const String apayQuizUrl = 'https://play518.apayquizzes.com/start';

  static const String privacyPolicy =
      'https://sites.google.com/view/grab-reward1/home';
}
