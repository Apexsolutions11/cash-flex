import { admin, db } from '../../firebase-admin';
import * as other from '../other-service';

export const addOfferwallRecord = async (
  provider: string,
  userId: string,
  rewardAmount: number,
  transId: string,
): Promise<Record<string, string>> => {
  try {
    userId = userId.trim();
    transId = transId.trim();
    rewardAmount = Math.floor(rewardAmount);

    const fieldValue = admin.firestore.FieldValue;

    const timestamp = fieldValue.serverTimestamp();
    const timestampMs = Date.now();

    if (!rewardAmount || isNaN(rewardAmount)) {
      return {
        response: 'failure',
        reason: 'Invalid reward amount',
      };
    }

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

    const fcmToken = userDocData.fcmToken ?? '';
    const country: string = userDocData.country ?? '';

    const orderId = await other.genOrderID();
    const batch = db.batch();
    const coinsVal = fieldValue.increment(rewardAmount);

    const updateData: any = {
      coins: coinsVal,
      totalCoins: coinsVal,
      balance: coinsVal,
    };

    if (provider === 'PLAYTIME' || provider === 'SPECIAL_REWARD') {
      updateData.adjoeEarning = coinsVal;
    } else {
      updateData.offersEarning = coinsVal;
    }

    batch.set(userDbRef, updateData, { merge: true });

    const referrer = userDocData.referrer;
    let referrerRewardAmount = 0;

    if (referrer) {
      const referrerDocRef = db.collection('users').doc(referrer);
      const referrerDoc = await referrerDocRef.get();

      if (referrerDoc.exists) {
        const referrerCoinsVal = fieldValue.increment(referrerRewardAmount);

        batch.update(referrerDocRef, {
          coins: referrerCoinsVal,
          totalCoins: referrerCoinsVal,
          balance: referrerCoinsVal,
          referralEarning: fieldValue.increment(referrerRewardAmount),
        });
      }
    }

    batch.set(userDbRef.collection('rewardHistory').doc(orderId), {
      provider: provider,
      rewardAmount: rewardAmount,
      timestamp: timestamp,
      timestampMs: timestampMs,
      orderId: orderId,
      transId: transId,
      referrerRewardAmount: referrerRewardAmount,
    });

    batch.set(db.collection('rewardRecord').doc(orderId), {
      transId: transId,
      provider: provider,
      userId: userId,
      rewardAmount: rewardAmount,
      timestamp: timestamp,
      timestampMs: timestampMs,
      orderId: orderId,
      referrerRewardAmount: referrerRewardAmount,
      country: country,
    });

    if (fcmToken) {
      await other.sendFcmNotification({
        notification: {
          title: 'Reward Received 🎉',
          body: `You have received ${rewardAmount} coins for completing an offer from ${other.formatProvider(provider)}`,
        },
        token: fcmToken,
      });
    }

    await batch.commit();

    return {
      response: 'success',
    };
  } catch (error) {
    console.error('Error in addOfferwallRecord:', error);

    return {
      response: 'failure',
      reason: 'An unexpected error occurred. Please try again later.',
    };
  }
};

