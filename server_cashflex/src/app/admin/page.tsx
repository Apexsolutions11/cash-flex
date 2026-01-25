'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function AdminPanel() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to app-data page
    router.replace('/admin/app-data');
  }, [router]);

  return null;
}
