"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { ChevronsUpDown, Copy, LogOut, Moon, Sun, User as UserIcon } from "lucide-react"
import { onAuthStateChanged, signOut, type User } from "firebase/auth"

import { getFirebaseAuth } from "@/lib/firebase-client"
import { useTheme } from "@/components/theme-provider"
import { cn } from "@/lib/utils"

function getInitials(input?: string | null) {
  const value = (input ?? "").trim()
  if (!value) return "A"
  const parts = value.split(/\s+/).filter(Boolean)
  const first = parts[0]?.[0] ?? "A"
  const second = parts.length > 1 ? parts[parts.length - 1]?.[0] ?? "" : ""
  return (first + second).toUpperCase()
}

function copyToClipboard(value: string) {
  return navigator.clipboard.writeText(value)
}

export function SidebarUserDropdown() {
  const router = useRouter()
  const { theme, setTheme } = useTheme()
  const [user, setUser] = React.useState<User | null>(null)
  const [copied, setCopied] = React.useState<null | "uid" | "email">(null)
  const detailsRef = React.useRef<HTMLDetailsElement | null>(null)

  React.useEffect(() => {
    const auth = getFirebaseAuth()
    return onAuthStateChanged(auth, (u) => setUser(u))
  }, [])

  React.useEffect(() => {
    const onClick = (event: MouseEvent) => {
      const el = detailsRef.current
      if (!el?.open) return
      if (event.target instanceof Node && el.contains(event.target)) return
      el.open = false
    }
    document.addEventListener("click", onClick)
    return () => document.removeEventListener("click", onClick)
  }, [])

  const close = () => {
    if (detailsRef.current) detailsRef.current.open = false
  }

  const handleLogout = async () => {
    const auth = getFirebaseAuth()
    await signOut(auth)
    close()
    router.push("/admin/login")
  }

  const handleCopyUid = async () => {
    if (!user?.uid) return
    try {
      await copyToClipboard(user.uid)
      setCopied("uid")
      setTimeout(() => setCopied(null), 1200)
      close()
    } catch {
      // no-op
    }
  }

  const handleCopyEmail = async () => {
    if (!user?.email) return
    try {
      await copyToClipboard(user.email)
      setCopied("email")
      setTimeout(() => setCopied(null), 1200)
      close()
    } catch {
      // no-op
    }
  }

  const toggleTheme = () => {
    setTheme(theme === "dark" ? "light" : "dark")
    close()
  }

  const displayName = user?.displayName || user?.email || "Admin"
  const initials = getInitials(user?.displayName || user?.email)

  return (
    <div className="relative">
      <details ref={detailsRef} className="group">
        <summary
          className={cn(
            "list-none rounded-md outline-none transition-colors",
            "cursor-pointer select-none",
            "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
            "focus-visible:ring-2 focus-visible:ring-sidebar-ring",
            "[&::-webkit-details-marker]:hidden"
          )}
        >
          <div className="flex items-center gap-2 rounded-md p-2">
            <div className="relative flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-md border bg-sidebar-accent text-sidebar-accent-foreground">
              {user?.photoURL ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={user.photoURL}
                  alt={displayName}
                  className="h-full w-full object-cover"
                  onError={(e) => {
                    ;(e.currentTarget as HTMLImageElement).style.display = "none"
                  }}
                />
              ) : (
                <span className="text-xs font-semibold">{initials}</span>
              )}
            </div>

            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium leading-tight">{displayName}</p>
              <p className="truncate text-xs text-sidebar-foreground/70 leading-tight">
                {user?.email || "Signed in"}
              </p>
            </div>

            <ChevronsUpDown className="h-4 w-4 shrink-0 text-sidebar-foreground/70" />
          </div>
        </summary>

        <div className="absolute bottom-full left-0 right-0 z-50 mb-2 overflow-hidden rounded-lg border bg-popover text-popover-foreground shadow-lg">
          <div className="px-3 py-2">
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <UserIcon className="h-3.5 w-3.5" />
              <span className="truncate">{user?.uid ? `UID: ${user.uid}` : "Account"}</span>
            </div>
          </div>
          <div className="h-px bg-border" />

          <button
            type="button"
            onClick={toggleTheme}
            className="flex w-full items-center gap-2 px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground"
          >
            {theme === "dark" ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            <span>Toggle theme</span>
          </button>

          <button
            type="button"
            onClick={handleCopyEmail}
            disabled={!user?.email}
            className="flex w-full items-center gap-2 px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground disabled:opacity-50"
          >
            <Copy className="h-4 w-4" />
            <span>{copied === "email" ? "Copied email" : "Copy email"}</span>
          </button>

          <button
            type="button"
            onClick={handleCopyUid}
            disabled={!user?.uid}
            className="flex w-full items-center gap-2 px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground disabled:opacity-50"
          >
            <Copy className="h-4 w-4" />
            <span>{copied === "uid" ? "Copied UID" : "Copy UID"}</span>
          </button>

          <div className="h-px bg-border" />

          <button
            type="button"
            onClick={handleLogout}
            className="flex w-full items-center gap-2 px-3 py-2 text-sm text-destructive hover:bg-destructive/10"
          >
            <LogOut className="h-4 w-4" />
            <span>Sign out</span>
          </button>
        </div>
      </details>
    </div>
  )
}


