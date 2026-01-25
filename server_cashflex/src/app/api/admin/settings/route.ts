import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import { clearSettingsCache } from '@/lib/helpers/settings-helper';

// GET - Retrieve all admin settings
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const settingsDoc = await db.collection('admin').doc('settings').get();
    
    if (!settingsDoc.exists) {
      // Return default structure if no settings exist
      return NextResponse.json({
        secureKey: '',
        ipKey: '',
        payoutKey: '',
        adjoeKey: '',
        mysteryKey: '',
        adminEmail: '',
        appName: 'Cash Flex',
        appNameSH: 'GR',
        dailyMaxPayout: 1,
        referrerCommision: 0.5,
        batchSize: 5000,
      });
    }

    return NextResponse.json(settingsDoc.data());
  } catch (error) {
    console.error('Error fetching admin settings:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST/PUT - Update admin settings
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    
    // Validate required fields
    const allowedFields = [
      'secureKey',
      'ipKey',
      'payoutKey',
      'adjoeKey',
      'mysteryKey',
      'adminEmail',
      'appName',
      'appNameSH',
      'dailyMaxPayout',
      'referrerCommision',
      'batchSize',
    ];

    const updateData: any = {};
    for (const field of allowedFields) {
      if (body[field] !== undefined) {
        updateData[field] = body[field];
      }
    }

    // Validate numeric fields
    if (updateData.dailyMaxPayout !== undefined) {
      updateData.dailyMaxPayout = Number(updateData.dailyMaxPayout);
    }
    if (updateData.referrerCommision !== undefined) {
      updateData.referrerCommision = Number(updateData.referrerCommision);
    }
    if (updateData.batchSize !== undefined) {
      updateData.batchSize = Number(updateData.batchSize);
    }

    await db.collection('admin').doc('settings').set(updateData, { merge: true });

    // Clear cache so new settings are loaded
    clearSettingsCache();

    return NextResponse.json({ success: true, message: 'Settings updated successfully' });
  } catch (error) {
    console.error('Error updating admin settings:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}


