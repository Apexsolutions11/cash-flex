'use client';

import { getFirebaseAuth } from '@/lib/firebase-client';
import { PromotionAppsForm } from '@/components/promotion-apps-form';
import { Card, CardContent } from '@/components/ui/card';

export default function PromotionAppsPage() {
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

  return (
    <Card>
      <CardContent className="pt-6">
        <PromotionAppsForm onGetAuthToken={getAuthToken} />
      </CardContent>
    </Card>
  );
}

