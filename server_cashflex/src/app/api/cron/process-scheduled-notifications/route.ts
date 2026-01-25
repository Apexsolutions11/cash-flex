import { NextRequest, NextResponse } from 'next/server';
import { db, admin } from '@/lib/firebase-admin';
import { verifyCronAuth } from '@/lib/middleware/cron-auth';
import * as other from '@/lib/helpers/other-service';

export async function POST(request: NextRequest) {
  if (!verifyCronAuth(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const now = admin.firestore.Timestamp.now();
    const nowDate = now.toDate();

    // Get all active scheduled notifications
    // We need to check both:
    // 1. One-time notifications: scheduledFor <= now (where nextSendAt is null)
    // 2. Recurring notifications: nextSendAt <= now
    const activeSnapshot = await db
      .collection('admin')
      .doc('notifications')
      .collection('scheduled')
      .where('status', '==', 'active')
      .get();

    const processedNotifications = [];

    for (const doc of activeSnapshot.docs) {
      const notification = doc.data();
      const scheduledFor = notification.scheduledFor?.toDate();
      const nextSendAt = notification.nextSendAt?.toDate();
      
      // For one-time notifications, check scheduledFor
      // For recurring notifications, check nextSendAt
      let shouldProcess = false;
      let timeToCheck: Date | null = null;

      if (notification.isRecurring) {
        // Recurring notification: check nextSendAt
        if (nextSendAt && nextSendAt <= nowDate) {
          shouldProcess = true;
          timeToCheck = nextSendAt;
        }
      } else {
        // One-time notification: check scheduledFor (and nextSendAt should be null)
        if (scheduledFor && scheduledFor <= nowDate && !nextSendAt) {
          shouldProcess = true;
          timeToCheck = scheduledFor;
        }
      }

      if (!shouldProcess || !timeToCheck) {
        continue;
      }

      try {
        // Send the notification
        await other.sendTopicNotification({
          notification: {
            title: notification.title,
            body: notification.body,
          },
          topic: 'all',
        });

        // Log the notification
        await db.collection('admin').doc('notifications').collection('history').add({
          title: notification.title,
          body: notification.body,
          type: notification.isRecurring ? 'scheduled_recurring' : 'scheduled_once',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          scheduledNotificationId: doc.id,
        });

        const sendCount = (notification.sendCount || 0) + 1;

        if (notification.isRecurring && notification.intervalMinutes) {
          // Calculate next send time for recurring notification
          const intervalMs = notification.intervalMinutes * 60 * 1000;
          const newNextSendAt = new Date(timeToCheck.getTime() + intervalMs);

          await doc.ref.update({
            nextSendAt: admin.firestore.Timestamp.fromDate(newNextSendAt),
            lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
            sendCount,
          });
        } else {
          // One-time notification - mark as sent
          await doc.ref.update({
            status: 'sent',
            lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
            sendCount,
          });
        }

        processedNotifications.push({
          id: doc.id,
          title: notification.title,
          status: notification.isRecurring ? 'recurring' : 'sent',
        });
      } catch (error) {
        console.error(`Error processing notification ${doc.id}:`, error);
        // Continue processing other notifications even if one fails
      }
    }

    return NextResponse.json({
      success: true,
      processed: processedNotifications.length,
      notifications: processedNotifications,
    });
  } catch (error) {
    console.error('Error processing scheduled notifications:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

