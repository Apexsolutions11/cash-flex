import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import { db, admin } from '@/lib/firebase-admin';
import { addRewardRecord } from '@/lib/helpers/record-helper/reward-record';

// POST - Grant coins to a user
export async function POST(
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
    const { coins, reason } = body;

    if (!coins || typeof coins !== 'number' || coins <= 0) {
      return NextResponse.json(
        { error: 'coins must be a positive number' },
        { status: 400 }
      );
    }

    // Get user document
    let userRef, userDoc, userData;
    try {
      userRef = db.collection('users').doc(uid);
      userDoc = await userRef.get();

      if (!userDoc.exists) {
        return NextResponse.json({ error: 'User not found' }, { status: 404 });
      }

      userData = userDoc.data();
    } catch (dbError: any) {
      // Catch Firebase Admin SDK authentication errors
      if (dbError?.code === 16 || dbError?.message?.includes('UNAUTHENTICATED') || dbError?.message?.includes('ACCESS_TOKEN_EXPIRED')) {
        console.error('Firebase Admin authentication error:', dbError);
        return NextResponse.json(
          { 
            error: 'Firebase Admin authentication failed. Please check your FIREBASE_SERVICE_ACCOUNT environment variable.',
            details: 'The service account credentials may be invalid or expired. Please verify your .env.local file has the correct FIREBASE_SERVICE_ACCOUNT value.'
          },
          { status: 500 }
        );
      }
      throw dbError;
    }

    const currentCoins = userData?.coins || 0;
    const currentTotalCoins = userData?.totalCoins || 0;

    try {
      // Update user coins
      await userRef.update({
        coins: admin.firestore.FieldValue.increment(coins),
        totalCoins: admin.firestore.FieldValue.increment(coins),
      });

      // Add reward record
      try {
        await addRewardRecord(
          'admin_grant',
          uid,
          coins,
          {
            title: 'Congratulations 🎉',
            body: `You have received ${coins} coins by ${adminContext.email || adminContext.uid}`,
          }
        );
      } catch (rewardError) {
        // Log but don't fail if reward record fails
        console.warn('Failed to add reward record:', rewardError);
      }

      return NextResponse.json({
        success: true,
        message: `Successfully granted ${coins} coins to user`,
        uid,
        previousCoins: currentCoins,
        newCoins: currentCoins + coins,
        previousTotalCoins: currentTotalCoins,
        newTotalCoins: currentTotalCoins + coins,
        grantedCoins: coins,
      });
    } catch (updateError: any) {
      if (updateError?.code === 16 || updateError?.message?.includes('UNAUTHENTICATED')) {
        console.error('Firebase Admin authentication error during update:', updateError);
        return NextResponse.json(
          { 
            error: 'Firebase Admin authentication failed during update. Please check your FIREBASE_SERVICE_ACCOUNT environment variable.',
            details: updateError.message
          },
          { status: 500 }
        );
      }
      throw updateError;
    }
  } catch (error: any) {
    console.error('Error granting coins:', error);
    
    // Provide more specific error messages
    if (error?.code === 16 || error?.message?.includes('UNAUTHENTICATED')) {
      return NextResponse.json(
        { 
          error: 'Firebase authentication failed. Please check your FIREBASE_SERVICE_ACCOUNT environment variable.',
          details: error.message 
        },
        { status: 500 }
      );
    }
    
    return NextResponse.json(
      { 
        error: 'Internal server error',
        details: error?.message || 'Unknown error occurred'
      },
      { status: 500 }
    );
  }
}

