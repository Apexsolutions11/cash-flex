import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/middleware/auth';
import { db, admin } from '@/lib/firebase-admin';

export async function POST(request: NextRequest) {
  try {
    const authContext = await verifyAuth(request);

    if (!authContext) {
      return NextResponse.json(
        {
          response: 'failure',
          reason: 'Access denied',
        },
        { status: 401 },
      );
    }

    const uid = authContext.uid?.trim();

    if (!uid) {
      return NextResponse.json({
        response: 'failure',
        reason: 'UserId is not available',
      });
    }

    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return NextResponse.json({
        response: 'failure',
        reason: 'User not found',
      });
    }

    const userData = userDoc.data();
    const dailyGameCount = userData?.dailyGameCount ?? 0;

    // Get admin-configurable daily game limit from appData
    const appDataDoc = await db.collection('admin').doc('appData').get();
    const appData = appDataDoc.exists ? appDataDoc.data() : {};
    const dailyGameLimit = appData?.dailyGameLimit || 10;

    // Check if limit is reached (but still allow incrementing for tracking purposes)
    // The frontend should check this before allowing the game to start
    
    // Increment daily game count
    await userDoc.ref.update({
      dailyGameCount: admin.firestore.FieldValue.increment(1),
    });

    return NextResponse.json({
      response: 'success',
      dailyGameCount: dailyGameCount + 1,
      dailyGameLimit,
    });
  } catch (error) {
    console.error('Error incrementing game count:', error);
    return NextResponse.json(
      {
        response: 'failure',
        reason: 'Internal server error',
      },
      { status: 500 },
    );
  }
}

