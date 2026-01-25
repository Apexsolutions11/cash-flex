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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

interface FollowTask {
  id?: string
  tag: string
  type: string
  link: string
  name: string
  active: boolean
  coins: number
  minBackgroundTime: number
  country?: string | null // Optional: restrict to specific country
  state?: string | null // Optional: restrict to specific state/region
}

interface FollowTasksFormProps {
  onGetAuthToken: () => Promise<string>
}

// List of common countries
const COUNTRIES = [
  "India",
  "United States",
  "United Kingdom",
  "Canada",
  "Australia",
  "Germany",
  "France",
  "Spain",
  "Italy",
  "Brazil",
  "Mexico",
  "Japan",
  "South Korea",
  "China",
  "Singapore",
  "Malaysia",
  "Indonesia",
  "Thailand",
  "Philippines",
  "Bangladesh",
  "Pakistan",
  "Sri Lanka",
  "Nepal",
  "Other",
]

// List of Indian states and union territories
const INDIAN_STATES = [
  "Andhra Pradesh",
  "Arunachal Pradesh",
  "Assam",
  "Bihar",
  "Chhattisgarh",
  "Goa",
  "Gujarat",
  "Haryana",
  "Himachal Pradesh",
  "Jharkhand",
  "Karnataka",
  "Kerala",
  "Madhya Pradesh",
  "Maharashtra",
  "Manipur",
  "Meghalaya",
  "Mizoram",
  "Nagaland",
  "Odisha",
  "Punjab",
  "Rajasthan",
  "Sikkim",
  "Tamil Nadu",
  "Telangana",
  "Tripura",
  "Uttar Pradesh",
  "Uttarakhand",
  "West Bengal",
  "Andaman and Nicobar Islands",
  "Chandigarh",
  "Dadra and Nagar Haveli and Daman and Diu",
  "Delhi",
  "Jammu and Kashmir",
  "Ladakh",
  "Lakshadweep",
  "Puducherry",
]

