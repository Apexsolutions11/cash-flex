'use client';

import { getFirebaseAuth } from '@/lib/firebase-client';
import { LayoutManagementForm } from '@/components/layout-management-form';

export default function LayoutManagementPage() {
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

  return <LayoutManagementForm onGetAuthToken={getAuthToken} />;
}

