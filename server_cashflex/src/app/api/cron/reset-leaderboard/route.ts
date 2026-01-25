import { NextRequest, NextResponse } from 'next/server';
import { db, admin } from '@/lib/firebase-admin';
import { addRewardRecord } from '@/lib/helpers/record-helper/reward-record';
import { getSettings } from '@/lib/helpers/settings-helper';
import * as other from '@/lib/helpers/other-service';
import { verifyCronAuth } from '@/lib/middleware/cron-auth';

export async function POST(request: NextRequest) {

  if (!verifyCronAuth(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    await other.sendTopicNotification({
      notification: {
        title: '🏆 Leaderboard Reset Alert',
        body: '🔄 Leaderboard resetting is in progress',
      },
      topic: 'default',
    });

    const userDbRef = db.collection('users');

    const coinsDocs = await userDbRef
      .where('coins', '>', 0)
      .orderBy('coins', 'desc')
      .limit(25)
      .get();
    const coinsBatch = db.batch();

    const addRewardPromises = coinsDocs.docs.map(async (doc) => {
      const userId = doc.data().userId;
      if (userId) {
        const result = await addRewardRecord(
          'LEADERBOARD',
          userId,
          1000,
          {
            title: 'Congratulations 🎉',
            body: `You have received 1000 coins for being top 25 in the leaderboard`,
          },
        );
        if (result.response === 'failure') {
          console.log(result.reason);
        }
      }
    });

    await Promise.all(addRewardPromises);
    await coinsBatch.commit();

    const settings = await getSettings();
    let query = userDbRef.where('coins', '>', 0).limit(settings.batchSize);
    let lastDocument = null;
    let batchCount = 0;
    let snapshot;

    do {
      if (lastDocument) {
        query = query.startAfter(lastDocument);
      }

      snapshot = await query.get();

      if (snapshot.empty) {
        console.log('No more documents to process for coins reset.');
        break;
      }

      const batch = db.batch();

      snapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          coins: 0,
        });
      });

      await batch.commit();
      batchCount += snapshot.size;

      lastDocument = snapshot.docs[snapshot.size - 1];
    } while (snapshot.size >= settings.batchSize);

    console.log(`Processed ${batchCount} user documents for resetting coins.`);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Unexpected error in reset leaderboard and coins process:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

