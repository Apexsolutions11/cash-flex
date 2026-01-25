import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';

// GET - Retrieve tokens
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const tokensDoc = await db.collection('admin').doc('tokens').get();
    
    if (!tokensDoc.exists) {
      return NextResponse.json({
        appDataToken: '',
      });
    }

    return NextResponse.json(tokensDoc.data());
  } catch (error) {
    console.error('Error fetching tokens:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST - Update tokens
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    
    const updateData: any = {};
    if (body.appDataToken !== undefined) {
      updateData.appDataToken = body.appDataToken;
    }

    await db.collection('admin').doc('tokens').set(updateData, { merge: true });

    return NextResponse.json({ success: true, message: 'Tokens updated successfully' });
  } catch (error) {
    console.error('Error updating tokens:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

