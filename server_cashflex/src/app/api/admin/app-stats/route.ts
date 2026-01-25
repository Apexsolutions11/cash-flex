import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';

interface StatsData {
  date: any;
  payoutByProvider: any;
  rewardByProvider: any;
  totalPayout: number;
  totalReferrerReward: number;
  totalReward: number;
  uploadTimestamp: any;
  usersJoined: number;
}

// GET - Retrieve app stats
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const year = searchParams.get('year') || new Date().getFullYear().toString();
    const month = searchParams.get('month');

    const statsRef = db.collection('appStats').doc(year);
    const yearDoc = await statsRef.get();
    
    if (!yearDoc.exists) {
      return NextResponse.json({ year, months: {} });
    }
    
    if (!month) {
      // Get all months for the year
      const monthsSnapshot = await statsRef.collection('months').get();
      const months: any = {};
      
      for (const monthDoc of monthsSnapshot.docs) {
        const datesSnapshot = await monthDoc.ref.collection('dates').get();
        const dates: any = {};
        
        for (const dateDoc of datesSnapshot.docs) {
          dates[dateDoc.id] = dateDoc.data();
        }
        
        months[monthDoc.id] = dates;
      }
      
      return NextResponse.json({ year, months });
    }

    // Get specific month
    const monthRef = statsRef.collection('months').doc(month);
    const monthDoc = await monthRef.get();
    
    if (!monthDoc.exists) {
      return NextResponse.json({ year, month, dates: {} });
    }
    
    const datesSnapshot = await monthRef.collection('dates').get();
    
    const dates: any = {};
    for (const dateDoc of datesSnapshot.docs) {
      dates[dateDoc.id] = dateDoc.data();
    }

    return NextResponse.json({ year, month, dates });
  } catch (error) {
    console.error('Error fetching app stats:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