export function FollowTasksForm({ onGetAuthToken }: FollowTasksFormProps) {
  const [tasks, setTasks] = useState<FollowTask[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<FollowTask | null>(null)
  const [formData, setFormData] = useState<FollowTask>({
    tag: "",
    type: "",
    link: "",
    name: "",
    active: true,
    coins: 10,
    minBackgroundTime: 30,
    country: "",
    state: "",
  })
  const [showOtherCountryInput, setShowOtherCountryInput] = useState(false)
  const [otherCountryValue, setOtherCountryValue] = useState("")
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null)

  useEffect(() => {
    fetchTasks()
  }, [])

  const fetchTasks = async () => {
    try {
      setLoading(true)
      const token = await onGetAuthToken()
      const response = await fetch("/api/admin/follow-tasks", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        const data = await response.json()
        setTasks(data || [])
      } else {
        setMessage({ type: "error", text: "Failed to fetch follow tasks" })
      }
    } catch (error) {
      console.error("Error fetching follow tasks:", error)
      setMessage({ type: "error", text: "Error loading follow tasks" })
    } finally {
      setLoading(false)
    }
  }

  const handleOpenDialog = (task?: FollowTask) => {
    if (task) {
      setEditingTask(task)
      setFormData(task)
      // Check if country is a custom value (not in COUNTRIES list)
      if (task.country && !COUNTRIES.includes(task.country)) {
        setShowOtherCountryInput(true)
        setOtherCountryValue(task.country)
      } else {
        setShowOtherCountryInput(false)
        setOtherCountryValue("")
      }
    } else {
      setEditingTask(null)
      setFormData({
        tag: "",
        type: "",
        link: "",
        name: "",
        active: true,
        coins: 10,
        minBackgroundTime: 30,
        country: "",
        state: "",
      })
      setShowOtherCountryInput(false)
      setOtherCountryValue("")
    }
    setIsDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setIsDialogOpen(false)
    setEditingTask(null)
    setFormData({
      tag: "",
      type: "",
      link: "",
      name: "",
      active: true,
      coins: 10,
      minBackgroundTime: 30,
      country: "",
      state: "",
    })
    setShowOtherCountryInput(false)
    setOtherCountryValue("")
  }

  const handleChange = (field: keyof FollowTask, value: string | number | boolean | null) => {
    const newFormData = { ...formData, [field]: value } as FollowTask
    
    // If country changes, clear state if switching from/to India
    if (field === "country") {
      const newCountry = value as string | null
      const oldCountry = formData.country
      
      // If switching from India to another country or vice versa, clear state
      if (
        (oldCountry === "India" && newCountry !== "India") ||
        (oldCountry !== "India" && newCountry === "India")
      ) {
        newFormData.state = ""
      }
      
      // If switching to/from "Other", update the other country input visibility
      if (newCountry && !COUNTRIES.includes(newCountry)) {
        setShowOtherCountryInput(true)
        setOtherCountryValue(newCountry)
      } else if (newCountry !== "Other") {
        setShowOtherCountryInput(false)
        setOtherCountryValue("")
      }
    }
    
    setFormData(newFormData)
  }

  const handleSave = async () => {
    if (!formData.tag || !formData.type || !formData.link || !formData.name) {
      setMessage({ type: "error", text: "All fields are required" })
      setTimeout(() => setMessage(null), 3000)
      return
    }

    try {
      setSaving(true)
      const token = await onGetAuthToken()

      if (editingTask?.id) {
        const response = await fetch("/api/admin/follow-tasks", {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            id: editingTask.id,
            ...formData,
          }),
        })

        if (!response.ok) {
          throw new Error("Failed to update follow task")
        }

        setMessage({ type: "success", text: "Follow task updated successfully!" })
        await fetchTasks()
      } else {
        const response = await fetch("/api/admin/follow-tasks", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(formData),
        })

        if (!response.ok) {
          throw new Error("Failed to create follow task")
        }

        setMessage({ type: "success", text: "Follow task created successfully!" })
        await fetchTasks()
      }

      handleCloseDialog()
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      console.error("Error saving follow task:", error)
      setMessage({ type: "error", text: "Failed to save follow task" })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this follow task?")) {
      return
    }

    try {
      const token = await onGetAuthToken()
      const response = await fetch(`/api/admin/follow-tasks?id=${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error("Failed to delete follow task")
      }

      setMessage({ type: "success", text: "Follow task deleted successfully!" })
      await fetchTasks()
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      console.error("Error deleting follow task:", error)
      setMessage({ type: "error", text: "Failed to delete follow task" })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  const toggleActive = async (task: FollowTask) => {
    try {
      const token = await onGetAuthToken()
      const response = await fetch("/api/admin/follow-tasks", {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id: task.id,
          active: !task.active,
        }),
      })

      if (!response.ok) {
        throw new Error("Failed to update task status")
      }

      await fetchTasks()
    } catch (error) {
      console.error("Error toggling task status:", error)
      setMessage({ type: "error", text: "Failed to update task status" })
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

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <div className="flex items-center justify-between gap-3">
        <p className="text-sm text-muted-foreground">
          {tasks.length} task{tasks.length === 1 ? "" : "s"}
        </p>
        <Button onClick={() => handleOpenDialog()} size="lg" className="shrink-0">
          <Plus className="mr-2 h-4 w-4" />
          Add Follow Task
        </Button>
      </div>

      <Separator />

      {tasks.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12">
            <p className="text-muted-foreground mb-4">No follow tasks found</p>
            <Button onClick={() => handleOpenDialog()} variant="outline">
              <Plus className="mr-2 h-4 w-4" />
              Create First Follow Task
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tasks.map((task) => (
            <Card key={task.id} className={`${!task.active ? "opacity-60" : ""}`}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="text-base line-clamp-2">{task.name}</CardTitle>
                    <CardDescription className="mt-1">
                      <span className="uppercase text-xs tracking-wide text-muted-foreground">
                        {task.type}
                      </span>
                      <span className="ml-2 align-middle">
                        <Badge variant={task.active ? "default" : "secondary"}>
                          {task.active ? "Active" : "Paused"}
                        </Badge>
                      </span>
                    </CardDescription>
                  </div>
                  <div className="flex items-center gap-2">
                    <Switch checked={task.active} onCheckedChange={() => toggleActive(task)} />
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3 text-sm">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Tag:</span>
                    <span className="font-mono text-xs bg-muted px-2 py-0.5 rounded">
                      {task.tag}
                    </span>
                  </div>
                  <div className="truncate">
                    <span className="text-muted-foreground">Link: </span>
                    <a
                      href={task.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:underline truncate block"
                    >
                      {task.link}
                    </a>
                  </div>
                  
                  {(task.country || task.state) && (
                    <div className="text-sm">
                      <span className="text-muted-foreground">Location: </span>
                      <span className="font-medium">
                        {task.country || "Global"}
                        {task.state ? `, ${task.state}` : ""}
                      </span>
                    </div>
                  )}

                  <Separator />

                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      onClick={() => handleOpenDialog(task)}
                    >
                      <Edit2 className="mr-2 h-3 w-3" />
                      Edit
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      className="flex-1"
                      onClick={() => task.id && handleDelete(task.id)}
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
            <DialogTitle>{editingTask ? "Edit Follow Task" : "Create New Follow Task"}</DialogTitle>
            <DialogDescription>
              {editingTask
                ? "Update the follow task details below"
                : "Fill in the details to create a new follow task"}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="name">Display Name</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => handleChange("name", e.target.value)}
                  placeholder="Instagram, Telegram Channel, etc."
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="type">Platform Type</Label>
                <Input
                  id="type"
                  value={formData.type}
                  onChange={(e) => handleChange("type", e.target.value)}
                  placeholder="instagram, telegram, youtube..."
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="coins">Reward Coins</Label>
                <Input
                  id="coins"
                  type="number"
                  min={0}
                  value={formData.coins}
                  onChange={(e) => handleChange("coins", Number(e.target.value))}
                  placeholder="10"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="minBackgroundTime">Min Background Time (seconds)</Label>
                <Input
                  id="minBackgroundTime"
                  type="number"
                  min={0}
                  value={formData.minBackgroundTime}
                  onChange={(e) => handleChange("minBackgroundTime", Number(e.target.value))}
                  placeholder="30"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="tag">Tag (unique id)</Label>
              <Input
                id="tag"
                value={formData.tag}
                onChange={(e) => handleChange("tag", e.target.value)}
                placeholder="INSTAGRAM_MAIN"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="link">Link (URL)</Label>
              <Input
                id="link"
                type="url"
                value={formData.link}
                onChange={(e) => handleChange("link", e.target.value)}
                placeholder="https://instagram.com/..."
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="country">Country (Optional)</Label>
                <Select
                  value={
                    showOtherCountryInput
                      ? "Other"
                      : formData.country && COUNTRIES.includes(formData.country)
                      ? formData.country
                      : formData.country === null || formData.country === ""
                      ? "__global__"
                      : "Other"
                  }
                  onValueChange={(value) => {
                    if (value === "__global__") {
                      handleChange("country", null)
                      setShowOtherCountryInput(false)
                      setOtherCountryValue("")
                    } else if (value === "Other") {
                      setShowOtherCountryInput(true)
                      if (otherCountryValue) {
                        handleChange("country", otherCountryValue)
                      }
                    } else {
                      handleChange("country", value)
                      setShowOtherCountryInput(false)
                      setOtherCountryValue("")
                    }
                  }}
                >
                  <SelectTrigger id="country">
                    <SelectValue placeholder="Select country (leave empty for global)" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="__global__">Global (All Countries)</SelectItem>
                    {COUNTRIES.map((country) => (
                      <SelectItem key={country} value={country}>
                        {country}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {showOtherCountryInput && (
                  <Input
                    id="country-other"
                    value={otherCountryValue}
                    onChange={(e) => {
                      const value = e.target.value
                      setOtherCountryValue(value)
                      handleChange("country", value || null)
                    }}
                    placeholder="Enter country name"
                    className="mt-2"
                  />
                )}
                <p className="text-xs text-muted-foreground">
                  {showOtherCountryInput
                    ? "Enter the country name"
                    : "Restrict this task to a specific country"}
                </p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="state">State/Region (Optional)</Label>
                {formData.country === "India" ? (
                  <>
                    <Select
                      value={formData.state || "__all_states__"}
                      onValueChange={(value) =>
                        handleChange("state", value === "__all_states__" ? null : value)
                      }
                    >
                      <SelectTrigger id="state">
                        <SelectValue placeholder="Select state (leave empty for all states)" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="__all_states__">All States</SelectItem>
                        {INDIAN_STATES.map((state) => (
                          <SelectItem key={state} value={state}>
                            {state}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <p className="text-xs text-muted-foreground">
                      Select a specific Indian state/union territory
                    </p>
                  </>
                ) : (
                  <>
                    <Input
                      id="state"
                      value={formData.state || ""}
                      onChange={(e) => handleChange("state", e.target.value || null)}
                      placeholder="Enter state/region name"
                    />
                    <p className="text-xs text-muted-foreground">
                      Enter state/region name for {formData.country || "selected country"}
                    </p>
                  </>
                )}
              </div>
            </div>

            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="space-y-0.5">
                <Label htmlFor="active">Active</Label>
                <p className="text-sm text-muted-foreground">
                  Whether this follow task is visible to users
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
                  {editingTask ? "Update" : "Create"}
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}


