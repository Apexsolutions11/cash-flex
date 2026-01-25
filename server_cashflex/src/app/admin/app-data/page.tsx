'use client';

import { useEffect, useState } from 'react';
import { getFirestoreClient } from '@/lib/firebase-client';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { AppDataForm } from '@/components/app-data-form';
import { Card, CardContent } from '@/components/ui/card';
import { Loader2 } from 'lucide-react';

export default function AppDataPage() {
  const [appData, setAppData] = useState<any>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchAppData();
  }, []);

  const fetchAppData = async () => {
    try {
      const db = getFirestoreClient();
      const appDataDoc = await getDoc(doc(db, 'admin', 'appData'));
      
      if (appDataDoc.exists()) {
        setAppData(appDataDoc.data() || {});
      } else {
        setAppData({});
      }
    } catch (error) {
      console.error('Error fetching app data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (data: any) => {
    setSaving(true);
    try {
      const db = getFirestoreClient();
      
      // Normalize fields to avoid invalid types (same logic as API)
      const normalized: Record<string, any> = { ...data };
      
      const coerceNonNegativeInt = (v: any): number => {
        if (typeof v === 'number' && Number.isFinite(v)) return Math.max(0, Math.trunc(v));
        if (typeof v === 'string') {
          const n = Number(v);
          if (Number.isFinite(n)) return Math.max(0, Math.trunc(n));
        }
        return 0;
      };
      
      // Coin conversion rates
      normalized.indiaCoinCurFactor = coerceNonNegativeInt(normalized.indiaCoinCurFactor);
      normalized.foreignCoinCurFactor = coerceNonNegativeInt(normalized.foreignCoinCurFactor);
      
      // Daily game limit
      if (normalized.dailyGameLimit !== undefined) {
        const limit = coerceNonNegativeInt(normalized.dailyGameLimit);
        normalized.dailyGameLimit = limit > 0 ? limit : 10;
      }
      
      // Geemee offerwall reward coins
      if (normalized.geemeeOfferwallRewardCoins !== undefined) {
        normalized.geemeeOfferwallRewardCoins = coerceNonNegativeInt(normalized.geemeeOfferwallRewardCoins);
      }
      
      // Validate normalUserTrackingParams
      if (normalized.normalUserTrackingParams !== undefined) {
        if (!Array.isArray(normalized.normalUserTrackingParams)) {
          throw new Error('normalUserTrackingParams must be an array');
        }
        normalized.normalUserTrackingParams = normalized.normalUserTrackingParams
          .filter((param: any) => typeof param === 'string' && param.trim().length > 0)
          .map((param: string) => param.trim().toLowerCase());
      }
      
      // Save to Firestore
      await setDoc(doc(db, 'admin', 'appData'), normalized, { merge: true });
      
      // Note: Token generation would need to be done server-side if required
      // For now, we'll skip it since it's not critical for the save operation
      
      setAppData(normalized);
    } catch (error) {
      console.error('Error saving app data:', error);
      throw error;
    } finally {
      setSaving(false);
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
      <CardContent className="pt-6">
        <AppDataForm
          initialData={appData}
          onSave={handleSave}
          saving={saving}
        />
      </CardContent>
    </Card>
  );
}

