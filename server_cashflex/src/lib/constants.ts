export const options = {
  timeoutSeconds: 300,
  memory: '8GB' as const,
};

export interface NotificationType {
  title: string;
  body: string;
}

// These will be loaded dynamically from Firestore via getSettings()
// Default values for backwards compatibility
export const appName: string = 'Cash Flex';
export const appNameSH: string = 'CF';
export const dailyMaxPayout: number = 1;
export const referrerCommision: number = 0.5;
export const batchSize: number = 5000;

// Legacy exports - use getSettings() for dynamic values
export const secureKey = process.env.SECURE_KEY || '';
export const ipKey = process.env.IP_KEY || '';
export const payoutKey = process.env.PAYOUT_KEY || '';
export const adjoeKey = process.env.ADJOE_KEY || '';
export const mysteryKey = process.env.MYSTERY_KEY || '';
export const adminEmail: string = process.env.ADMIN_EMAIL || '';

export const ipApiBaseUrl: string = 'https://pro.ip-api.com/json/';

// Helper function to get IP API query (needs to be async)
export async function getIpApiQuery(): Promise<string> {
  const { getSettings } = await import('./helpers/settings-helper');
  const settings = await getSettings();
  return `?key=${settings.ipKey}&fields=157215`;
}

export async function getIpApiCordQuery(): Promise<string> {
  const { getSettings } = await import('./helpers/settings-helper');
  const settings = await getSettings();
  return `?key=${settings.ipKey}&fields=16576`;
}

// Legacy exports for backwards compatibility
export const ipApiQuery: string = `?key=${ipKey}&fields=157215`;
export const ipAPiCordQuery: string = `?key=${ipKey}&fields=16576`;

export const xdGooglePlayPid: number = 48801;
export const xdPaypalPid: number = 58832;
export const xdDanaPid: number = 54670;
export const xdGCashPid: number = 49900;
export const xdTouchNGoPid: number = 52119;
export const xdAmazonPid: number = 58966;
export const xdFlipkartPid: number = 1007;

const paymentServerBaseUrl = 'https://payouts.adzeagle.com/api/v1';

const paymentEndPoints = {
  openmoney: {
    request: `${paymentServerBaseUrl}/handle-transactions/openmoney`,
    status: `${paymentServerBaseUrl}/payment-status/openmoney`,
  },
  xoxoday: {
    request: `${paymentServerBaseUrl}/handle-transactions/xoxoday`,
    status: `${paymentServerBaseUrl}/payment-status/xoxoday`,
  },
  cashfree: {
    request: `${paymentServerBaseUrl}/handle-transactions/cashfree`,
    status: `${paymentServerBaseUrl}/payment-status/cashfree`,
  },
};

export const { openmoney, xoxoday, cashfree } = paymentEndPoints;

export const reviewTaskUrl = 'http://64.227.132.79/api/checkReviewTask';

export const adjoeServerIpList: readonly string[] = [
  '3.121.65.44',
  '18.185.166.67',
  '52.29.52.48',
];

