import { NextRequest } from 'next/server';

export function verifyCronAuth(request: NextRequest): boolean {
  const passwordHeader = request.headers.get('password');
  const cronSecret = process.env.CRON_SECRET;

  if (!cronSecret || !passwordHeader) {
    return false;
  }

  return passwordHeader.trim() === cronSecret.trim();
}

