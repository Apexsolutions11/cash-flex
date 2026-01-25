'use client';

import { getFirebaseAuth } from '@/lib/firebase-client';
import { StatsView } from '@/components/stats-view';
import { Card, CardContent } from '@/components/ui/card';

export default function StatsPage() {
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
        <StatsView onGetAuthToken={getAuthToken} />
      </CardContent>
    </Card>
  );
}

