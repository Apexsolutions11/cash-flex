"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { Loader2, Save } from "lucide-react"
import { Textarea } from "@/components/ui/textarea"
import { Switch } from "@/components/ui/switch"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { StatusMessage } from "@/components/status-message"
import { Badge } from "@/components/ui/badge"

type PromotionAppId = "app1" | "app2" | "app3" | "app4"

type BadgeVariant = "none" | "default" | "popular" | "new" | "hot"

interface PromotionApp {
  id: PromotionAppId
  enabled?: boolean
  photo?: string
  title?: string
  description?: string
  stars?: number
  coins?: number
  buttonText?: string
  playStoreUrl?: string
  tasks?: string[]
  minimumBackgroundTime?: number // in seconds
  badgeText?: string
  badgeVariant?: BadgeVariant
}

interface PromotionAppsFormProps {
  onGetAuthToken: () => Promise<string>
}

interface ApiResponse {
  app1?: Omit<PromotionApp, "id">
  app2?: Omit<PromotionApp, "id">
  app3?: Omit<PromotionApp, "id">
  app4?: Omit<PromotionApp, "id">
}

export function PromotionAppsForm({ onGetAuthToken }: PromotionAppsFormProps) {
  const [apps, setApps] = useState<Record<PromotionAppId, PromotionApp>>({
    app1: { id: "app1", enabled: true },
    app2: { id: "app2", enabled: true },
    app3: { id: "app3", enabled: true },
    app4: { id: "app4", enabled: true },
  })
  const [tasksText, setTasksText] = useState<Record<PromotionAppId, string>>({
    app1: "",
    app2: "",
    app3: "",
    app4: "",
  })
  const [loading, setLoading] = useState(true)
  const [editingId, setEditingId] = useState<PromotionAppId | null>(null)
  const [savingId, setSavingId] = useState<PromotionAppId | null>(null)
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null)

  useEffect(() => {
    fetchApps()
  }, [])

  const fetchApps = async () => {
    try {
      setLoading(true)
      const token = await onGetAuthToken()
      const response = await fetch("/api/admin/promotion-apps", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error("Failed to fetch promotion apps")
      }

      const data: ApiResponse = await response.json()

      const nextApps: Record<PromotionAppId, PromotionApp> = {
        app1: { id: "app1", enabled: true, ...(data.app1 || {}) },
        app2: { id: "app2", enabled: true, ...(data.app2 || {}) },
        app3: { id: "app3", enabled: true, ...(data.app3 || {}) },
        app4: { id: "app4", enabled: true, ...(data.app4 || {}) },
      }

      setApps(nextApps)

      setTasksText({
        app1: (nextApps.app1.tasks || []).join(", "),
        app2: (nextApps.app2.tasks || []).join(", "),
        app3: (nextApps.app3.tasks || []).join(", "),
        app4: (nextApps.app4.tasks || []).join(", "),
      })
    } catch (error) {
      console.error("Error fetching promotion apps:", error)
      setMessage({ type: "error", text: "Failed to load promotion apps" })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setLoading(false)
    }
  }

  const handleChange = (id: PromotionAppId, field: keyof PromotionApp, value: string | number | boolean) => {
    setApps((prev) => ({
      ...prev,
      [id]: {
        ...prev[id],
        [field]: value,
      },
    }))
  }

  const handleTasksChange = (id: PromotionAppId, value: string) => {
    setTasksText((prev) => ({ ...prev, [id]: value }))
  }

  const handleStartEdit = (id: PromotionAppId) => {
    setEditingId(id)
  }

  const handleCancelEdit = async () => {
    // Reload from server to discard local unsaved changes
    await fetchApps()
    setEditingId(null)
  }

  const handleSave = async (id: PromotionAppId) => {
    const app = apps[id]
    if (!app?.title || !app.playStoreUrl) {
      setMessage({
        type: "error",
        text: "Title and Play Store URL are required",
      })
      setTimeout(() => setMessage(null), 3000)
      return
    }

    const parsedTasks = tasksText[id]
      .split(",")
      .map((t) => t.trim())
      .filter((t) => t.length > 0)

    try {
      setSavingId(id)
      const token = await onGetAuthToken()
      const { id: _ignoredId, ...appWithoutId } = app
      const response = await fetch("/api/admin/promotion-apps", {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id,
          ...appWithoutId,
          tasks: parsedTasks,
          enabled: app.enabled ?? true,
        }),
      })

      if (!response.ok) {
        throw new Error("Failed to save promotion app")
      }

      setMessage({
        type: "success",
        text: id === "app1" ? "App 1 saved successfully" : "App 2 saved successfully",
      })
      setTimeout(() => setMessage(null), 3000)
      setEditingId(null)
    } catch (error) {
      console.error("Error saving promotion app:", error)
      setMessage({ type: "error", text: "Failed to save promotion app" })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setSavingId(null)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {(["app1", "app2", "app3", "app4"] as PromotionAppId[]).map((id) => {
          const app = apps[id]
          const label = id === "app1" ? "Promotion App 1" : id === "app2" ? "Promotion App 2" : id === "app3" ? "Promotion App 3" : "Promotion App 4"
          const isEditing = editingId === id
          return (
            <Card key={id}>
              <CardHeader>
                <div className="flex items-start justify-between gap-3">
                  <div className="space-y-1">
                    <CardTitle className="text-base">{label}</CardTitle>
                    <CardDescription>
                      {isEditing
                        ? "Edit the content and tasks for this promotion app"
                        : "Preview of the current promotion app configuration"}
                    </CardDescription>
                  </div>
                  <Badge variant={(app.enabled ?? true) ? "default" : "secondary"}>
                    {(app.enabled ?? true) ? "Enabled" : "Disabled"}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                {isEditing ? (
                  <>
                    <div className="flex items-center justify-between space-x-2">
                      <div className="space-y-0.5">
                        <Label htmlFor={`${id}-enabled`} className="text-base">Enable App</Label>
                        <p className="text-xs text-muted-foreground">Show this app in the Flutter app</p>
                      </div>
                      <Switch
                        id={`${id}-enabled`}
                        checked={app.enabled ?? true}
                        onCheckedChange={(checked) => handleChange(id, "enabled", checked)}
                      />
                    </div>
                    <Separator />
                    <div className="space-y-2">
                      <Label htmlFor={`${id}-title`}>Title</Label>
                      <Input
                        id={`${id}-title`}
                        value={app.title || ""}
                        onChange={(e) => handleChange(id, "title", e.target.value)}
                        placeholder="Awesome Game"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor={`${id}-description`}>Description</Label>
                      <Textarea
                        id={`${id}-description`}
                        value={app.description || ""}
                        onChange={(e) => handleChange(id, "description", e.target.value)}
                        placeholder="Short description shown in the app"
                        rows={3}
                      />
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor={`${id}-badgeText`}>Badge Text</Label>
                        <Input
                          id={`${id}-badgeText`}
                          value={app.badgeText || ""}
                          onChange={(e) => handleChange(id, "badgeText", e.target.value)}
                          placeholder="POPULAR"
                        />
                        <p className="text-xs text-muted-foreground">
                          Optional. If empty, badge may still show if variant is set (uses variant label).
                        </p>
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor={`${id}-badgeVariant`}>Badge Variant</Label>
                        <Select
                          value={(app.badgeVariant || "none") as string}
                          onValueChange={(value) => handleChange(id, "badgeVariant", value)}
                        >
                          <SelectTrigger id={`${id}-badgeVariant`}>
                            <SelectValue placeholder="Select badge variant" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="none">None</SelectItem>
                            <SelectItem value="default">Default</SelectItem>
                            <SelectItem value="popular">Popular</SelectItem>
                            <SelectItem value="new">New</SelectItem>
                            <SelectItem value="hot">Hot</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor={`${id}-stars`}>Stars (0–5)</Label>
                        <Input
                          id={`${id}-stars`}
                          type="number"
                          min={0}
                          max={5}
                          step={0.1}
                          value={app.stars ?? ""}
                          onChange={(e) =>
                            handleChange(id, "stars", e.target.value ? Number(e.target.value) : 0)
                          }
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor={`${id}-coins`}>Coins</Label>
                        <Input
                          id={`${id}-coins`}
                          type="number"
                          min={0}
                          value={app.coins ?? ""}
                          onChange={(e) =>
                            handleChange(id, "coins", e.target.value ? Number(e.target.value) : 0)
                          }
                        />
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor={`${id}-buttonText`}>Button Text</Label>
                      <Input
                        id={`${id}-buttonText`}
                        value={app.buttonText || ""}
                        onChange={(e) => handleChange(id, "buttonText", e.target.value)}
                        placeholder="Install Now"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor={`${id}-playStoreUrl`}>Play Store URL</Label>
                      <Input
                        id={`${id}-playStoreUrl`}
                        type="url"
                        value={app.playStoreUrl || ""}
                        onChange={(e) => handleChange(id, "playStoreUrl", e.target.value)}
                        placeholder="https://play.google.com/store/apps/details?id=..."
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor={`${id}-photo`}>Photo URL</Label>
                      <Input
                        id={`${id}-photo`}
                        type="url"
                        value={app.photo || ""}
                        onChange={(e) => handleChange(id, "photo", e.target.value)}
                        placeholder="https://play-lh.googleusercontent.com/..."
                      />
                      {app.photo && (
                        <div className="mt-2 h-32 w-full overflow-hidden rounded-lg bg-muted">
                          <img
                            src={app.photo}
                            alt={app.title || "Promotion app"}
                            className="h-full w-full object-cover"
                            onError={(e) => {
                              (e.target as HTMLImageElement).style.display = "none"
                            }}
                          />
                        </div>
                      )}
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor={`${id}-tasks`}>Tasks (comma-separated)</Label>
                      <Textarea
                        id={`${id}-tasks`}
                        value={tasksText[id]}
                        onChange={(e) => handleTasksChange(id, e.target.value)}
                        placeholder="Install the app, Open and play for 5 minutes, Complete tutorial..."
                        rows={3}
                      />
                      <p className="text-xs text-muted-foreground">
                        These will be stored as a list of strings in Firestore.
                      </p>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor={`${id}-minimumBackgroundTime`}>Minimum Background Time (seconds)</Label>
                      <Input
                        id={`${id}-minimumBackgroundTime`}
                        type="number"
                        min={0}
                        value={app.minimumBackgroundTime ?? ""}
                        onChange={(e) =>
                          handleChange(id, "minimumBackgroundTime", e.target.value ? Number(e.target.value) : 0)
                        }
                        placeholder="60"
                      />
                      <p className="text-xs text-muted-foreground">
                        Minimum time user must keep the app in background (in seconds) to earn coins. Set to 0 to disable.
                      </p>
                    </div>

                    <Separator />

                    <div className="flex justify-end gap-2">
                      <Button
                        variant="outline"
                        onClick={handleCancelEdit}
                        disabled={savingId === id}
                      >
                        Cancel
                      </Button>
                      <Button onClick={() => handleSave(id)} disabled={savingId === id}>
                        {savingId === id ? (
                          <>
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            Saving...
                          </>
                        ) : (
                          <>
                            <Save className="mr-2 h-4 w-4" />
                            Save {label}
                          </>
                        )}
                      </Button>
                    </div>
                  </>
                ) : (
                  <>
                    <div className="flex items-center justify-between space-x-2">
                      <div className="space-y-0.5">
                        <Label htmlFor={`${id}-enabled-preview`} className="text-base">Enable App</Label>
                        <p className="text-xs text-muted-foreground">Show this app in the Flutter app</p>
                      </div>
                      <Switch
                        id={`${id}-enabled-preview`}
                        checked={app.enabled ?? true}
                        onCheckedChange={(checked) => {
                          handleChange(id, "enabled", checked)
                          handleSave(id)
                        }}
                      />
                    </div>
                    <Separator />
                    <div className="flex gap-3">
                      {app.photo && (
                        <div className="h-20 w-20 overflow-hidden rounded-lg bg-muted shrink-0">
                          <img
                            src={app.photo}
                            alt={app.title || "Promotion app"}
                            className="h-full w-full object-cover"
                            onError={(e) => {
                              (e.target as HTMLImageElement).style.display = "none"
                            }}
                          />
                        </div>
                      )}
                      <div className="space-y-1">
                        <p className="text-sm font-semibold">{app.title || "Not configured"}</p>
                        {app.description && (
                          <p className="text-xs text-muted-foreground line-clamp-3">
                            {app.description}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div className="space-y-1">
                        <p className="text-muted-foreground text-xs">Stars</p>
                        <p>{app.stars ?? "-"}</p>
                      </div>
                      <div className="space-y-1">
                        <p className="text-muted-foreground text-xs">Coins</p>
                        <p>{app.coins ?? "-"}</p>
                      </div>
                      <div className="space-y-1">
                        <p className="text-muted-foreground text-xs">Min Background Time</p>
                        <p>{app.minimumBackgroundTime ? `${app.minimumBackgroundTime}s` : "-"}</p>
                      </div>
                      <div className="space-y-1 col-span-2">
                        <p className="text-muted-foreground text-xs">Play Store URL</p>
                        {app.playStoreUrl ? (
                          <a
                            href={app.playStoreUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs text-blue-500 hover:underline break-all"
                          >
                            {app.playStoreUrl}
                          </a>
                        ) : (
                          <p className="text-xs text-muted-foreground">Not set</p>
                        )}
                      </div>
                    </div>

                    <div className="space-y-1 text-sm">
                      <p className="text-muted-foreground text-xs">Tasks</p>
                      {tasksText[id] ? (
                        <ul className="list-disc pl-5 space-y-0.5 text-xs">
                          {tasksText[id].split(",").map((t) => t.trim()).filter(Boolean).map((t) => (
                            <li key={t}>{t}</li>
                          ))}
                        </ul>
                      ) : (
                        <p className="text-xs text-muted-foreground">No tasks configured</p>
                      )}
                    </div>

                    <Separator />

                    <div className="flex justify-end">
                      <Button variant="outline" size="sm" onClick={() => handleStartEdit(id)}>
                        Edit {label}
                      </Button>
                    </div>
                  </>
                )}
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}


