'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';

export default function ReferralPage() {
  const params = useParams();
  const code = params?.code as string;
  const [isDetecting, setIsDetecting] = useState(true);
  const [userAgent, setUserAgent] = useState<string>('');

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setUserAgent(navigator.userAgent || '');
      setIsDetecting(false);
    }
  }, []);

  useEffect(() => {
    if (!code || isDetecting) return;

    // Get current domain dynamically
    const currentOrigin = typeof window !== 'undefined' ? window.location.origin : '';
    const hostname = typeof window !== 'undefined' ? window.location.hostname : '';
    
    // Cash Flex configuration
    const packageName = 'com.cash.flex';
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.cash.flex';

    // Build Play Store URL with referral parameter
    const encodedReferrer = encodeURIComponent(`referralCode=${code}`);
    const playStoreWithReferrer = `${playStoreUrl}&referrer=${encodedReferrer}`;

    // Build deep link URL using current domain
    const deepLinkUrl = `${currentOrigin}/r/${code}`;

    // Check if Android
    const isAndroid = /Android/i.test(userAgent);

    if (isAndroid) {
      // Try app link first (for Android App Links)
      // The domain should match what's in assetlinks.json
      window.location.href = deepLinkUrl;
      
      // Fallback: If app doesn't open within 1.5 seconds, redirect to Play Store
      const fallbackTimer = setTimeout(() => {
        window.location.href = playStoreWithReferrer;
      }, 1500);

      // Clear timer if page unloads (app opened successfully)
      window.addEventListener('beforeunload', () => {
        clearTimeout(fallbackTimer);
      });
      
      // Also try intent URL as a backup for devices that don't support app links
      const intentUrl = `intent://${hostname}/r/${code}#Intent;scheme=https;package=${packageName};S.browser_fallback_url=${encodeURIComponent(playStoreWithReferrer)};end`;
      
      // Try intent URL after a short delay if app link didn't work
      setTimeout(() => {
        if (document.visibilityState === 'visible') {
          // Page is still visible, app didn't open, try intent
          window.location.href = intentUrl;
        }
      }, 500);
    } else {
      // For non-Android, just redirect to Play Store
      window.location.href = playStoreWithReferrer;
    }
  }, [code, isDetecting, userAgent]);

  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      backgroundColor: '#1a1a1a',
      color: '#fff',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      padding: '20px',
      textAlign: 'center',
    }}>
      <div style={{
        maxWidth: '400px',
        width: '100%',
      }}>
        <h1 style={{ fontSize: '24px', marginBottom: '16px', fontWeight: 'bold' }}>
          Opening App...
        </h1>
        <p style={{ fontSize: '16px', color: '#aaa', marginBottom: '24px' }}>
          {isDetecting ? 'Detecting device...' : 'Redirecting you to the app...'}
        </p>
        <div style={{
          width: '50px',
          height: '50px',
          border: '4px solid #333',
          borderTopColor: '#3b82f6',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite',
          margin: '0 auto',
        }} />
        <style jsx>{`
          @keyframes spin {
            to { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    </div>
  );
}
