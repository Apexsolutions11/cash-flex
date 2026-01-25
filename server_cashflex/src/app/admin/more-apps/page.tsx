'use client';

import { getFirebaseAuth } from '@/lib/firebase-client';
import { MoreAppsForm } from '@/components/more-apps-form';

export default function MoreAppsPage() {
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

  return <MoreAppsForm onGetAuthToken={getAuthToken} />;
}

