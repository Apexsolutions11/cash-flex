import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/middleware/auth';
import { db, admin } from '@/lib/firebase-admin';
import { addRewardRecord } from '@/lib/helpers/record-helper/reward-record';

export async function POST(request: NextRequest) {
  try {
    const authContext = await verifyAuth(request);

    if (!authContext) {
      return NextResponse.json(
        {
          response: 'failure',
          reason: 'Access denied',
        },
        { status: 401 },
      );
    }

    const body = await request.json();
    const requestedCoins = body.coins ?? 0;
    const title = body.title ?? 'COINS_BONUS';

    if (!Number.isInteger(requestedCoins) || requestedCoins > 50) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Invalid or too many coins',
      });
    }

    const uid = authContext.uid?.trim();

    if (!uid) {
      return NextResponse.json({
        response: 'failure',
        reason: 'UserId is not available',
      });
    }

    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return NextResponse.json({
        response: 'failure',
        reason: 'User not found',
      });
    }

    if (requestedCoins > 0) {
      await addRewardRecord(
        title,
        uid,
        requestedCoins,
        {
          title: 'Congratulations 🎉',
          body: `You have received ${requestedCoins} coins`,
        },
      );
    }

    // Only increment game coins, not dailyGameCount (that's handled separately)
    await userDoc.ref.update({
      gameCoins: admin.firestore.FieldValue.increment(requestedCoins),
    });

    return NextResponse.json({
      response: 'success',
    });
  } catch (error) {
    console.error('Error in claimCoins function:', error);
    return NextResponse.json(
      {
        response: 'failure',
        reason: 'Internal server error',
      },
      { status: 500 },
    );
  }
}

