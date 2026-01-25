import { NextRequest, NextResponse } from 'next/server';
import { db, admin } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import * as other from '@/lib/helpers/other-service';

export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const requestBody = await request.json();
    const { title, body } = requestBody;

    if (!title || !body) {
      return NextResponse.json(
        { error: 'Title and body are required' },
        { status: 400 }
      );
    }

    // Send notification to all users via topic
    await other.sendTopicNotification({
      notification: {
        title: title.trim(),
        body: body.trim(),
      },
      topic: 'all',
    });

    // Also log the notification
    await db.collection('admin').doc('notifications').collection('history').add({
      title: title.trim(),
      body: body.trim(),
      type: 'broadcast',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentBy: adminContext.uid,
    });

    return NextResponse.json({ 
      success: true, 
      message: 'Notification sent successfully to all users' 
    });
  } catch (error) {
    console.error('Error sending notification:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

