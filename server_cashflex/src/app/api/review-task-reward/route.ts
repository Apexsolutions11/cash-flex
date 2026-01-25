import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/middleware/auth';
import { db, admin } from '@/lib/firebase-admin';
import { addRewardRecord } from '@/lib/helpers/record-helper/reward-record';
import axios from 'axios';
import * as constant from '@/lib/constants';
import { getSettings } from '@/lib/helpers/settings-helper';

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
    const name = body.name ? body.name.trim() : '';

    if (userId === '' || name === '') {
      return NextResponse.json({
        response: 'failure',
        reason: 'Invalid data',
      });
    }

    const nameDoc = await db.collection('reviewTask').doc(name).get();
    const nameData = nameDoc.data();

    if (!nameDoc.exists || !nameData?.enabled) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Invalid or inactive offer',
      });
    }

    const link = nameData.link;
    const appDataDoc = await db.collection('admin').doc('appData').get();
    const appData = appDataDoc.exists ? appDataDoc.data() : null;

    const defaultCoins =
      appData && typeof appData.reviewTaskDefaultCoins === 'number' && Number.isFinite(appData.reviewTaskDefaultCoins)
        ? appData.reviewTaskDefaultCoins
        : null;

    const coins =
      defaultCoins && defaultCoins > 0
        ? defaultCoins
        : typeof nameData.coins === 'number' && Number.isFinite(nameData.coins)
          ? nameData.coins
          : 150;

    const userDoc = await db.collection('users').doc(userId).get();
    const userDocData = userDoc.data();

    const reviewedList = userDocData?.reviewedList || [];
    const email = userDocData?.email || '';

    if (reviewedList.includes(name)) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Offer is already completed',
      });
    }

    const batch = db.batch();

    batch.update(userDoc.ref, {
      reviewedList: admin.firestore.FieldValue.arrayUnion(name),
    });

    await batch.commit();

    let addCoins = true;

        try {
          const settings = await getSettings();
          const apiResponse = await axios.post(constant.reviewTaskUrl, {
            email: email,
            link: link,
            appName: settings.appName,
          });

      if (apiResponse.status == 200 && apiResponse.data == '1') {
        addCoins = false;
      } else {
        addCoins = true;
      }
    } catch (apiError) {
      addCoins = true;
    }

    if (addCoins) {
      console.log('Adding coins for review task');
      const result = await addRewardRecord(
        'REVIEW_&_EARN',
        userId,
        coins,
        {
          title: 'Reward Received 🎉',
          body: `You have received ${coins} coins for completing a task`,
        },
      );

      if (result.response === 'failure') {
        console.log(result.reason);
      }
    } else {
      console.log('Not adding coins for review task');
    }

    return NextResponse.json({
      response: 'success',
    });
  } catch (error) {
    console.error('Error in review task reward: ', error);

    return NextResponse.json(
      {
        response: 'failure',
        reason: 'An unexpected error occurred. Please try again later.',
      },
      { status: 500 },
    );
  }
}

