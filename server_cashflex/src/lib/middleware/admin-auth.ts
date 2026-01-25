import { NextRequest } from 'next/server';
import { verifyAuth } from './auth';

export interface AdminContext {
  uid: string;
  email?: string;
  isAdmin: boolean;
}

/**
 * Verifies if the request is from an authenticated user.
 * If user is authenticated via Firebase Auth, they are considered an admin.
 */
export async function verifyAdminAuth(request: NextRequest): Promise<AdminContext | null> {
  try {
    // Verify Firebase auth - if authenticated, user is admin
    const authContext = await verifyAuth(request);
    if (!authContext || !authContext.uid) {
      return null;
    }

    return {
      uid: authContext.uid,
      email: authContext.email,
      isAdmin: true,
    };
  } catch (error) {
    console.error('Admin auth verification error:', error);
    return null;
  }
}


