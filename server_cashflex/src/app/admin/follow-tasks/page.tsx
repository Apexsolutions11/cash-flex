'use client';

import { getFirebaseAuth } from '@/lib/firebase-client';
import { FollowTasksForm } from '@/components/follow-tasks-form';

export default function FollowTasksPage() {
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

  return <FollowTasksForm onGetAuthToken={getAuthToken} />;
}

