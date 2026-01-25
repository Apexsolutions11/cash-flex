"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { Save, Loader2, Plus, Trash2, Edit2, X } from "lucide-react"
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

interface ReviewTask {
  id?: string
  clipboardEnabled: boolean
  coins: number
  minBackgroundTime: number
  description: string
  enabled: boolean
  img: string
  link: string
}

interface ReviewTasksFormProps {
  onGetAuthToken: () => Promise<string>
}

export function ReviewTasksForm({ onGetAuthToken }: ReviewTasksFormProps) {
  const [tasks, setTasks] = useState<ReviewTask[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<ReviewTask | null>(null)
  const [formData, setFormData] = useState<ReviewTask>({
    clipboardEnabled: false,
    coins: 150,
    minBackgroundTime: 60,
    description: "",
    enabled: false,
    img: "",
    link: "",
  })
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  useEffect(() => {
    fetchTasks()
  }, [])

  const fetchTasks = async () => {
    try {
      setLoading(true)
      const token = await onGetAuthToken()
      const response = await fetch('/api/admin/review-tasks', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        const data = await response.json()
        setTasks(data || [])
      } else {
        setMessage({ type: 'error', text: 'Failed to fetch review tasks' })
      }
    } catch (error) {
      console.error('Error fetching review tasks:', error)
      setMessage({ type: 'error', text: 'Error loading review tasks' })
    } finally {
      setLoading(false)
    }
  }

  const handleOpenDialog = (task?: ReviewTask) => {
    if (task) {
      setEditingTask(task)
      setFormData(task)
    } else {
      setEditingTask(null)
      setFormData({
        clipboardEnabled: false,
        coins: 150,
        minBackgroundTime: 60,
        description: "",
        enabled: false,
        img: "",
        link: "",
      })
    }
    setIsDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setIsDialogOpen(false)
    setEditingTask(null)
    setFormData({
      clipboardEnabled: false,
      coins: 150,
      minBackgroundTime: 60,
      description: "",
      enabled: false,
      img: "",
      link: "",
    })
  }

  const handleChange = (field: keyof ReviewTask, value: string | number | boolean) => {
    setFormData({ ...formData, [field]: value })
  }

  const handleSave = async () => {
    if (!formData.link || !formData.img) {
      setMessage({ type: 'error', text: 'Link and image URL are required' })
      setTimeout(() => setMessage(null), 3000)
      return
    }

    try {
      setSaving(true)
      const token = await onGetAuthToken()
      
      if (editingTask?.id) {
        // Update existing task
        const response = await fetch('/api/admin/review-tasks', {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            id: editingTask.id,
            ...formData,
          }),
        })

        if (!response.ok) {
          throw new Error('Failed to update review task')
        }

        setMessage({ type: 'success', text: 'Review task updated successfully!' })
        await fetchTasks()
      } else {
        // Create new task
        const response = await fetch('/api/admin/review-tasks', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(formData),
        })

        if (!response.ok) {
          throw new Error('Failed to create review task')
        }

        setMessage({ type: 'success', text: 'Review task created successfully!' })
        await fetchTasks()
      }

      handleCloseDialog()
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      console.error('Error saving review task:', error)
      setMessage({ type: 'error', text: 'Failed to save review task' })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this review task?')) {
      return
    }

    try {
      const token = await onGetAuthToken()
      const response = await fetch(`/api/admin/review-tasks?id=${id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error('Failed to delete review task')
      }

      setMessage({ type: 'success', text: 'Review task deleted successfully!' })
      await fetchTasks()
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      console.error('Error deleting review task:', error)
      setMessage({ type: 'error', text: 'Failed to delete review task' })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  const toggleEnabled = async (task: ReviewTask) => {
    try {
      const token = await onGetAuthToken()
      const response = await fetch('/api/admin/review-tasks', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id: task.id,
          enabled: !task.enabled,
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to update task status')
      }

      await fetchTasks()
    } catch (error) {
      console.error('Error toggling task status:', error)
      setMessage({ type: 'error', text: 'Failed to update task status' })
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
          Add Review Task
        </Button>
      </div>

      <Separator />

      {tasks.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12">
            <p className="text-muted-foreground mb-4">No review tasks found</p>
            <Button onClick={() => handleOpenDialog()} variant="outline">
              <Plus className="mr-2 h-4 w-4" />
              Create First Review Task
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tasks.map((task) => (
            <Card key={task.id} className={`${!task.enabled ? 'opacity-60' : ''}`}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="text-base line-clamp-2">
                      {task.description || 'No description'}
                    </CardTitle>
                    <CardDescription className="mt-1">
                      <Badge variant={task.enabled ? "default" : "secondary"}>
                        {task.enabled ? "Enabled" : "Disabled"}
                      </Badge>
                    </CardDescription>
                  </div>
                  <div className="flex items-center gap-2">
                    <Switch
                      checked={task.enabled}
                      onCheckedChange={() => toggleEnabled(task)}
                    />
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {task.img && (
                    <div className="relative w-full h-32 bg-muted rounded-lg overflow-hidden">
                      <img
                        src={task.img}
                        alt={task.description || 'Review task'}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = 'none'
                        }}
                      />
                    </div>
                  )}
                  
                  <div className="space-y-2 text-sm">
                    <div className="flex items-center justify-between">
                      <span className="text-muted-foreground">Clipboard:</span>
                      <span className={task.clipboardEnabled ? 'text-green-600' : 'text-gray-500'}>
                        {task.clipboardEnabled ? 'Enabled' : 'Disabled'}
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
                  </div>

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
            <DialogTitle>
              {editingTask ? 'Edit Review Task' : 'Create New Review Task'}
            </DialogTitle>
            <DialogDescription>
              {editingTask
                ? 'Update the review task details below'
                : 'Fill in the details to create a new review task'}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="coins">Reward Coins</Label>
                <Input
                  id="coins"
                  type="number"
                  min={0}
                  value={formData.coins}
                  onChange={(e) => handleChange('coins', Number(e.target.value))}
                  placeholder="150"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="minBackgroundTime">Min Background Time (seconds)</Label>
                <Input
                  id="minBackgroundTime"
                  type="number"
                  min={0}
                  value={formData.minBackgroundTime}
                  onChange={(e) => handleChange('minBackgroundTime', Number(e.target.value))}
                  placeholder="60"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Input
                id="description"
                value={formData.description}
                onChange={(e) => handleChange('description', e.target.value)}
                placeholder="Enter task description"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="link">App Link (URL)</Label>
              <Input
                id="link"
                type="url"
                value={formData.link}
                onChange={(e) => handleChange('link', e.target.value)}
                placeholder="https://play.google.com/store/apps/details?id=..."
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="img">Image URL</Label>
              <Input
                id="img"
                type="url"
                value={formData.img}
                onChange={(e) => handleChange('img', e.target.value)}
                placeholder="https://play-lh.googleusercontent.com/..."
                required
              />
              {formData.img && (
                <div className="relative w-full h-32 bg-muted rounded-lg overflow-hidden mt-2">
                  <img
                    src={formData.img}
                    alt="Preview"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = 'none'
                    }}
                  />
                </div>
              )}
            </div>

            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="space-y-0.5">
                <Label htmlFor="enabled">Enabled</Label>
                <p className="text-sm text-muted-foreground">
                  Whether this task is active and visible to users
                </p>
              </div>
              <Switch
                id="enabled"
                checked={formData.enabled}
                onCheckedChange={(checked) => handleChange('enabled', checked)}
              />
            </div>

            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="space-y-0.5">
                <Label htmlFor="clipboardEnabled">Clipboard Enabled</Label>
                <p className="text-sm text-muted-foreground">
                  Allow users to copy the link to clipboard
                </p>
              </div>
              <Switch
                id="clipboardEnabled"
                checked={formData.clipboardEnabled}
                onCheckedChange={(checked) => handleChange('clipboardEnabled', checked)}
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
                  {editingTask ? 'Update' : 'Create'}
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

