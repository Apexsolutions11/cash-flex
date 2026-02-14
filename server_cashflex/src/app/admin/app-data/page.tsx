'use client';

import { useEffect, useState } from 'react';
import { getFirebaseAuth } from '@/lib/firebase-client';
import { AppDataForm } from '@/components/app-data-form';
import { Card, CardContent } from '@/components/ui/card';
import { Loader2 } from 'lucide-react';
import { StatusMessage } from '@/components/status-message';

export default function AppDataPage() {
  const [appData, setAppData] = useState<any>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<{ type: 'error'; text: string } | null>(null);

  useEffect(() => {
    fetchAppData();
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

  const fetchAppData = async () => {
    setLoading(true);
    setError(null);
    try {
      const token = await getAuthToken();
      
      // Add timeout to prevent hanging
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
      
      const response = await fetch('/api/admin/app-data', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        signal: controller.signal,
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Failed to fetch app data' }));
        throw new Error(errorData.error || `HTTP ${response.status}`);
      }
      
      const data = await response.json();
      setAppData(data || {});
    } catch (error: any) {
      console.error('Error fetching app data:', error);
      if (error.name === 'AbortError') {
        setError({ type: 'error', text: 'Request timed out. Please check your connection and try again.' });
      } else {
        setError({ type: 'error', text: error.message || 'Failed to load app data. Please refresh the page.' });
      }
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (data: any) => {
    setSaving(true);
    setError(null);
    try {
      const token = await getAuthToken();
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 15000); // 15 second timeout for save
      
      const response = await fetch('/api/admin/app-data', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(data),
        signal: controller.signal,
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Failed to save app data' }));
        throw new Error(errorData.error || `HTTP ${response.status}`);
      }
      
      const result = await response.json();
      setAppData(data); // Update local state with saved data
      
      // Refresh data to get any server-side modifications
      await fetchAppData();
    } catch (error: any) {
      console.error('Error saving app data:', error);
      if (error.name === 'AbortError') {
        setError({ type: 'error', text: 'Save request timed out. Please try again.' });
      } else {
        setError({ type: 'error', text: error.message || 'Failed to save app data. Please try again.' });
      }
      throw error;
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-12 gap-4">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        <p className="text-sm text-muted-foreground">Loading app data...</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {error && (
        <StatusMessage
          type="error"
          message={error}
          onDismiss={() => setError(null)}
        />
      )}
      <Card>
        <CardContent className="pt-6">
          <AppDataForm
            initialData={appData}
            onSave={handleSave}
            saving={saving}
          />
        </CardContent>
      </Card>
    </div>
  );
}

