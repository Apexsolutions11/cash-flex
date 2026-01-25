import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import { Timestamp } from 'firebase-admin/firestore';

// GET - Retrieve admin dashboard statistics
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get user count
    const usersSnapshot = await db.collection('users').count().get();
    const totalUsers = usersSnapshot.data().count;

    // Get active users (logged in last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const activeUsersSnapshot = await db
      .collection('users')
      .where('lastLoginTimestamp', '>=', Timestamp.fromDate(sevenDaysAgo))
      .count()
      .get();
    const activeUsers = activeUsersSnapshot.data().count;

    // Get total transactions
    const transactionsSnapshot = await db.collection('transactionRecord').count().get();
    const totalTransactions = transactionsSnapshot.data().count;

    // Get pending transactions
    const pendingTransactionsSnapshot = await db
      .collection('transactionRecord')
      .where('status', '==', 'processing')
      .count()
      .get();
    const pendingTransactions = pendingTransactionsSnapshot.data().count;

    // Get total rewards
    const rewardsSnapshot = await db.collection('rewardRecord').count().get();
    const totalRewards = rewardsSnapshot.data().count;

    return NextResponse.json({
      totalUsers,
      activeUsers,
      totalTransactions,
      pendingTransactions,
      totalRewards,
    });
  } catch (error) {
    console.error('Error fetching admin stats:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}


