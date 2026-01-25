import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import { db, auth } from '@/lib/firebase-admin';

// PATCH - Block or unblock a user
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { uid } = await params;
    const body = await request.json();
    const { blocked, reason } = body;

    if (typeof blocked !== 'boolean') {
      return NextResponse.json(
        { error: 'blocked must be a boolean' },
        { status: 400 }
      );
    }

    // Update Firestore user document - use isBlocked field
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    const updateData: any = {
      isBlocked: blocked,
    };

    if (blocked && reason) {
      updateData.blockedReason = reason;
    } else if (!blocked) {
      updateData.blockedReason = null;
    }

    await userRef.update(updateData);

    // Also disable/enable the user in Firebase Auth
    try {
      await auth.updateUser(uid, {
        disabled: blocked,
      });
    } catch (error) {
      console.warn(`Failed to update Firebase Auth user ${uid}:`, error);
      // Continue even if Auth update fails
    }

    return NextResponse.json({
      success: true,
      message: blocked ? 'User blocked successfully' : 'User unblocked successfully',
      uid,
      isBlocked: blocked,
    });
  } catch (error) {
    console.error('Error blocking/unblocking user:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

