import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import { db, auth } from '@/lib/firebase-admin';

// GET - Get user details by UID
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { uid } = await params;

    // Get user document from Firestore
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    const userData = userDoc.data();

    // Get Firebase Auth user record
    let authUser = null;
    try {
      authUser = await auth.getUser(uid);
    } catch (error) {
      console.warn(`Firebase Auth user not found for UID: ${uid}`);
    }

    // Get user's transactions
    const transactionsSnapshot = await db
      .collection('transactionRecord')
      .where('userId', '==', uid)
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const transactions = transactionsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        amount: data.amount || 0,
        status: data.status || null,
        timestamp: data.timestamp?.toDate().toISOString() || null,
        walletType: data.walletType || null,
      };
    });

    // Get user's reward records
    const rewardsSnapshot = await db
      .collection('rewardRecord')
      .where('userId', '==', uid)
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const rewards = rewardsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        coins: data.coins || 0,
        source: data.source || null,
        timestamp: data.timestamp?.toDate().toISOString() || null,
      };
    });

    return NextResponse.json({
      uid,
      email: userData?.email || authUser?.email || null,
      name: userData?.name || authUser?.displayName || null,
      photo: userData?.photo || authUser?.photoURL || null,
      coins: userData?.coins || 0,
      balance: userData?.balance || 0,
      totalCoins: userData?.totalCoins || 0,
      referralCode: userData?.referralCode || null,
      referralCount: userData?.referralCount || 0,
      referralEarning: userData?.referralEarning || 0,
      isBlocked: userData?.isBlocked || false,
      blockedReason: userData?.blockedReason || null,
      joiningTimestamp: userData?.joiningTimestamp?.toDate().toISOString() || null,
      lastLoginTimestamp: userData?.lastLoginTimestamp?.toDate().toISOString() || null,
      country: userData?.country || null,
      countryCode: userData?.countryCode || null,
      city: userData?.city || null,
      userType: userData?.userType || null,
      deviceId: userData?.deviceId || null,
      ipAddress: userData?.ipAddress || null,
      dailyPayoutCount: userData?.dailyPayoutCount || 0,
      totalPayoutCount: userData?.totalPayoutCount || 0,
      dailyGameCount: userData?.dailyGameCount || 0,
      energy: userData?.energy || 0,
      rated: userData?.rated || false,
      referred: userData?.referred || false,
      socialFollowed: userData?.socialFollowed || [],
      reviewedList: userData?.reviewedList || [],
      offersEarning: userData?.offersEarning || 0,
      rewardEarning: userData?.rewardEarning || 0,
      // Firebase Auth data
      emailVerified: authUser?.emailVerified || false,
      disabled: authUser?.disabled || false,
      creationTime: authUser?.metadata.creationTime || null,
      lastSignInTime: authUser?.metadata.lastSignInTime || null,
      // Recent activity
      recentTransactions: transactions,
      recentRewards: rewards,
    });
  } catch (error) {
    console.error('Error fetching user details:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

