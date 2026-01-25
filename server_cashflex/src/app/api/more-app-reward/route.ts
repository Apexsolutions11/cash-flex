import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/middleware/auth';
import { db, admin } from '@/lib/firebase-admin';
import { addRewardRecord } from '@/lib/helpers/record-helper/reward-record';

export async function POST(request: NextRequest) {
  try {
    const authContext = await verifyAuth(request);
    if (!authContext || !authContext.uid) {
      return NextResponse.json({ response: 'failure', reason: 'Access denied' }, { status: 401 });
    }

    const body = await request.json();
    const uid = authContext.uid.trim();
    const appId = String(body.appId ?? '').trim();

    if (!uid || !appId) {
      return NextResponse.json({ response: 'failure', reason: 'Invalid data' }, { status: 400 });
    }

    const appDoc = await db.collection('moreApps').doc(appId).get();
    if (!appDoc.exists) {
      return NextResponse.json({ response: 'failure', reason: 'Invalid app' }, { status: 400 });
    }

    const appData = appDoc.data() || {};
    if (!appData.active) {
      return NextResponse.json({ response: 'failure', reason: 'Inactive app' }, { status: 400 });
    }

    const settingsDoc = await db.collection('admin').doc('appData').get();
    const settings = settingsDoc.exists ? (settingsDoc.data() || {}) : {};

    const defaultCoins =
      typeof settings.moreAppsDefaultCoins === 'number' && Number.isFinite(settings.moreAppsDefaultCoins)
        ? settings.moreAppsDefaultCoins
        : 0;

    const coins =
      defaultCoins > 0
        ? defaultCoins
        : typeof appData.coins === 'number' && Number.isFinite(appData.coins)
          ? appData.coins
          : 0;
    if (coins <= 0) {
      return NextResponse.json({ response: 'failure', reason: 'Invalid reward' }, { status: 400 });
    }

    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      return NextResponse.json({ response: 'failure', reason: 'User not found' }, { status: 404 });
    }

    const completed = (userDoc.data()?.moreAppsCompleted as string[]) || [];
    if (completed.includes(appId)) {
      return NextResponse.json({ response: 'failure', reason: 'Offer is already completed' });
    }

    // Mark completed (so it can't be claimed twice)
    await userRef.update({
      moreAppsCompleted: admin.firestore.FieldValue.arrayUnion(appId),
    });

    await addRewardRecord('MORE_APPS', uid, coins, {
      title: 'Congratulations 🎉',
      body: `You have received ${coins} coins for completing the app offer.`,
    });

    return NextResponse.json({ response: 'success' });
  } catch (error) {
    console.error('Error in more app reward: ', error);
    return NextResponse.json(
      { response: 'failure', reason: 'An unexpected error occurred. Please try again later.' },
      { status: 500 },
    );
  }
}


