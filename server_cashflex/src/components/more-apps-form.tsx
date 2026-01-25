"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { Loader2, Plus, Trash2, Edit2, X, Save } from "lucide-react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Switch } from "@/components/ui/switch"
import { StatusMessage } from "@/components/status-message"
import { Badge } from "@/components/ui/badge"

interface MoreApp {
  id?: string
  coins: number
  minBackgroundTime: number
  appName: string
  clickUrl: string
  imageUrl: string
  active: boolean
  bundleId: string
  rank: number
}

interface MoreAppsFormProps {
  onGetAuthToken: () => Promise<string>
}

export function MoreAppsForm({ onGetAuthToken }: MoreAppsFormProps) {
  const [apps, setApps] = useState<MoreApp[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingApp, setEditingApp] = useState<MoreApp | null>(null)
  const [formData, setFormData] = useState<MoreApp>({
    coins: 0,
    minBackgroundTime: 120,
    appName: "",
    clickUrl: "",
    imageUrl: "",
    active: true,
    bundleId: "",
    rank: 1,
  })
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null)

  useEffect(() => {
    fetchApps()
  }, [])

  const fetchApps = async () => {
    try {
      setLoading(true)
      const token = await onGetAuthToken()
      const response = await fetch("/api/admin/more-apps", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        const data = await response.json()
        setApps(data || [])
      } else {
        setMessage({ type: "error", text: "Failed to fetch apps" })
      }
    } catch (error) {
      console.error("Error fetching apps:", error)
      setMessage({ type: "error", text: "Error loading apps" })
    } finally {
      setLoading(false)
    }
  }

  const handleOpenDialog = (app?: MoreApp) => {
    if (app) {
      setEditingApp(app)
      setFormData(app)
    } else {
      setEditingApp(null)
      setFormData({
        coins: 0,
        minBackgroundTime: 120,
        appName: "",
        clickUrl: "",
        imageUrl: "",
        active: true,
        bundleId: "",
        rank: apps.length + 1,
      })
    }
    setIsDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setIsDialogOpen(false)
    setEditingApp(null)
    setFormData({
      coins: 0,
      minBackgroundTime: 120,
      appName: "",
      clickUrl: "",
      imageUrl: "",
      active: true,
      bundleId: "",
      rank: 1,
    })
  }

  const handleChange = (field: keyof MoreApp, value: string | number | boolean) => {
    setFormData({ ...formData, [field]: value } as MoreApp)
  }

  const handleSave = async () => {
    if (!formData.appName || !formData.clickUrl || !formData.imageUrl || !formData.bundleId) {
      setMessage({ type: "error", text: "All fields are required" })
      setTimeout(() => setMessage(null), 3000)
      return
    }

    if (formData.coins <= 0) {
      setMessage({ type: "error", text: "Coins must be greater than 0" })
      setTimeout(() => setMessage(null), 3000)
      return
    }

    try {
      setSaving(true)
      const token = await onGetAuthToken()

      if (editingApp?.id) {
        const response = await fetch("/api/admin/more-apps", {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            id: editingApp.id,
            ...formData,
          }),
        })

        if (!response.ok) {
          throw new Error("Failed to update app")
        }

        setMessage({ type: "success", text: "App updated successfully!" })
        await fetchApps()
      } else {
        const response = await fetch("/api/admin/more-apps", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(formData),
        })

        if (!response.ok) {
          throw new Error("Failed to create app")
        }

        setMessage({ type: "success", text: "App created successfully!" })
        await fetchApps()
      }

      handleCloseDialog()
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      console.error("Error saving app:", error)
      setMessage({ type: "error", text: "Failed to save app" })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this app?")) {
      return
    }

    try {
      const token = await onGetAuthToken()
      const response = await fetch(`/api/admin/more-apps?id=${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error("Failed to delete app")
      }

      setMessage({ type: "success", text: "App deleted successfully!" })
      await fetchApps()
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      console.error("Error deleting app:", error)
      setMessage({ type: "error", text: "Failed to delete app" })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  const toggleActive = async (app: MoreApp) => {
    try {
      const token = await onGetAuthToken()
      const response = await fetch("/api/admin/more-apps", {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id: app.id,
          active: !app.active,
        }),
      })

      if (!response.ok) {
        throw new Error("Failed to update app status")
      }

      await fetchApps()
    } catch (error) {
      console.error("Error toggling app status:", error)
      setMessage({ type: "error", text: "Failed to update app status" })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    )
  }

  const sortedApps = [...apps].sort((a, b) => a.rank - b.rank)

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <div className="flex items-center justify-between gap-3">
        <p className="text-sm text-muted-foreground">
          {sortedApps.length} app{sortedApps.length === 1 ? "" : "s"} •{" "}
          {sortedApps.filter((a) => a.active).length} active
        </p>
        <Button onClick={() => handleOpenDialog()} size="lg" className="shrink-0">
          <Plus className="mr-2 h-4 w-4" />
          Add App
        </Button>
      </div>

      <Separator />

      {sortedApps.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12">
            <p className="text-muted-foreground mb-4">No apps found</p>
            <Button onClick={() => handleOpenDialog()} variant="outline">
              <Plus className="mr-2 h-4 w-4" />
              Create First App
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {sortedApps.map((app) => (
            <Card key={app.id} className={`${!app.active ? "opacity-60" : ""}`}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1 space-y-1">
                    <CardTitle className="text-base line-clamp-2">{app.appName}</CardTitle>
                    <CardDescription className="flex items-center justify-between text-xs">
                      <span className="inline-flex items-center gap-2">
                        <span className="font-mono">#{app.rank}</span>
                        <Badge variant={app.active ? "default" : "secondary"}>
                          {app.active ? "Active" : "Paused"}
                        </Badge>
                      </span>
                      <span className="truncate">{app.bundleId}</span>
                    </CardDescription>
                  </div>
                  <div className="flex items-center gap-2">
                    <Switch checked={app.active} onCheckedChange={() => toggleActive(app)} />
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3 text-sm">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Coins Reward</span>
                    <span className="font-semibold">{app.coins}</span>
                  </div>

                  <div className="truncate">
                    <span className="text-muted-foreground">Click URL: </span>
                    <a
                      href={app.clickUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:underline truncate block"
                    >
                      {app.clickUrl}
                    </a>
                  </div>

                  <div className="space-y-1">
                    <span className="text-muted-foreground text-xs">Image Preview</span>
                    {app.imageUrl && (
                      <div className="relative w-full h-32 bg-muted rounded-lg overflow-hidden">
                        <img
                          src={app.imageUrl}
                          alt={app.appName}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = "none"
                          }}
                        />
                      </div>
                    )}
                  </div>

                  <Separator />

                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      onClick={() => handleOpenDialog(app)}
                    >
                      <Edit2 className="mr-2 h-3 w-3" />
                      Edit
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      className="flex-1"
                      onClick={() => app.id && handleDelete(app.id)}
                    >
                      <Trash2 className="mr-2 h-3 w-3" />
                      Delete
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingApp ? "Edit App" : "Create New App"}</DialogTitle>
            <DialogDescription>
              {editingApp
                ? "Update the app details below"
                : "Fill in the details to create a new app promotion"}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="appName">App Name</Label>
              <Input
                id="appName"
                value={formData.appName}
                onChange={(e) => handleChange("appName", e.target.value)}
                placeholder="Enter app name"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="bundleId">Bundle ID</Label>
                <Input
                  id="bundleId"
                  value={formData.bundleId}
                  onChange={(e) => handleChange("bundleId", e.target.value)}
                  placeholder="com.example.app"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="rank">Rank</Label>
                <Input
                  id="rank"
                  type="number"
                  value={formData.rank}
                  onChange={(e) => handleChange("rank", Number(e.target.value))}
                  min={1}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="coins">Coins Reward</Label>
                <Input
                  id="coins"
                  type="number"
                  value={formData.coins}
                  onChange={(e) => handleChange("coins", Number(e.target.value))}
                  min={1}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="minBackgroundTime">Min Background Time (seconds)</Label>
                <Input
                  id="minBackgroundTime"
                  type="number"
                  value={formData.minBackgroundTime}
                  onChange={(e) => handleChange("minBackgroundTime", Number(e.target.value))}
                  min={0}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="clickUrl">Click URL</Label>
                <Input
                  id="clickUrl"
                  type="url"
                  value={formData.clickUrl}
                  onChange={(e) => handleChange("clickUrl", e.target.value)}
                  placeholder="https://play.google.com/store/apps/details?id=..."
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="imageUrl">Image URL</Label>
              <Input
                id="imageUrl"
                type="url"
                value={formData.imageUrl}
                onChange={(e) => handleChange("imageUrl", e.target.value)}
                placeholder="https://play-lh.googleusercontent.com/..."
              />
              {formData.imageUrl && (
                <div className="relative w-full h-32 bg-muted rounded-lg overflow-hidden mt-2">
                  <img
                    src={formData.imageUrl}
                    alt="Preview"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = "none"
                    }}
                  />
                </div>
              )}
            </div>

            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="space-y-0.5">
                <Label htmlFor="active">Active</Label>
                <p className="text-sm text-muted-foreground">
                  Whether this app is visible to users in the mobile app
                </p>
              </div>
              <Switch
                id="active"
                checked={formData.active}
                onCheckedChange={(checked) => handleChange("active", checked)}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={handleCloseDialog} disabled={saving}>
              <X className="mr-2 h-4 w-4" />
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Saving...
                </>
              ) : (
                <>
                  <Save className="mr-2 h-4 w-4" />
                  {editingApp ? "Update" : "Create"}
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}


