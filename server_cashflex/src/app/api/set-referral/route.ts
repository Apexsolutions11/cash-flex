import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth, getRequestIpAddress } from '@/lib/middleware/auth';
import { db, admin } from '@/lib/firebase-admin';
import { addRewardRecord } from '@/lib/helpers/record-helper/reward-record';
import { getSettings } from '@/lib/helpers/settings-helper';

export async function POST(request: NextRequest) {
  try {
    const reqIp: string = getRequestIpAddress(request);
    const authContext = await verifyAuth(request);
    const uid: string = authContext?.uid ? authContext.uid.trim() : '';

    if (!uid || uid === '') {
      console.warn(`[SetReferral] Missing User ID. IP: ${reqIp}`);
      return NextResponse.json(
        {
          response: 'failure',
          reason: 'User ID is not available',
        },
        { status: 401 },
      );
    }

    const body = await request.json();
    const usersCol = db.collection('users');
    const userDbRef = usersCol.doc(uid);
    const userDoc = await userDbRef.get();

    if (!userDoc.exists) {
      console.warn(`[SetReferral] User document not found. UID: ${uid}, IP: ${reqIp}`);
      return NextResponse.json({
        response: 'failure',
        reason: 'User document is not available',
      });
    }

    const userDocData = userDoc.data();

    if (
      userDocData?.referred ||
      (userDocData?.referrer != null && userDocData?.referrer.trim() !== '')
    ) {
      console.info(
        `[SetReferral] User already invited. UID: ${uid}, Referrer: ${userDocData?.referrer}`,
      );
      return NextResponse.json({
        response: 'failure',
        reason: 'Already invited.',
      });
    }

    const referralCode: string = body.referralCode ? body.referralCode.trim() : '';

    if (!referralCode || referralCode === '') {
      console.warn(`[SetReferral] Missing referral code. UID: ${uid}, IP: ${reqIp}`);
      return NextResponse.json({
        response: 'failure',
        reason: 'Referral code is not available',
      });
    }

    console.info(`[SetReferral] Processing referral. UID: ${uid}, Referral Code: ${referralCode}`);

    const inviterDoc = await usersCol.where('referralCode', '==', referralCode).get();

    if (inviterDoc.empty) {
      console.warn(`[SetReferral] Inviter not found. UID: ${uid}, Referral Code: ${referralCode}`);
      
      // Get joining bonus coins from appData
      const appDataDoc = await db.collection('admin').doc('appData').get();
      const appData = appDataDoc.exists ? appDataDoc.data() : {};
      const joiningBonusCoins = 
        appData && typeof appData.joiningBonusCoins === 'number' && Number.isFinite(appData.joiningBonusCoins) && appData.joiningBonusCoins > 0
          ? appData.joiningBonusCoins
          : 50; // Default fallback
      
      const result = await addRewardRecord(
        'JOINING_BONUS',
        uid,
        joiningBonusCoins,
        {
          title: 'Congratulations 🎉',
          body: `You have received ${joiningBonusCoins} coins as joining bonus`,
        },
      );

      if (result.response === 'failure') {
        console.error(`[SetReferral] Failed to credit signup bonus. UID: ${uid}, Reason: ${result.reason}`);
      }

      return NextResponse.json({
        response: 'success',
      });
    }

    const inviterDocData = inviterDoc.docs[0].data();

    if (inviterDocData.userId === uid) {
      console.warn(`[SetReferral] Inviter and user are the same. UID: ${uid}`);
      return NextResponse.json({
        response: 'failure',
        reason: 'Inviter and user are the same',
      });
    }

    const inviterIP = inviterDocData.ipAddress;

    if (reqIp && inviterIP && reqIp === inviterIP) {
      console.warn(
        `[SetReferral] IP address conflict. UID: ${uid}, Inviter UID: ${inviterDocData.userId}, IP: ${reqIp}`,
      );
      return NextResponse.json({
        response: 'failure',
        reason: 'Requester and Inviter cannot have the same IP address',
      });
    }

    const inviterUid: string = inviterDocData.userId;

    await userDbRef.set(
      {
        referred: true,
        referrer: inviterUid,
      },
      { merge: true },
    );

    // Get referral coins from appData
    const appDataDoc = await db.collection('admin').doc('appData').get();
    const appData = appDataDoc.exists ? appDataDoc.data() : {};
    const referralCoins = 
      appData && typeof appData.referralCoins === 'number' && Number.isFinite(appData.referralCoins) && appData.referralCoins > 0
        ? appData.referralCoins
        : 100; // Default fallback

    const result = await addRewardRecord(
      'SIGNUP_BONUS',
      uid,
      referralCoins,
      {
        title: 'Congratulations 🎉',
        body: `You have received ${referralCoins} coins for signing up using a referral link.`,
      },
    );

    if (result.response === 'failure') {
      console.error(`Failure adding reward: ${result.reason}`);
      return NextResponse.json({
        response: 'failure',
        reason: result.reason,
      });
    }

    const settings = await getSettings();
    const inviterReferralCount = inviterDocData.referralCount;
    const inviterEmail = inviterDocData.email;
    let giveReward = false;

    if (inviterReferralCount > 500 && settings.adminEmail !== inviterEmail) {
      if (Math.random() > 0.7) {
        giveReward = true;
      } else {
        console.error(`Reward not given due to 70% probability logic.`);
      }
    } else {
      giveReward = true;
    }

    if (giveReward) {
      await usersCol.doc(inviterUid).update({
        referralCount: admin.firestore.FieldValue.increment(1),
      });
    }

    console.log(`Referral process completed successfully`);
    return NextResponse.json({
      response: 'success',
    });
  } catch (error) {
    console.error(`[SetReferral] Unexpected error: ${error}`);
    return NextResponse.json(
      {
        response: 'failure',
        reason: error,
      },
      { status: 500 },
    );
  }
}

