'use client';

import { ReactNode, useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { getFirebaseAuth } from '@/lib/firebase-client';
import { onAuthStateChanged } from 'firebase/auth';
import { AdminSidebar } from '@/components/admin-sidebar';
import { ThemeSwitcher } from '@/components/theme-switcher';
import { SidebarInset, SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { Loader2 } from 'lucide-react';

export default function AdminLayout({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [authReady, setAuthReady] = useState(false);
  const [loading, setLoading] = useState(true);
  const isLoginRoute = pathname === '/admin/login';
  
  useEffect(() => {
    const auth = getFirebaseAuth();
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        setAuthReady(true);
        setLoading(false);
      } else {
        setAuthReady(true);
        setLoading(false);
        if (pathname !== '/admin/login') {
          router.push('/admin/login');
        }
      }
    });

    return () => unsubscribe();
  }, [router, pathname]);
  
  // Extract the active tab from pathname
  const getActiveTab = (): string => {
    if (pathname === '/admin') return 'app-data';
    const segments = pathname.split('/');
    return segments[segments.length - 1] || 'app-data';
  };

  const activeTab = getActiveTab();

  const PAGE_META: Record<
    string,
    { title: string; description: string }
  > = {
    'app-data': {
      title: 'App Data',
      description: 'Core app configuration and integration settings.',
    },
    'server-data': {
      title: 'Server Data',
      description: 'Server settings and runtime flags.',
    },
    settings: {
      title: 'Settings',
      description: 'Configure API keys, limits, and system settings.',
    },
    tokens: {
      title: 'Tokens',
      description: 'Manage application tokens and secrets.',
    },
    'test-token': {
      title: 'Admin Test Token',
      description: 'Generate ID tokens for testing and impersonation.',
    },
    stats: {
      title: 'Statistics',
      description: 'Analytics and provider breakdowns.',
    },
    'review-tasks': {
      title: 'Review Tasks',
      description: 'Manage review offers shown in the app.',
    },
    'follow-tasks': {
      title: 'Follow Tasks',
      description: 'Manage follow-us tasks and rewards.',
    },
    'more-apps': {
      title: 'More Apps',
      description: 'Configure “More Apps” promotions and ranking.',
    },
    'promotion-apps': {
      title: 'Promotion Apps',
      description: 'Highlight placements and campaign settings.',
    },
    'layout-management': {
      title: 'Layout Management',
      description: 'Reorder and toggle components per layout and page.',
    },
    'wallet-management': {
      title: 'Wallet Management',
      description: 'Manage wallet catalog, methods, and denominations.',
    },
    notifications: {
      title: 'Notifications',
      description: 'Send and schedule push notifications to users.',
    },
    'user-management': {
      title: 'User Management',
      description: 'Manage users, view details, block users, and grant coins.',
    },
  };

  const pageMeta = PAGE_META[activeTab] ?? {
    title: 'Admin',
    description: 'Manage your application settings.',
  };

  if (!authReady || loading) {
    return (
      <div className="min-h-dvh flex items-center justify-center bg-[radial-gradient(circle_at_top,hsl(var(--primary))/18,transparent_55%),radial-gradient(circle_at_bottom,hsl(var(--accent))/18,transparent_55%),hsl(var(--background))]">
        <div className="flex items-center gap-3 rounded-xl border bg-card/60 px-5 py-4 shadow-sm backdrop-blur">
          <Loader2 className="h-5 w-5 animate-spin text-primary" />
          <div className="leading-tight">
            <p className="text-sm font-medium">Loading admin…</p>
            <p className="text-xs text-muted-foreground">Checking session</p>
          </div>
        </div>
      </div>
    );
}

  // Login should not be wrapped with the admin shell.
  if (isLoginRoute) {
    return <>{children}</>;
  }

  return (
    <SidebarProvider defaultOpen>
      <AdminSidebar activeTab={activeTab as any} />
      <SidebarInset className="min-h-dvh overflow-y-auto bg-[radial-gradient(circle_at_top,hsl(var(--primary))/14,transparent_55%),radial-gradient(circle_at_bottom,hsl(var(--accent))/14,transparent_55%),hsl(var(--background))]">
        <header className="sticky top-0 z-10 border-b bg-background/70 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4 px-4 py-4 md:px-8">
            <div className="flex items-center gap-2 min-w-0">
              <SidebarTrigger className="md:hidden" />
              <div className="min-w-0">
                <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  Admin
                </p>
                <h1 className="truncate text-2xl font-semibold tracking-tight md:text-3xl">
                  {pageMeta.title}
                </h1>
                <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">
                  {pageMeta.description}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <ThemeSwitcher />
            </div>
          </div>
        </header>

        <div className="mx-auto w-full max-w-7xl px-4 py-6 md:px-8 md:py-8">
          {children}
        </div>
      </SidebarInset>
    </SidebarProvider>
  );
}
