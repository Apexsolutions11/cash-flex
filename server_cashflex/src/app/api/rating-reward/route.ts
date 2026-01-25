import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/middleware/auth';
import { db, admin } from '@/lib/firebase-admin';
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

    if (userId === '') {
      return NextResponse.json({
        response: 'failure',
        reason: 'Invalid data',
      });
    }

    const userDoc = await db.collection('users').doc(userId).get();
    const userDocData = userDoc.data();

    const rated = userDocData?.rated || false;

    if (rated) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Already rating done',
      });
    }

    const batch = db.batch();

    batch.update(userDoc.ref, {
      rated: true,
    });

    await batch.commit();

    const appDataDoc = await db.collection('admin').doc('appData').get();
    const appData = appDataDoc.exists ? appDataDoc.data() : null;

    const coins =
      appData && typeof appData.rateUsCoins === 'number' && Number.isFinite(appData.rateUsCoins) && appData.rateUsCoins > 0
        ? appData.rateUsCoins
        : 50;

    const result = await addRewardRecord(
      'RATING_REWARD',
      userId,
      coins,
      {
        title: 'Congratulations 🎉',
        body: `You have received ${coins} coins for rating us on Play Store.`,
      },
    );

    if (result.response === 'failure') {
      console.log(result.reason);
    }

    return NextResponse.json({
      response: 'success',
    });
  } catch (error) {
    console.error('Error in rating reward: ', error);

    return NextResponse.json(
      {
        response: 'failure',
        reason: 'An unexpected error occurred. Please try again later.',
      },
      { status: 500 },
    );
  }
}

