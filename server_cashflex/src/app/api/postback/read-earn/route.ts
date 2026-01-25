import { NextRequest, NextResponse } from 'next/server';
import { addOfferwallRecord } from '@/lib/helpers/record-helper/offerwall-record';
import { getSettings } from '@/lib/helpers/settings-helper';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { apiKey, userId, txnId, coins } = body;

    if (!apiKey || !userId || !txnId || !coins) {
      return new NextResponse('Missing required parameters: apiKey, userId, txnId, or coins.', {
        status: 400,
      });
    }

    const settings = await getSettings();
    if (apiKey !== settings.mysteryKey) {
      return new NextResponse('Unauthorized', { status: 403 });
    }

    const rewardAmount: number = Math.floor(coins);

    const result = await addOfferwallRecord('READ_&_EARN', userId, rewardAmount, txnId);

    if (result.response === 'failure') {
      console.log(result.reason);
    }

    return new NextResponse('Success', { status: 200 });
  } catch (error) {
    console.error('Error in Read Earn Postback:', error);
    return new NextResponse('Internal server error', { status: 500 });
  }
}

