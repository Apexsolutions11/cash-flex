import { NextRequest, NextResponse } from 'next/server';
import { db, admin } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';

export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const requestBody = await request.json();
    const { title, body, scheduledFor, isRecurring, intervalMinutes } = requestBody;

    if (!title || !body) {
      return NextResponse.json(
        { error: 'Title and body are required' },
        { status: 400 }
      );
    }

    if (isRecurring) {
      if (!scheduledFor || !intervalMinutes || intervalMinutes < 1) {
        return NextResponse.json(
          { error: 'Scheduled date and valid interval (minimum 1 minute) are required for recurring notifications' },
          { status: 400 }
        );
      }
    } else {
      if (!scheduledFor) {
        return NextResponse.json(
          { error: 'Scheduled date is required' },
          { status: 400 }
        );
      }
    }

    const scheduledDate = new Date(scheduledFor);
    const now = new Date();

    if (scheduledDate <= now) {
      return NextResponse.json(
        { error: 'Scheduled date must be in the future' },
        { status: 400 }
      );
    }

    // Calculate next send time for recurring notifications
    let nextSendAt: Date | undefined;
    if (isRecurring && intervalMinutes) {
      nextSendAt = scheduledDate;
    }

    const notificationRef = await db.collection('admin').doc('notifications').collection('scheduled').add({
      title: title.trim(),
      body: body.trim(),
      scheduledFor: admin.firestore.Timestamp.fromDate(scheduledDate),
      isRecurring: isRecurring || false,
      intervalMinutes: isRecurring ? intervalMinutes : null,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: adminContext.uid,
      nextSendAt: nextSendAt ? admin.firestore.Timestamp.fromDate(nextSendAt) : null,
      sendCount: 0,
      lastSentAt: null,
    });

    return NextResponse.json({ 
      success: true, 
      message: 'Notification scheduled successfully',
      id: notificationRef.id,
    });
  } catch (error) {
    console.error('Error scheduling notification:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

