import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { addOfferwallRecord } from '@/lib/helpers/record-helper/offerwall-record';
import { getSettings } from '@/lib/helpers/settings-helper';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { apiKey, email, id, coins } = body;

    if (!apiKey || !email || !id || !coins) {
      return new NextResponse('Missing required parameters: apiKey, email, id, or coins.', {
        status: 400,
      });
    }

    const settings = await getSettings();
    if (apiKey !== settings.mysteryKey) {
      return new NextResponse('Unauthorized', { status: 403 });
    }

    const trimmedEmail: string = email.trim();
    const userRef = db.collection('users');
    const userSnapshot = await userRef.where('email', '==', trimmedEmail).limit(1).get();

    if (userSnapshot.empty) {
      return new NextResponse('User not found', { status: 404 });
    }

    const userId: string = userSnapshot.docs[0].id;
    const transId: string = id.trim();
    const rewardAmount: number = Math.floor(+coins);

    const result = await addOfferwallRecord('SPECIAL_REWARD', userId, rewardAmount, transId);

    if (result.response === 'failure') {
      console.log(result.reason);
    }

    return new NextResponse('Success', { status: 200 });
  } catch (error) {
    console.error('Error in Special Reward Postback:', error);
    return new NextResponse('Internal server error', { status: 500 });
  }
}

