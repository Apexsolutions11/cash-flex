'use client';

import { getFirebaseAuth } from '@/lib/firebase-client';
import { ReviewTasksForm } from '@/components/review-tasks-form';

export default function ReviewTasksPage() {
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

  return <ReviewTasksForm onGetAuthToken={getAuthToken} />;
}

