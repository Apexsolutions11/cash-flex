import axios from 'axios';
import { db, admin } from '../firebase-admin';
import * as constant from '../constants';
import * as other from './other-service';
import { getSettings } from './settings-helper';

export const trackIp = async (
  ipAddress: string,
  userId: string,
  country: string,
  email: string,
  options?: {
    referralId?: string;
    gclid?: string;
    fbclid?: string;
    trackingParams?: Record<string, string>;
    hasLocalApps?: boolean;
    isVpn?: boolean;
    isEmulator?: boolean;
    installedApps?: string[];
  },
) => {
  const userDbRef = db.collection('users').doc(userId);

  const userData: {
    ipAddress: string;
    country?: string; // Make optional to avoid overwriting with empty string
    lastLoginTimestamp: FirebaseFirestore.FieldValue;
    normalUser?: boolean; // Legacy field, kept for backward compatibility
    internationalUser?: boolean; // Legacy field, kept for backward compatibility
    userType?: 'google' | 'normal' | 'international'; // New consolidated user type field
    googleUserReason?: string; // Reason for google user classification
    // IP API tracking fields
    ipQuery?: string;
    countryCode?: string;
    region?: string;
    regionName?: string;
    city?: string;
    zip?: string;
    lat?: number;
    lon?: number;
    timezone?: string;
    isp?: string;
    org?: string;
    as?: string;
    installedApps?: string[];
  } = {
    ipAddress,
    // Only set country if we have a valid value (don't initialize with empty string)
    ...(country && country.trim().length > 0 && { country }),
    lastLoginTimestamp: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Track the reason for googleUser classification
  let googleUserReason: string | null = null;
  let userType: 'google' | 'normal' | 'international' = 'google'; // Default to google

  // Priority 0: Check for admin-defined tracking parameters - mark as normalUser
  // This is the highest priority check for scalable parameter detection
  let hasAdminDefinedParam = false;
  if (options?.trackingParams && Object.keys(options.trackingParams).length > 0) {
    try {
      // Fetch appData from Firestore to get admin-defined tracking parameters
      const appDataDoc = await db.collection('admin').doc('appData').get();
      const appData = appDataDoc.exists ? (appDataDoc.data() || {}) : {};
      const adminParams = Array.isArray(appData.normalUserTrackingParams) 
        ? appData.normalUserTrackingParams 
        : ['gclid', 'fbclid']; // Default to existing params for backward compatibility
      
      if (adminParams.length > 0) {
        // Check if any extracted parameter matches admin-defined parameters
        const extractedParamKeys = Object.keys(options.trackingParams).map(k => k.toLowerCase());
        const adminParamKeys = adminParams.map(p => p.toLowerCase().trim());
        
        for (const extractedKey of extractedParamKeys) {
          if (adminParamKeys.includes(extractedKey)) {
            hasAdminDefinedParam = true;
            const paramValue = options.trackingParams[extractedKey];
            console.log(`[User Classification] User ${userId}: Marked as NORMAL_USER (admin-defined parameter detected: ${extractedKey}=${paramValue})`);
            break;
          }
        }
      }
    } catch (error) {
      console.error(`[User Classification] Error checking admin-defined parameters: ${error}`);
    }
  }

  // Determine userType based on classification rules
  // Priority 0: Admin-defined tracking parameters -> normal
  if (hasAdminDefinedParam) {
    userType = 'normal';
    userData.normalUser = true; // Legacy field
    userData.internationalUser = false; // Legacy field
    console.log(`[User Classification] User ${userId}: userType = NORMAL (admin-defined parameter)`);
  } else {
    // Priority 1: Check for gclid or fbclid -> international
    if (options?.gclid || options?.fbclid) {
      userType = 'international';
      userData.internationalUser = true; // Legacy field
      userData.normalUser = false; // Legacy field
      console.log(`[User Classification] User ${userId}: userType = INTERNATIONAL (gclid: ${options?.gclid ? 'present' : 'none'}, fbclid: ${options?.fbclid ? 'present' : 'none'})`);
    } else {
      // Priority 2: Check for referral ID -> normal
      if (options?.referralId && options.referralId.trim().length > 0) {
        userType = 'normal';
        userData.normalUser = true; // Legacy field
        userData.internationalUser = false; // Legacy field
        console.log(`[User Classification] User ${userId}: userType = NORMAL (has referral ID: ${options.referralId})`);
      } else {
        // Priority 3: Apply local conditions
        // Check for VPN or Emulator -> google
        if (options?.isVpn === true) {
          userType = 'google';
          userData.normalUser = false; // Legacy field
          userData.internationalUser = false; // Legacy field
          googleUserReason = 'VPN detected';
          console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
        } else if (options?.isEmulator === true) {
          userType = 'google';
          userData.normalUser = false; // Legacy field
          userData.internationalUser = false; // Legacy field
          googleUserReason = 'Emulator detected';
          console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
        } else if (options?.hasLocalApps === true) {
          // Check for local apps -> normal
          userType = 'normal';
          userData.normalUser = true; // Legacy field
          userData.internationalUser = false; // Legacy field
          console.log(`[User Classification] User ${userId}: userType = NORMAL (has local apps: phonepay, paytm, or fampay)`);
        } else {
          // No local apps found -> google
          userType = 'google';
          userData.normalUser = false; // Legacy field
          userData.internationalUser = false; // Legacy field
          googleUserReason = 'No local apps detected (missing: phonepay, paytm, fampay)';
          console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
        }
      }
    }
  }

  // Legacy email check - only apply if not already classified
  if (!hasAdminDefinedParam && userType !== 'international' && !options?.referralId && !options?.hasLocalApps && !options?.isVpn && !options?.isEmulator) {
    if (!email.endsWith('@gmail.com')) {
      if (userType !== 'normal') {
        userType = 'google';
        userData.normalUser = false; // Legacy field
        if (!googleUserReason) {
          googleUserReason = `Non-Gmail email detected: ${email}`;
          console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
        }
      }
    }
  }

  // Get IP API data for additional information
  let userDoc: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;
  
  if (ipAddress) {
    const settings = await getSettings();
    const ipApiQuery = `?fields=66846719`;
    const ipApiPromise = axios.get(constant.ipApiBaseUrl + ipAddress + ipApiQuery).catch(err => {
      console.error(`[IP Tracking] Failed to fetch IP API data for ${ipAddress}:`, err.message);
      return null; // Return null instead of throwing to allow graceful handling
    });
    const userDocPromise = userDbRef.get();

    try {
      const [ipApiResponse, fetchedUserDoc] = await Promise.all([ipApiPromise, userDocPromise]);
      userDoc = fetchedUserDoc;

      if (ipApiResponse?.data?.status === 'success') {
        const { 
          query, 
          country: ipApiCountry, 
          countryCode, 
          region, 
          regionName, 
          city, 
          zip, 
          lat, 
          lon, 
          timezone, 
          isp, 
          org, 
          as: asNumber 
        } = ipApiResponse.data;

        // HIGHEST PRIORITY: Check if org is "Google" or isp is "Google LLC" -> immediately set userType to "google"
        // This rule overrides all other classification rules
        if (org === 'Google' || isp === 'Google LLC') {
          userType = 'google';
          userData.normalUser = false; // Legacy field
          userData.internationalUser = false; // Legacy field
          googleUserReason = `Google detected (org: ${org}, isp: ${isp})`;
          console.log(`[User Classification] User ${userId}: userType = GOOGLE (HIGHEST PRIORITY) - Reason: ${googleUserReason}`);
        } else {
          // Only apply Google ISP check if not already classified by new logic
          // Skip if user was marked as normalUser via admin-defined parameters
          if (!hasAdminDefinedParam && userType !== 'international' && !options?.referralId && !options?.hasLocalApps && !options?.isVpn && !options?.isEmulator) {
            if (checkForGoogle(isp)) {
              if (userType !== 'normal') {
                userType = 'google';
                userData.normalUser = false; // Legacy field
                if (!googleUserReason) {
                  googleUserReason = `Google ISP detected: ${isp}`;
                  console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
                }
              }
            }
          }
        }

        // Store all IP API data for tracking - use IP API country as it's more accurate
        // Only update country if IP API provides a valid value (don't overwrite with empty string)
        const countryToStore = ipApiCountry && ipApiCountry.trim().length > 0 
          ? ipApiCountry 
          : (country && country.trim().length > 0 ? country : undefined);
        
        Object.assign(userData, { 
          ipQuery: query,
          ...(countryToStore && { country: countryToStore }), // Only set country if we have a valid value
          countryCode,
          region,
          regionName,
          city,
          zip,
          lat,
          lon,
          timezone,
          isp,
          org,
        });
        // Store 'as' field separately using bracket notation (since 'as' is a reserved keyword)
        (userData as any)['as'] = asNumber;
        
        console.log(`[IP Tracking] Successfully stored IP API data for user ${userId}: country=${ipApiCountry || country}, isp=${isp}, org=${org}, city=${city}`);
      } else {
        // IP API call failed or returned non-success - still log basic IP info
        console.log(`[IP Tracking] IP API call failed or returned non-success for ${ipAddress}, storing basic IP info: country=${country}`);
        // Only update country if we have a valid value (don't overwrite with empty string)
        if (country && country.trim().length > 0) {
          userData.country = country;
        }
        // Only set to google if not already classified
        // Skip if user was marked as normalUser via admin-defined parameters
        if (!hasAdminDefinedParam && userType !== 'international' && !options?.referralId && !options?.hasLocalApps && !options?.isVpn && !options?.isEmulator) {
          if (userType !== 'normal') {
            userType = 'google';
            userData.normalUser = false; // Legacy field
            if (!googleUserReason) {
              googleUserReason = 'IP API response status was not success';
              console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
            }
          }
        }
      }

      if (userDoc && userDoc.exists) {
        const userDocData = userDoc.data();

        const settings = await getSettings();
        if (userDocData?.dailyPayoutCount > settings.dailyMaxPayout) {
          await other.blockUserWallet(db, userId, 'DAILY_MAX_LIMIT');
        }
      }
    } catch (error) {
      console.error(`[IP Tracking] Error fetching IP data for user ${userId}:`, error);
      // Ensure we fetch user doc even if IP API fails
      if (!userDoc) {
        try {
          userDoc = await userDbRef.get();
        } catch (e) {
          console.error(`[IP Tracking] Error fetching user doc:`, e);
        }
      }
      // Only set to google if not already classified
      // Skip if user was marked as normalUser via admin-defined parameters
      if (!hasAdminDefinedParam && userType !== 'international' && !options?.referralId && !options?.hasLocalApps && !options?.isVpn && !options?.isEmulator) {
        if (userType !== 'normal') {
          userType = 'google';
          userData.normalUser = false; // Legacy field
          if (!googleUserReason) {
            googleUserReason = `Error fetching IP data: ${error instanceof Error ? error.message : 'Unknown error'}`;
            console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
          }
        }
      }
      // Basic IP address and country are already in userData, so they will still be saved
    }
  } else {
    console.log(`[IP Tracking] No IP address provided for user ${userId}, storing basic info: country=${country}`);
    // Only update country if we have a valid value (don't overwrite with empty string)
    if (country && country.trim().length > 0) {
      userData.country = country;
    }
    // Only set to google if not already classified
    // Skip if user was marked as normalUser via admin-defined parameters
    if (!hasAdminDefinedParam && userType !== 'international' && !options?.referralId && !options?.hasLocalApps && !options?.isVpn && !options?.isEmulator) {
      if (userType !== 'normal') {
        userType = 'google';
        userData.normalUser = false; // Legacy field
        if (!googleUserReason) {
          googleUserReason = 'No IP address provided';
          console.log(`[User Classification] User ${userId}: userType = GOOGLE - Reason: ${googleUserReason}`);
        }
      }
    }
  }

  // Set the userType field in userData
  userData.userType = userType;

  // Store googleUserReason if user is classified as google
  if (userType === 'google' && googleUserReason) {
    userData.googleUserReason = googleUserReason;
  }

  // Store installed apps list if provided
  if (options?.installedApps && Array.isArray(options.installedApps)) {
    userData.installedApps = options.installedApps;
  }

  // Final logging for user classification
  console.log(`[User Classification] Final classification for User ${userId}: userType = ${userType.toUpperCase()}${googleUserReason ? ` - ${googleUserReason}` : ''}`);

  // Log what IP data will be saved
  console.log(`[IP Tracking] Saving IP data for user ${userId}:`, {
    ipAddress: userData.ipAddress,
    country: userData.country,
    countryCode: (userData as any).countryCode,
    isp: (userData as any).isp,
    org: (userData as any).org,
    city: (userData as any).city,
    region: (userData as any).region,
  });

  try {
    await userDbRef.set(userData, { merge: true });
    console.log(`[IP Tracking] Successfully saved user data to Firestore for user ${userId}`);
  } catch (error) {
    console.error(`[IP Tracking] Error setting user data for user ${userId}:`, error);
  }
};

export function getRequestIpAddress(req: Request): string {
  const forwarded = req.headers.get('x-forwarded-for');
  if (forwarded) {
    return forwarded.split(',')[0].trim();
  }
  const realIp = req.headers.get('x-real-ip');
  return realIp || '';
}

function checkForGoogle(input: string): boolean {
  const target = 'google';
  const lowerInput = input.toLowerCase();
  return lowerInput.includes(target);
}

export const getLatLonForIP = async (reqIp: string) => {
  try {
    const settings = await getSettings();
    const ipAPiCordQuery = `?fields=16576`;
    const ipApiResponse = await axios.get(`${constant.ipApiBaseUrl}${reqIp}${ipAPiCordQuery}`);

    if (ipApiResponse.data.status === 'success') {
      const { lat, lon } = ipApiResponse.data;
      return {
        lat: lat || '',
        lon: lon || '',
      };
    }

    return {
      lat: '',
      lon: '',
    };
  } catch (error) {
    console.error('Error retrieving IP location:', error);
    return {
      lat: '',
      lon: '',
    };
  }
};

