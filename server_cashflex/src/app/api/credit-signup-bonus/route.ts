import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/middleware/auth';
import { db } from '@/lib/firebase-admin';
import { addRewardRecord } from '@/lib/helpers/record-helper/reward-record';

export async function POST(request: NextRequest) {
  try {
    const authContext = await verifyAuth(request);

    if (!authContext || !authContext.uid) {
      return NextResponse.json(
        {
          response: 'failure',
          reason: 'Access denied',
        },
        { status: 401 },
      );
    }

    const userId = authContext.uid.trim();

    if (!userId) {
      return NextResponse.json({
        response: 'failure',
        reason: 'User ID not provided',
      });
    }

    const userRef = db.collection('users').doc(userId);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      return NextResponse.json({
        response: 'failure',
        reason: 'User not found',
      });
    }

    const userData = userSnapshot.data();

    const referred = userData?.referred || false;

    if (!referred) {
      const rewardHistorySnapshot = await userRef.collection('rewardHistory').limit(1).get();

      if (!rewardHistorySnapshot.empty) {
        return NextResponse.json({
          response: 'failure',
          reason: 'User has existing rewards',
        });
      }

      // Get joining bonus coins from appData
      const appDataDoc = await db.collection('admin').doc('appData').get();
      const appData = appDataDoc.exists ? appDataDoc.data() : {};
      const joiningBonusCoins = 
        appData && typeof appData.joiningBonusCoins === 'number' && Number.isFinite(appData.joiningBonusCoins) && appData.joiningBonusCoins > 0
          ? appData.joiningBonusCoins
          : 50; // Default fallback

      const result = await addRewardRecord(
        'JOINING_BONUS',
        userId,
        joiningBonusCoins,
        {
          title: 'Congratulations 🎉',
          body: `You have received ${joiningBonusCoins} coins as joining bonus`,
        },
      );

      if (result.response === 'failure') {
        console.log(result.reason);
      }

      return NextResponse.json({
        response: 'success',
      });
    } else {
      return NextResponse.json({
        response: 'failure',
        reason: 'User is already joined',
      });
    }
  } catch (error) {
    console.error('Error in credit signup bonus:', error);

    return NextResponse.json(
      {
        response: 'failure',
        reason: 'An unexpected error occurred. Please try again later.',
      },
      { status: 500 },
    );
  }
}

