import { admin, db } from '../../firebase-admin';
import * as constant from '../../constants';
import * as other from '../other-service';

export const addRewardRecord = async (
  provider: string,
  userId: string,
  rewardAmount: number,
  notification: constant.NotificationType,
) => {
  try {
    userId = userId.trim();

    if (isNaN(rewardAmount) || !userId) {
      return {
        response: 'failure',
        reason: 'Invalid input',
      };
    }

    const fieldValue = admin.firestore.FieldValue;

    const timestamp = fieldValue.serverTimestamp();
    const timestampMs = Date.now();

    const userDbRef = db.collection('users').doc(userId);
    const userDoc = await userDbRef.get();

    if (!userDoc.exists) {
      return {
        response: 'failure',
        reason: 'User does not exist in the database',
      };
    }

    const userDocData = userDoc.data();

    if (!userDocData) {
      return {
        response: 'failure',
        reason: 'User data not found',
      };
    }

    const fcmToken: string = userDocData.fcmToken ?? '';
    const country: string = userDocData.country ?? '';

    const orderId: string = await other.genOrderID();

    const batch = db.batch();

    const coinsVal = fieldValue.increment(rewardAmount);

    batch.update(userDbRef, {
      totalCoins: coinsVal,
      coins: coinsVal,
      balance: coinsVal,
      rewardEarning: coinsVal,
    });

    batch.set(userDbRef.collection('rewardHistory').doc(orderId), {
      provider: provider,
      rewardAmount: rewardAmount,
      timestamp: timestamp,
      timestampMs: timestampMs,
      orderId: orderId,
    });

    batch.set(db.collection('rewardRecord').doc(orderId), {
      provider: provider,
      userId: userId,
      rewardAmount: rewardAmount,
      timestamp: timestamp,
      timestampMs: timestampMs,
      orderId: orderId,
      country: country,
    });

    await batch.commit();

    if (fcmToken) {
      await other.sendFcmNotification({
        notification: notification,
        token: fcmToken,
      });
    }

    return {
      response: 'success',
    };
  } catch (error) {
    console.error('Error in adding reward record: ', error);

    return {
      response: 'failure',
      reason: 'An unexpected error occurred. Please try again later.',
    };
  }
};

