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

    const energy = userDoc.data()?.energy ?? 0;

    if (energy >= 20) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Energy limit reached',
      });
    }

    await userDoc.ref.update({
      energy: admin.firestore.FieldValue.increment(1),
    });

    return NextResponse.json({
      response: 'success',
    });
  } catch (error) {
    return NextResponse.json(
      {
        response: 'failure',
        reason: error,
      },
      { status: 500 },
    );
  }
}

