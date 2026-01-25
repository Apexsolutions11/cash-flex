'use client';

import { useEffect, useState, useRef } from 'react';
import { getFirebaseApp, getFirebaseAuth } from '@/lib/firebase-client';
import { getApps, initializeApp } from 'firebase/app';
import { Auth, getAuth as getClientAuth, onAuthStateChanged, signInWithCustomToken, signOut } from 'firebase/auth';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Copy, Fingerprint, Loader2, RefreshCcw } from 'lucide-react';

export default function TestTokenPage() {
  const [token, setToken] = useState<string>('');
  const [impersonatedToken, setImpersonatedToken] = useState<string>('');
  const [impersonatedUser, setImpersonatedUser] = useState<{ uid: string; email?: string | null } | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [impersonateLoading, setImpersonateLoading] = useState(false);
  const [copyState, setCopyState] = useState<'idle' | 'copied' | 'error'>('idle');
  const [impersonateCopyState, setImpersonateCopyState] = useState<'idle' | 'copied' | 'error'>('idle');
  const [impersonateValue, setImpersonateValue] = useState('');
  const [impersonateError, setImpersonateError] = useState<string | null>(null);
  const impersonationAuthRef = useRef<Auth | null>(null);

  useEffect(() => {
    refreshToken();
  }, []);

  const getAuthToken = async (): Promise<string> => {
    const auth = getFirebaseAuth();
    const user = auth.currentUser;
    
    if (!user) {
      throw new Error('Not authenticated');
    }
    
    try {
      return await user.getIdToken(true);
    } catch (error) {
      throw new Error('Failed to get auth token');
    }
  };

  const refreshToken = async () => {
    setRefreshing(true);
    try {
      const freshToken = await getAuthToken();
      setToken(freshToken);
    } catch (error) {
      console.error('Error fetching ID token for testing:', error);
      setToken('');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const getImpersonationAuth = () => {
    if (impersonationAuthRef.current) {
      return impersonationAuthRef.current;
    }
    const baseApp = getFirebaseApp();
    const secondaryApp =
      getApps().find((app) => app.name === 'impersonation') ||
      initializeApp(baseApp.options, 'impersonation');
    const secondaryAuth = getClientAuth(secondaryApp);
    impersonationAuthRef.current = secondaryAuth;
    return secondaryAuth;
  };

  const handleImpersonate = async () => {
    const identifier = impersonateValue.trim();
    if (!identifier) {
      setImpersonateError('Enter a UID or email to impersonate.');
      return;
    }

    setImpersonateLoading(true);
    setImpersonateError(null);
    setImpersonatedToken('');
    setImpersonatedUser(null);

    try {
      const adminToken = await getAuthToken();
      const response = await fetch('/api/admin/impersonate-token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({ identifier }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || 'Failed to create impersonation token');
      }

      const data = await response.json();
      const impersonationAuth = getImpersonationAuth();

      await signOut(impersonationAuth).catch(() => {});

      const credential = await signInWithCustomToken(impersonationAuth, data.customToken);
      const idToken = await credential.user.getIdToken(true);

      setImpersonatedToken(idToken);
      setImpersonatedUser({
        uid: data.uid,
        email: data.email || credential.user.email || null,
      });
    } catch (error: any) {
      console.error('Impersonation error:', error);
      setImpersonateError(error?.message || 'Failed to impersonate user');
    } finally {
      setImpersonateLoading(false);
    }
  };

  const handleCopy = async () => {
    if (!token) return;

    try {
      await navigator.clipboard.writeText(token);
      setCopyState('copied');
      setTimeout(() => setCopyState('idle'), 1600);
    } catch (error) {
      console.error('Failed to copy token:', error);
      setCopyState('error');
      setTimeout(() => setCopyState('idle'), 1600);
    }
  };

  const handleImpersonateCopy = async () => {
    if (!impersonatedToken) return;

    try {
      await navigator.clipboard.writeText(impersonatedToken);
      setImpersonateCopyState('copied');
      setTimeout(() => setImpersonateCopyState('idle'), 1600);
    } catch (error) {
      console.error('Failed to copy impersonated token:', error);
      setImpersonateCopyState('error');
      setTimeout(() => setImpersonateCopyState('idle'), 1600);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  return (
    <Card>
      <CardContent className="space-y-6 pt-6">
        <div className="flex flex-wrap items-center gap-3">
          <Button onClick={refreshToken} disabled={refreshing} className="gap-2">
            <RefreshCcw className="h-4 w-4" />
            {refreshing ? 'Refreshing...' : 'Refresh token'}
          </Button>
          <Button variant="outline" onClick={handleCopy} disabled={!token} className="gap-2">
            <Copy className="h-4 w-4" />
            {copyState === 'copied' ? 'Copied!' : 'Copy token'}
          </Button>
          {copyState === 'error' && (
            <span className="text-sm text-destructive">Failed to copy</span>
          )}
        </div>

        <div className="space-y-2">
          <p className="text-sm font-medium text-muted-foreground">Current ID token</p>
          <Textarea
            readOnly
            value={token || 'No token available. Make sure you are signed in.'}
            className="min-h-[140px] font-mono"
          />
        </div>

        <div className="rounded-lg border bg-muted/40 p-4 space-y-3">
          <div className="space-y-1">
            <p className="text-sm font-medium">Impersonate a user</p>
            <p className="text-sm text-muted-foreground">
              Enter a UID or email to fetch that user&apos;s ID token without signing out of your admin session.
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            <Input
              placeholder="UID or email"
              value={impersonateValue}
              onChange={(e) => setImpersonateValue(e.target.value)}
              className="sm:flex-1"
            />
            <Button onClick={handleImpersonate} disabled={impersonateLoading} className="gap-2">
              {impersonateLoading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Fetching...
                </>
              ) : (
                <>
                  <Fingerprint className="h-4 w-4" />
                  Get user token
                </>
              )}
            </Button>
          </div>
          {impersonateError && <p className="text-sm text-destructive">{impersonateError}</p>}
          {impersonatedToken && (
            <div className="space-y-2">
              <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
                <span className="font-medium text-foreground">Impersonated user:</span>
                <span>{impersonatedUser?.uid}</span>
                {impersonatedUser?.email && <span>• {impersonatedUser.email}</span>}
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <Button variant="outline" onClick={handleImpersonateCopy} className="gap-2">
                  <Copy className="h-4 w-4" />
                  {impersonateCopyState === 'copied' ? 'Copied!' : 'Copy impersonated token'}
                </Button>
                {impersonateCopyState === 'error' && (
                  <span className="text-sm text-destructive">Failed to copy</span>
                )}
              </div>
              <Textarea
                readOnly
                value={impersonatedToken}
                className="min-h-[140px] font-mono"
              />
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

