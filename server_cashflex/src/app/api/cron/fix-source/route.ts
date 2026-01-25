import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyCronAuth } from '@/lib/middleware/cron-auth';

export async function POST(request: NextRequest) {

  if (!verifyCronAuth(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const checkSubstrings = ['gclid', 'singular', 'mtg'];

  try {
    const usersSnapshot = await db
      .collection('users')
      .where('source', 'not-in', ['GoogleAd', 'Other'])
      .limit(200)
      .get();

    if (!usersSnapshot.empty) {
      const batch = db.batch();

      usersSnapshot.forEach((doc: any) => {
        batch.update(doc.ref, {
          source: checkSubstrings.some((sub) => doc.data().source.includes(sub))
            ? 'GoogleAd'
            : 'Other',
        });
      });

      await batch.commit();
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('❌ Server Error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

