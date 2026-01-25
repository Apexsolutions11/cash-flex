import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';

// GET - Retrieve server data
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const serverDataDoc = await db.collection('admin').doc('serverData').get();
    
    if (!serverDataDoc.exists) {
      return NextResponse.json({
        link: '',
        walletEnabled: false,
      });
    }

    return NextResponse.json(serverDataDoc.data());
  } catch (error) {
    console.error('Error fetching server data:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST - Update server data
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    
    const updateData: any = {};
    if (body.link !== undefined) {
      updateData.link = body.link;
    }
    if (body.walletEnabled !== undefined) {
      updateData.walletEnabled = Boolean(body.walletEnabled);
    }

    await db.collection('admin').doc('serverData').set(updateData, { merge: true });

    return NextResponse.json({ success: true, message: 'Server data updated successfully' });
  } catch (error) {
    console.error('Error updating server data:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

