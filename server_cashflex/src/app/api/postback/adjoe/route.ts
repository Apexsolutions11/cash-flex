import { NextRequest, NextResponse } from 'next/server';
import { getRequestIpAddress } from '@/lib/middleware/auth';
import { addOfferwallRecord } from '@/lib/helpers/record-helper/offerwall-record';
import * as constant from '@/lib/constants';
import { getSettings } from '@/lib/helpers/settings-helper';
import crypto from 'crypto';

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const queryParams: any = {};
    searchParams.forEach((value, key) => {
      queryParams[key] = value;
    });

    const reqIp: string = getRequestIpAddress(request);

    console.log(queryParams);

    if (!queryParams || !queryParams.uid || !constant.adjoeServerIpList.includes(reqIp)) {
      return new NextResponse('0', { status: 404 });
    }

    const userId: string = (queryParams.uid as string).trim();
    const transId: string = (queryParams.tranx as string).trim();
    const rewardAmount: number = +queryParams.coins!;
    const currency: string = (queryParams.currency as string).trim();
    const device_id: string = (queryParams.device_id as string).trim();
    const sdk_app_id: string = (queryParams.sdk_app_id as string).trim();

    const settings = await getSettings();
    const sidData =
      transId + userId + currency + rewardAmount + device_id + sdk_app_id + settings.adjoeKey;
    const sid = crypto.createHash('sha1').update(sidData).digest('hex');

    if (queryParams.sid !== sid) {
      return new NextResponse('0', { status: 403 });
    }

    const result = await addOfferwallRecord('PLAYTIME', userId, rewardAmount, transId);

    if (result.response === 'failure') {
      console.log(result.reason);
    }

    return new NextResponse('1', { status: 200 });
  } catch (error) {
    console.error('Error in Adjoe Postback:', error);
    return new NextResponse('Internal Server Error', { status: 500 });
  }
}

