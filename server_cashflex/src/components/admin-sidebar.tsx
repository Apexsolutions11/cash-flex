"use client"

import Link from "next/link"
import { useRouter } from "next/navigation"
import { getFirebaseAuth } from "@/lib/firebase-client"
import { signOut } from "firebase/auth"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarSeparator,
} from "@/components/ui/sidebar"
import { SidebarUserDropdown } from "@/components/sidebar-user-dropdown"
import {
  BarChart3,
  Database,
  Fingerprint,
  Grid2x2,
  HeartHandshake,
  Key,
  Layout,
  LogOut,
  Settings,
  Server,
  Sparkles,
  Star,
  Wallet,
  Bell,
  Users,
} from "lucide-react"

type TabType =
  | "app-data"
  | "server-data"
  | "settings"
  | "tokens"
  | "test-token"
  | "stats"
  | "review-tasks"
  | "follow-tasks"
  | "more-apps"
  | "promotion-apps"
  | "layout-management"
  | "wallet-management"
  | "notifications"
  | "user-management"

interface AdminSidebarProps {
  activeTab: TabType
}

export function AdminSidebar({ activeTab }: AdminSidebarProps) {
  const router = useRouter()

  const handleLogout = async () => {
    const auth = getFirebaseAuth()
    await signOut(auth)
    router.push("/admin/login")
  }

  const getHref = (tab: TabType) => {
    if (tab === "app-data") return "/admin"
    return `/admin/${tab}`
  }

  return (
    <Sidebar collapsible="icon" variant="sidebar" className="z-30">
      <SidebarHeader>
        <div className="flex flex-col leading-tight">
          <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Cash Flex
          </p>
          <h2 className="text-base font-semibold tracking-tight">Admin Console</h2>
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Configuration</SidebarGroupLabel>
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "app-data"}>
                <Link href={getHref("app-data")}>
                  <Database />
                  <span>App Data</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "server-data"}>
                <Link href={getHref("server-data")}>
                  <Server />
                  <span>Server Data</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "settings"}>
                <Link href={getHref("settings")}>
                  <Settings />
                  <span>Settings</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "tokens"}>
                <Link href={getHref("tokens")}>
                  <Key />
                  <span>Tokens</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>

        <SidebarSeparator />

        <SidebarGroup>
          <SidebarGroupLabel>Content</SidebarGroupLabel>
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "review-tasks"}>
                <Link href={getHref("review-tasks")}>
                  <Star />
                  <span>Review Tasks</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "follow-tasks"}>
                <Link href={getHref("follow-tasks")}>
                  <HeartHandshake />
                  <span>Follow Tasks</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "more-apps"}>
                <Link href={getHref("more-apps")}>
                  <Grid2x2 />
                  <span>More Apps</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "promotion-apps"}>
                <Link href={getHref("promotion-apps")}>
                  <Sparkles />
                  <span>Promotion Apps</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "layout-management"}>
                <Link href={getHref("layout-management")}>
                  <Layout />
                  <span>Layout Management</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "wallet-management"}>
                <Link href={getHref("wallet-management")}>
                  <Wallet />
                  <span>Wallet Management</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>

        <SidebarSeparator />

        <SidebarGroup>
          <SidebarGroupLabel>User Management</SidebarGroupLabel>
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "user-management"}>
                <Link href={getHref("user-management")}>
                  <Users />
                  <span>User Management</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>

        <SidebarSeparator />

        <SidebarGroup>
          <SidebarGroupLabel>Analytics & Tools</SidebarGroupLabel>
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "stats"}>
                <Link href={getHref("stats")}>
                  <BarChart3 />
                  <span>Statistics</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "notifications"}>
                <Link href={getHref("notifications")}>
                  <Bell />
                  <span>Notifications</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild isActive={activeTab === "test-token"}>
                <Link href={getHref("test-token")}>
                  <Fingerprint />
                  <span>Admin Test Token</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter className="space-y-2">
        <SidebarUserDropdown />
      </SidebarFooter>
    </Sidebar>
  )
}
