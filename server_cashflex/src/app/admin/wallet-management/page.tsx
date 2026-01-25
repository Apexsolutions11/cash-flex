'use client';

import { getFirebaseAuth } from '@/lib/firebase-client';
import { WalletManagementForm } from '@/components/wallet-management-form';

export default function WalletManagementPage() {
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

  return <WalletManagementForm onGetAuthToken={getAuthToken} />;
}

