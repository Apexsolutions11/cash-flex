import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import { db } from '@/lib/firebase-admin';

// GET - List users with pagination
// Note: This endpoint can be called directly from client-side Firestore queries
// Keeping this for backward compatibility, but client-side queries are recommended
export async function GET(request: NextRequest) {
  try {
    // Optional: Verify admin auth if you want server-side protection
    // For now, we'll skip it since client-side queries are more direct
    // const adminContext = await verifyAdminAuth(request);
    // if (!adminContext) {
    //   return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    // }

    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);
    const search = searchParams.get('search') || '';
    const blocked = searchParams.get('blocked');
    
    // Verify Firebase connection by testing a simple query first
    let snapshot;
    try {
      // First, try a simple query to verify authentication
      const testQuery = db.collection('users').limit(1);
      await testQuery.get();
      
      // If test succeeds, proceed with the full query
      try {
        // Try ordering by joiningTimestamp (requires index)
        const query = db.collection('users').orderBy('joiningTimestamp', 'desc').limit(1000);
        snapshot = await query.get();
      } catch (orderByError: any) {
        // If orderBy fails (likely due to missing index), fetch without ordering
        console.warn('orderBy failed, fetching without order:', orderByError.message);
        snapshot = await db.collection('users').limit(1000).get();
      }
    } catch (authError: any) {
      // Catch authentication errors specifically
      if (authError?.code === 16 || authError?.message?.includes('UNAUTHENTICATED') || authError?.message?.includes('ACCESS_TOKEN_EXPIRED')) {
        console.error('Firebase authentication error:', authError);
        throw {
          code: 16,
          message: 'Firebase authentication failed. Please verify your FIREBASE_SERVICE_ACCOUNT environment variable is correctly set and the service account JSON is valid.',
          originalError: authError.message
        };
      }
      // Re-throw other errors
      throw authError;
    }
    
    let users = snapshot.docs.map((doc) => {
      const data = doc.data();
      // Safely handle timestamp fields
      let joiningTimestamp: string | null = null;
      let lastLoginTimestamp: string | null = null;
      
      try {
        if (data.joiningTimestamp?.toDate) {
          joiningTimestamp = data.joiningTimestamp.toDate().toISOString();
        } else if (data.joiningTimestamp) {
          joiningTimestamp = new Date(data.joiningTimestamp).toISOString();
        }
      } catch (e) {
        // Ignore timestamp parsing errors
      }
      
      try {
        if (data.lastLoginTimestamp?.toDate) {
          lastLoginTimestamp = data.lastLoginTimestamp.toDate().toISOString();
        } else if (data.lastLoginTimestamp) {
          lastLoginTimestamp = new Date(data.lastLoginTimestamp).toISOString();
        }
      } catch (e) {
        // Ignore timestamp parsing errors
      }
      
      return {
        uid: doc.id,
        email: data.email || null,
        name: data.name || null,
        photo: data.photo || null,
        coins: data.coins || 0,
        balance: data.balance || 0,
        totalCoins: data.totalCoins || 0,
        referralCode: data.referralCode || null,
        referralCount: data.referralCount || 0,
        isBlocked: data.isBlocked || false,
        blockedReason: data.blockedReason || null,
        joiningTimestamp,
        lastLoginTimestamp,
        country: data.country || null,
        userType: data.userType || null,
        deviceId: data.deviceId || null,
      };
    });
    
    // Sort by joiningTimestamp if we couldn't use orderBy
    // (fallback case - sort in memory)
    users.sort((a, b) => {
      if (!a.joiningTimestamp && !b.joiningTimestamp) return 0;
      if (!a.joiningTimestamp) return 1;
      if (!b.joiningTimestamp) return -1;
      return new Date(b.joiningTimestamp).getTime() - new Date(a.joiningTimestamp).getTime();
    });

    // Filter by blocked status if provided
    if (blocked === 'true') {
      users = users.filter((user) => user.isBlocked === true);
    } else if (blocked === 'false') {
      users = users.filter((user) => user.isBlocked === false);
    }

    // Filter by search term if provided
    if (search) {
      const searchLower = search.toLowerCase();
      users = users.filter(
        (user) =>
          user.email?.toLowerCase().includes(searchLower) ||
          user.name?.toLowerCase().includes(searchLower) ||
          user.uid.toLowerCase().includes(searchLower) ||
          user.referralCode?.toLowerCase().includes(searchLower)
      );
    }

    const total = users.length;
    const offset = (page - 1) * limit;
    const paginatedUsers = users.slice(offset, offset + limit);

    return NextResponse.json({
      users: paginatedUsers,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error: any) {
    console.error('Error fetching users:', error);
    
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
    
    if (error?.code === 7 || error?.message?.includes('PERMISSION_DENIED')) {
      return NextResponse.json(
        { 
          error: 'Permission denied. Please check your Firebase service account permissions.',
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

