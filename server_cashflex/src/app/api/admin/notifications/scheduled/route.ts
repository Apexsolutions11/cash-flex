import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';

export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const snapshot = await db
      .collection('admin')
      .doc('notifications')
      .collection('scheduled')
      .orderBy('createdAt', 'desc')
      .get();

    const notifications = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title || '',
        body: data.body || '',
        scheduledFor: data.scheduledFor?.toDate().toISOString() || null,
        isRecurring: data.isRecurring || false,
        intervalMinutes: data.intervalMinutes || null,
        status: data.status || 'pending',
        createdAt: data.createdAt?.toDate().toISOString() || null,
        nextSendAt: data.nextSendAt?.toDate().toISOString() || null,
        lastSentAt: data.lastSentAt?.toDate().toISOString() || null,
        sendCount: data.sendCount || 0,
      };
    });

    return NextResponse.json({ notifications });
  } catch (error) {
    console.error('Error fetching scheduled notifications:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

