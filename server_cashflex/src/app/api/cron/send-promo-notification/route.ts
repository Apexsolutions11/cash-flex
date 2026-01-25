import { NextRequest, NextResponse } from 'next/server';
import { promoNotificationList } from '@/lib/helpers/notification-list';
import * as other from '@/lib/helpers/other-service';
import { verifyCronAuth } from '@/lib/middleware/cron-auth';

export async function POST(request: NextRequest) {

  if (!verifyCronAuth(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const randomNotification = promoNotificationList[Math.floor(Math.random() * promoNotificationList.length)];

  await other.sendTopicNotification({
    notification: randomNotification,
    topic: 'promo',
  });

  return NextResponse.json({ success: true });
}

