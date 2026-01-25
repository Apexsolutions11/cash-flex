import { NextRequest } from 'next/server';
import { auth } from '../firebase-admin';

export interface AuthContext {
  uid: string;
  email?: string;
  token: any;
}

export async function verifyAuth(request: NextRequest): Promise<AuthContext | null> {
  try {
    const authHeader = request.headers.get('authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null;
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(token);
    
    return {
      uid: decodedToken.uid,
      email: decodedToken.email,
      token: decodedToken,
    };
  } catch (error) {
    console.error('Auth verification error:', error);
    return null;
  }
}

export function getRequestIpAddress(request: NextRequest): string {
  const forwarded = request.headers.get('x-forwarded-for');
  if (forwarded) {
    return forwarded.split(',')[0].trim();
  }
  const realIp = request.headers.get('x-real-ip');
  return realIp || '';
}

