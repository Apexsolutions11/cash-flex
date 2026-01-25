import { randomBytes } from 'crypto';
import { admin, db } from '../firebase-admin';
import * as constant from '../constants';
import { getSettings } from './settings-helper';

export const genOrderID = async () => {
  const settings = await getSettings();
  const timestamp = Date.now().toString(36);
  const randomValue = randomBytes(6).toString('hex');
  const orderId = `${settings.appNameSH}${timestamp}${randomValue}`;
  return orderId;
};

export const sendFcmNotification = async (message: admin.messaging.Message): Promise<void> => {
  try {
    await admin.messaging().send(message);
  } catch (error) {
    console.error(`Error sending fcm notification: ${error}`);
  }
};

export const sendTopicNotification = async (message: admin.messaging.Message): Promise<void> => {
  try {
    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending topic notification: ', error);
  }
};

export const sendFcmNotificationViaUid = async (
  uid: string,
  notification: constant.NotificationType,
): Promise<void> => {
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const userDocData = userDoc.data();
    const fcmToken: string = userDocData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM Token found for user: ${uid}`);
      return;
    }

    const message = {
      notification: notification,
      token: fcmToken,
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error(`Error sending FCM notification to user ${uid}: ${error}`);
  }
};

export async function blockUserWallet(
  db: admin.firestore.Firestore,
  userId: string,
  reason: string,
) {
  const userRef = db.collection('users').doc(userId);

  await userRef.set(
    {
      walletBlocked: true,
      reason: reason,
    },
    { merge: true },
  );
}

export function formatProvider(provider: string): string {
  const words = provider.split('_');
  const capitalizedWords = words.map(
    (word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase(),
  );
  return capitalizedWords.join(' ');
}

