import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { addOfferwallRecord } from '@/lib/helpers/record-helper/offerwall-record';


export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) || {};
    const { apiKey, userid, coins, details } = body;

    // Validate required fields
    if (!apiKey || !userid || typeof coins === 'undefined') {
      return new NextResponse(
        JSON.stringify({
          error: 'Missing required fields',
          required: ['apiKey', 'userid', 'coins'],
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Validate and authenticate API key
    if (apiKey !== 'cashapps123') {
      return new NextResponse(
        JSON.stringify({ error: 'Unauthorized - Invalid API key' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Validate userid
    const trimmedUserId = String(userid).trim();
    if (!trimmedUserId) {
      return new NextResponse(
        JSON.stringify({ error: 'Invalid userid' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Validate coins
    const rewardAmount = Math.floor(+coins);
    if (!Number.isFinite(rewardAmount) || rewardAmount <= 0) {
      return new NextResponse(
        JSON.stringify({
          error: 'Invalid coins value. Must be a positive number',
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Ensure user exists
    const userDoc = await db.collection('users').doc(trimmedUserId).get();
    if (!userDoc.exists) {
      return new NextResponse(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Generate transactionId for tracking
    const appId = 'cashflex'; // This is Cash Flex's postback
    const timestamp = Date.now();
    const transactionId = `${trimmedUserId}_${appId}_promotion_app_${timestamp}`;

    // Grant the reward
    const provider = 'PROMOTION_APP';
    const result = await addOfferwallRecord(
      provider,
      trimmedUserId,
      rewardAmount,
      transactionId,
    );

    if (result.response === 'failure') {
      console.error('Failed to add promotion app reward:', result.reason);
      return new NextResponse(
        JSON.stringify({
          error: 'Failed to process reward',
          reason: result.reason,
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Store details in rewardRecord for tracking
    try {
      const rewardRecordDoc = await db
        .collection('rewardRecord')
        .where('transId', '==', transactionId)
        .where('provider', '==', 'PROMOTION_APP')
        .limit(1)
        .get();

      if (!rewardRecordDoc.empty) {
        await rewardRecordDoc.docs[0].ref.update({
          appId: appId,
          details: details || 'Rewards',
        });
      }
    } catch (updateError) {
      // Non-critical error, log but don't fail
      console.warn('Failed to update rewardRecord with details:', updateError);
    }

    return new NextResponse(
      JSON.stringify({
        status: 'success',
        message: 'Coins added successfully',
        timestamp: new Date().toISOString(),
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('Error in Promotion Apps Postback:', error);
    return new NextResponse(
      JSON.stringify({
        status: 'failed',
        message: 'Server error occurred',
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
}
