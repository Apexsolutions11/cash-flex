import { NextRequest, NextResponse } from 'next/server';
import { db, admin } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';

// GET - Retrieve app data
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
      const appDataDoc = await db.collection('admin').doc('appData').get();
      
      if (!appDataDoc.exists) {
        return NextResponse.json({});
      }

      return NextResponse.json(appDataDoc.data());
    } catch (dbError: any) {
      // Catch Firebase Admin SDK authentication errors
      if (dbError?.code === 16 || dbError?.message?.includes('UNAUTHENTICATED') || dbError?.message?.includes('ACCESS_TOKEN_EXPIRED')) {
        console.error('Firebase Admin authentication error:', dbError);
        return NextResponse.json(
          { 
            error: 'Firebase Admin authentication failed. Please check your FIREBASE_SERVICE_ACCOUNT environment variable.',
            details: 'The service account credentials may be invalid or expired.'
          },
          { status: 500 }
        );
      }
      throw dbError;
    }
  } catch (error: any) {
    console.error('Error fetching app data:', error);
    
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

// POST - Update app data
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();

    // Normalize fields to avoid "missing" or invalid types (e.g. NaN -> null) coming from the UI.
    const normalized: Record<string, any> = { ...(body ?? {}) };

    const coerceNonNegativeInt = (v: any): number => {
      if (typeof v === 'number' && Number.isFinite(v)) return Math.max(0, Math.trunc(v));
      if (typeof v === 'string') {
        const n = Number(v);
        if (Number.isFinite(n)) return Math.max(0, Math.trunc(n));
      }
      return 0;
    };

    // Coin conversion rates (coins per 1 unit)
    normalized.indiaCoinCurFactor = coerceNonNegativeInt(normalized.indiaCoinCurFactor);
    normalized.foreignCoinCurFactor = coerceNonNegativeInt(normalized.foreignCoinCurFactor);
    
    // Daily game limit (must be at least 1)
    if (normalized.dailyGameLimit !== undefined) {
      const limit = coerceNonNegativeInt(normalized.dailyGameLimit);
      normalized.dailyGameLimit = limit > 0 ? limit : 10; // Default to 10 if 0 or invalid
    }
    
    // Geemee offerwall reward coins (must be non-negative)
    if (normalized.geemeeOfferwallRewardCoins !== undefined) {
      normalized.geemeeOfferwallRewardCoins = coerceNonNegativeInt(normalized.geemeeOfferwallRewardCoins);
    }
    
    // Validate normalUserTrackingParams - must be an array of strings
    if (normalized.normalUserTrackingParams !== undefined) {
      if (!Array.isArray(normalized.normalUserTrackingParams)) {
        return NextResponse.json(
          { error: 'normalUserTrackingParams must be an array' },
          { status: 400 }
        );
      }
      // Filter out empty strings and ensure all items are strings
      normalized.normalUserTrackingParams = normalized.normalUserTrackingParams
        .filter((param: any) => typeof param === 'string' && param.trim().length > 0)
        .map((param: string) => param.trim().toLowerCase());
    }
    
    try {
      await db.collection('admin').doc('appData').set(normalized, { merge: true });

      // Generate new token when app data changes
      try {
        const { genOrderID } = await import('@/lib/helpers/other-service');
        const newToken = await genOrderID();
        await db.collection('admin').doc('tokens').update({
          appDataToken: newToken,
        });
      } catch (tokenError) {
        // Log but don't fail if token update fails
        console.warn('Failed to update app data token:', tokenError);
      }

      return NextResponse.json({ success: true, message: 'App data updated successfully' });
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
  } catch (error: any) {
    console.error('Error updating app data:', error);
    
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


