import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import * as other from '@/lib/helpers/other-service';
import { verifyCronAuth } from '@/lib/middleware/cron-auth';

export async function POST(request: NextRequest) {

  if (!verifyCronAuth(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const appDataDoc = await db.collection('admin').doc('appData').get();
    const tokensDoc = await db.collection('admin').doc('tokens').get();

    const appData = appDataDoc.data();
    const tokensData = tokensDoc.data();

    // Check if appData has changed (you might want to store previous state)
    // For now, we'll just update the token
    const newToken = await other.genOrderID();
    await db.collection('admin').doc('tokens').update({
      appDataToken: newToken,
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error in onAppDataChange:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

