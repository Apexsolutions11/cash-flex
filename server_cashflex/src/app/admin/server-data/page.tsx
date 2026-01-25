'use client';

import { useEffect, useState } from 'react';
import { getFirebaseAuth } from '@/lib/firebase-client';
import { ServerDataForm } from '@/components/server-data-form';
import { Card, CardContent } from '@/components/ui/card';
import { Loader2 } from 'lucide-react';

export default function ServerDataPage() {
  const [serverData, setServerData] = useState<any>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchServerData();
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

  const fetchServerData = async () => {
    try {
      const token = await getAuthToken();
      const response = await fetch('/api/admin/server-data', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setServerData(data || {});
      }
    } catch (error) {
      console.error('Error fetching server data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (data: any) => {
    setSaving(true);
    try {
      const token = await getAuthToken();
      const response = await fetch('/api/admin/server-data', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to save server data');
      }

      setServerData(data);
    } catch (error) {
      console.error('Error saving server data:', error);
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
        <ServerDataForm
          initialData={serverData}
          onSave={handleSave}
          saving={saving}
        />
      </CardContent>
    </Card>
  );
}

