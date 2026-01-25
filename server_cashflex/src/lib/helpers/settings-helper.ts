import { db } from '../firebase-admin';

interface Settings {
  secureKey: string;
  ipKey: string;
  payoutKey: string;
  adjoeKey: string;
  mysteryKey: string;
  adminEmail: string;
  appName: string;
  appNameSH: string;
  dailyMaxPayout: number;
  referrerCommision: number;
  batchSize: number;
}

let cachedSettings: Settings | null = null;
let cacheTimestamp: number = 0;
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

/**
 * Gets admin settings from Firestore with caching.
 * Falls back to environment variables if settings don't exist in Firestore.
 */
export async function getSettings(): Promise<Settings> {
  const now = Date.now();
  
  // Return cached settings if still valid
  if (cachedSettings && (now - cacheTimestamp) < CACHE_TTL) {
    return cachedSettings;
  }

  try {
    const settingsDoc = await db.collection('admin').doc('settings').get();
    
    if (settingsDoc.exists) {
      const data = settingsDoc.data() as Settings;
      cachedSettings = {
        secureKey: data.secureKey || process.env.SECURE_KEY || '',
        ipKey: data.ipKey || process.env.IP_KEY || '',
        payoutKey: data.payoutKey || process.env.PAYOUT_KEY || '',
        adjoeKey: data.adjoeKey || process.env.ADJOE_KEY || '',
        mysteryKey: data.mysteryKey || process.env.MYSTERY_KEY || '',
        adminEmail: data.adminEmail || process.env.ADMIN_EMAIL || '',
        appName: data.appName || 'Cash Flex',
        appNameSH: data.appNameSH || 'GR',
        dailyMaxPayout: data.dailyMaxPayout || 1,
        referrerCommision: data.referrerCommision || 0.5,
        batchSize: data.batchSize || 5000,
      };
      cacheTimestamp = now;
      return cachedSettings;
    }
  } catch (error) {
    console.error('Error fetching settings from Firestore:', error);
  }

  // Fallback to environment variables
  return {
    secureKey: process.env.SECURE_KEY || '',
    ipKey: process.env.IP_KEY || '',
    payoutKey: process.env.PAYOUT_KEY || '',
    adjoeKey: process.env.ADJOE_KEY || '',
    mysteryKey: process.env.MYSTERY_KEY || '',
    adminEmail: process.env.ADMIN_EMAIL || '',
    appName: 'Cash Flex',
    appNameSH: 'GR',
    dailyMaxPayout: 1,
    referrerCommision: 0.5,
    batchSize: 5000,
  };
}

/**
 * Clears the settings cache (call after updating settings)
 */
export function clearSettingsCache() {
  cachedSettings = null;
  cacheTimestamp = 0;
}

