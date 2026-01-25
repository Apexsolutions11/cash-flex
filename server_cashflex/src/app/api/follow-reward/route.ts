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

    const body = await request.json();
    const userId = authContext.uid.trim();
    const tag = body.tag ? body.tag.trim() : '';

    if (userId === '' || tag === '') {
      return NextResponse.json({
        response: 'failure',
        reason: 'Invalid data',
      });
    }

    const tagDoc = await db.collection('socials').doc(tag).get();
    const tagData = tagDoc.data();

    if (!tagDoc.exists || !tagData?.active) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Invalid or inactive tag',
      });
    }

    const platform = tagData.type;
    const appDataDoc = await db.collection('admin').doc('appData').get();
    const appData = appDataDoc.exists ? appDataDoc.data() : null;

    const defaultCoins =
      appData && typeof appData.followTaskDefaultCoins === 'number' && Number.isFinite(appData.followTaskDefaultCoins)
        ? appData.followTaskDefaultCoins
        : null;

    const coins =
      defaultCoins && defaultCoins > 0
        ? defaultCoins
        : typeof tagData.coins === 'number' && Number.isFinite(tagData.coins)
          ? tagData.coins
          : 10;

    const userDoc = await db.collection('users').doc(userId).get();
    const userDocData = userDoc.data();

    const socialFollowed = userDocData?.socialFollowed || [];

    if (socialFollowed.includes(tag)) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Platform is already followed',
      });
    }

    const batch = db.batch();

    batch.update(userDoc.ref, {
      socialFollowed: admin.firestore.FieldValue.arrayUnion(tag),
    });

    await batch.commit();

    const result = await addRewardRecord(
      'FOLLOW_REWARD',
      userId,
      coins,
      {
        title: 'Congratulations 🎉',
        body: `You have received ${coins} coins for following us on ${platform}.`,
      },
    );

    if (result.response === 'failure') {
      console.log(result.reason);
    }

    return NextResponse.json({
      response: 'success',
    });
  } catch (error) {
    console.error('Error in follow reward: ', error);

    return NextResponse.json(
      {
        response: 'failure',
        reason: 'An unexpected error occurred. Please try again later.',
      },
      { status: 500 },
    );
  }
}

