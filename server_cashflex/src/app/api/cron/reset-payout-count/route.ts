import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { getSettings } from '@/lib/helpers/settings-helper';
import { verifyCronAuth } from '@/lib/middleware/cron-auth';

export async function POST(request: NextRequest) {

  if (!verifyCronAuth(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const settings = await getSettings();
    const userDbRef = db.collection('users');

    let query = userDbRef.where('dailyPayoutCount', '>', 0).limit(settings.batchSize);
    let lastDocument = null;
    let batchCount = 0;
    let snapshot;

    do {
      if (lastDocument) {
        query = query.startAfter(lastDocument);
      }

      snapshot = await query.get();

      if (snapshot.empty) {
        console.log('No more documents to process for payout count.');
        break;
      }

      const batch = db.batch();

      snapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          dailyPayoutCount: 0,
        });
      });

      await batch.commit();
      batchCount += snapshot.size;

      lastDocument = snapshot.docs[snapshot.size - 1];
    } while (snapshot.size >= settings.batchSize);

    console.log(`Processed ${batchCount} user documents for resetting payout count.`);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Unexpected error in reset payout count process:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

