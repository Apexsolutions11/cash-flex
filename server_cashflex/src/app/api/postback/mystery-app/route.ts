import { NextRequest, NextResponse } from 'next/server';
import { db, admin } from '@/lib/firebase-admin';
import { addOfferwallRecord } from '@/lib/helpers/record-helper/offerwall-record';
import { getSettings } from '@/lib/helpers/settings-helper';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json() || {};
    const { referralCode, id, coins, apiKey } = body;

    if (!referralCode || !id || !coins || !apiKey) {
      return new NextResponse('Missing required fields', { status: 400 });
    }

    const settings = await getSettings();
    if (apiKey !== settings.mysteryKey) {
      return new NextResponse('Unauthorized', { status: 403 });
    }

    const userSnapshot = await db
      .collection('users')
      .where('referralCode', '==', referralCode)
      .limit(1)
      .get();

    if (userSnapshot.empty) {
      return new NextResponse('User not found', { status: 404 });
    }

    const userId = userSnapshot.docs[0].id;
    const rewardAmount = Math.floor(+coins);

    const now = admin.firestore.Timestamp.now();
    const eighteenHoursAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 18 * 60 * 60 * 1000,
    );

    const recentRewardSnapshot = await db
      .collection(`users/${userId}/rewardHistory`)
      .where('provider', '==', 'MYSTERY_APP_REWARD')
      .where('timestamp', '>=', eighteenHoursAgo)
      .limit(1)
      .get();

    if (!recentRewardSnapshot.empty) {
      return new NextResponse('Duplicate reward detected within 18 hours', { status: 409 });
    }

    const result = await addOfferwallRecord('MYSTERY_APP_REWARD', userId, rewardAmount, id);

    if (result.response === 'failure') {
      console.error(result.reason);
    }

    return new NextResponse('Success', { status: 200 });
  } catch (error) {
    console.error('Error in Mystery App Postback:', error);
    return new NextResponse('Internal server error', { status: 500 });
  }
}

