import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth, getRequestIpAddress } from '@/lib/middleware/auth';
import * as ip from '@/lib/helpers/ip-service';

export async function POST(request: NextRequest) {
  try {
    const authContext = await verifyAuth(request);

    if (!authContext) {
      return NextResponse.json(
        {
          response: 'failure',
          reason: 'Access denied',
        },
        { status: 401 },
      );
    }

    const userId = authContext.uid.trim();
    const email = authContext.email?.trim() || '';
    const country = request.headers.get('x-appengine-country')?.toString() || '';
    const ipAddress = getRequestIpAddress(request);

    // Extract classification data from request body
    let classificationOptions: {
      referralId?: string;
      gclid?: string;
      fbclid?: string;
      trackingParams?: Record<string, string>;
      hasLocalApps?: boolean;
      isVpn?: boolean;
      isEmulator?: boolean;
      installedApps?: string[];
    } = {};

    try {
      const body = await request.json();
      if (body.referralId) classificationOptions.referralId = String(body.referralId).trim();
      if (body.gclid) classificationOptions.gclid = String(body.gclid).trim();
      if (body.fbclid) classificationOptions.fbclid = String(body.fbclid).trim();
      if (body.trackingParams && typeof body.trackingParams === 'object') {
        // Convert all keys to lowercase for consistent comparison
        const normalizedParams: Record<string, string> = {};
        for (const [key, value] of Object.entries(body.trackingParams)) {
          if (typeof value === 'string' && value.trim().length > 0) {
            normalizedParams[key.toLowerCase().trim()] = String(value).trim();
          }
        }
        classificationOptions.trackingParams = normalizedParams;
      }
      if (typeof body.hasLocalApps === 'boolean') classificationOptions.hasLocalApps = body.hasLocalApps;
      if (typeof body.isVpn === 'boolean') classificationOptions.isVpn = body.isVpn;
      if (typeof body.isEmulator === 'boolean') classificationOptions.isEmulator = body.isEmulator;
      if (Array.isArray(body.installedApps)) classificationOptions.installedApps = body.installedApps;
    } catch (e) {
      // Request body parsing failed or no body provided - continue with empty options
      // This maintains backward compatibility
    }

    await ip.trackIp(ipAddress, userId, country, email, classificationOptions);

    return NextResponse.json({
      response: 'success',
    });
  } catch (error) {
    console.error('Failed to authenticate user: ', error);
    return NextResponse.json(
      {
        response: 'failure',
        reason: 'Internal server error',
      },
      { status: 500 },
    );
  }
}

