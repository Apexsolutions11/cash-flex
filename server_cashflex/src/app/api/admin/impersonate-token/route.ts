import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';
import { auth } from '@/lib/firebase-admin';

export async function POST(request: NextRequest) {
  const adminContext = await verifyAdminAuth(request);

  if (!adminContext) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  let identifier: string | undefined;

  try {
    const body = await request.json();
    identifier = typeof body?.identifier === 'string' ? body.identifier.trim() : '';
  } catch {
    identifier = '';
  }

  if (!identifier) {
    return NextResponse.json({ error: 'identifier is required' }, { status: 400 });
  }

  try {
    const userRecord = identifier.includes('@')
      ? await auth.getUserByEmail(identifier)
      : await auth.getUser(identifier);

    const customToken = await auth.createCustomToken(userRecord.uid);

    return NextResponse.json({
      customToken,
      uid: userRecord.uid,
      email: userRecord.email ?? null,
      displayName: userRecord.displayName ?? null,
    });
  } catch (error) {
    console.error('Error generating impersonation token:', error);
    return NextResponse.json({ error: 'Failed to generate impersonation token' }, { status: 500 });
  }
}

