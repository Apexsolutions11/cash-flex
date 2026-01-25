"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { Send, Loader2, Calendar, Clock, Repeat } from "lucide-react"
import { StatusMessage } from "@/components/status-message"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

interface NotificationFormProps {
  onGetAuthToken: () => Promise<string>
}

interface ScheduledNotification {
  id: string
  title: string
  body: string
  scheduledFor: string
  intervalMinutes?: number
  isRecurring: boolean
  status: 'pending' | 'sent' | 'active' | 'paused'
  createdAt: string
  lastSentAt?: string
  nextSendAt?: string
  sendCount: number
}

export function NotificationForm({ onGetAuthToken }: NotificationFormProps) {
  const [title, setTitle] = useState("")
  const [body, setBody] = useState("")
  const [notificationType, setNotificationType] = useState<"send-now" | "schedule-once" | "schedule-recurring">("send-now")
  const [scheduledDate, setScheduledDate] = useState("")
  const [scheduledTime, setScheduledTime] = useState("")
  const [intervalMinutes, setIntervalMinutes] = useState("60")
  const [sending, setSending] = useState(false)
  const [scheduledNotifications, setScheduledNotifications] = useState<ScheduledNotification[]>([])
  const [loadingScheduled, setLoadingScheduled] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleSendNow = async () => {
    if (!title.trim() || !body.trim()) {
      setMessage({ type: 'error', text: 'Please enter both title and body' })
      return
    }

    setSending(true)
    setMessage(null)

    try {
      const token = await onGetAuthToken()
      const response = await fetch('/api/admin/notifications/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          title: title.trim(),
          body: body.trim(),
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to send notification')
      }

      setMessage({ type: 'success', text: 'Notification sent successfully to all users!' })
      setTitle("")
      setBody("")
    } catch (error: any) {
      setMessage({ type: 'error', text: error.message || 'Failed to send notification' })
    } finally {
      setSending(false)
    }
  }

  const handleSchedule = async () => {
    if (!title.trim() || !body.trim()) {
      setMessage({ type: 'error', text: 'Please enter both title and body' })
      return
    }

    if (notificationType !== "send-now") {
      if (!scheduledDate || !scheduledTime) {
        setMessage({ type: 'error', text: 'Please select date and time for scheduled notification' })
        return
      }

      if (notificationType === "schedule-recurring" && (!intervalMinutes || parseInt(intervalMinutes) < 1)) {
        setMessage({ type: 'error', text: 'Please enter a valid interval (minimum 1 minute)' })
        return
      }
    }

    setSending(true)
    setMessage(null)

    try {
      const token = await onGetAuthToken()
      
      const scheduledDateTime = new Date(`${scheduledDate}T${scheduledTime}`).toISOString()

      const response = await fetch('/api/admin/notifications/schedule', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          title: title.trim(),
          body: body.trim(),
          scheduledFor: scheduledDateTime,
          isRecurring: notificationType === "schedule-recurring",
          intervalMinutes: notificationType === "schedule-recurring" ? parseInt(intervalMinutes) : undefined,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to schedule notification')
      }

      setMessage({ 
        type: 'success', 
        text: notificationType === "send-now" 
          ? 'Notification sent successfully!' 
          : 'Notification scheduled successfully!' 
      })
      setTitle("")
      setBody("")
      setScheduledDate("")
      setScheduledTime("")
      loadScheduledNotifications()
    } catch (error: any) {
      setMessage({ type: 'error', text: error.message || 'Failed to schedule notification' })
    } finally {
      setSending(false)
    }
  }

  const loadScheduledNotifications = async () => {
    setLoadingScheduled(true)
    try {
      const token = await onGetAuthToken()
      const response = await fetch('/api/admin/notifications/scheduled', {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      })

      const data = await response.json()

      if (response.ok && data.notifications) {
        setScheduledNotifications(data.notifications)
      }
    } catch (error) {
      console.error('Error loading scheduled notifications:', error)
    } finally {
      setLoadingScheduled(false)
    }
  }

  const handleToggleNotification = async (id: string, currentStatus: string) => {
    try {
      const token = await onGetAuthToken()
      const newStatus = currentStatus === 'active' ? 'paused' : 'active'
      
      const response = await fetch(`/api/admin/notifications/scheduled/${id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ status: newStatus }),
      })

      if (response.ok) {
        loadScheduledNotifications()
      }
    } catch (error) {
      console.error('Error toggling notification:', error)
    }
  }

  const handleDeleteNotification = async (id: string) => {
    if (!confirm('Are you sure you want to delete this scheduled notification?')) {
      return
    }

    try {
      const token = await onGetAuthToken()
      const response = await fetch(`/api/admin/notifications/scheduled/${id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      })

      if (response.ok) {
        loadScheduledNotifications()
        setMessage({ type: 'success', text: 'Scheduled notification deleted successfully' })
      }
    } catch (error) {
      console.error('Error deleting notification:', error)
      setMessage({ type: 'error', text: 'Failed to delete notification' })
    }
  }

  // Load scheduled notifications on mount
  useEffect(() => {
    loadScheduledNotifications()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const formatDateTime = (isoString: string) => {
    const date = new Date(isoString)
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const getMinDateTime = () => {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    const hours = String(now.getHours()).padStart(2, '0')
    const minutes = String(now.getMinutes()).padStart(2, '0')
    return {
      date: `${year}-${month}-${day}`,
      time: `${hours}:${minutes}`
    }
  }

  const minDateTime = getMinDateTime()

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Send Notification</CardTitle>
          <CardDescription>
            Send push notifications to all users or schedule them for later
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Tabs value={notificationType} onValueChange={(v) => setNotificationType(v as any)}>
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="send-now">
                <Send className="mr-2 h-4 w-4" />
                Send Now
              </TabsTrigger>
              <TabsTrigger value="schedule-once">
                <Calendar className="mr-2 h-4 w-4" />
                Schedule Once
              </TabsTrigger>
              <TabsTrigger value="schedule-recurring">
                <Repeat className="mr-2 h-4 w-4" />
                Recurring
              </TabsTrigger>
            </TabsList>

            <TabsContent value="send-now" className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="title">Title</Label>
                <Input
                  id="title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Enter notification title"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="body">Message</Label>
                <Textarea
                  id="body"
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="Enter notification message"
                  rows={4}
                />
              </div>

              <Button 
                onClick={handleSendNow} 
                disabled={sending}
                className="w-full"
              >
                {sending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Sending...
                  </>
                ) : (
                  <>
                    <Send className="mr-2 h-4 w-4" />
                    Send Now
                  </>
                )}
              </Button>
            </TabsContent>

            <TabsContent value="schedule-once" className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="schedule-title">Title</Label>
                <Input
                  id="schedule-title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Enter notification title"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="schedule-body">Message</Label>
                <Textarea
                  id="schedule-body"
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="Enter notification message"
                  rows={4}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="scheduled-date">Date</Label>
                  <Input
                    id="scheduled-date"
                    type="date"
                    value={scheduledDate}
                    onChange={(e) => setScheduledDate(e.target.value)}
                    min={minDateTime.date}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="scheduled-time">Time</Label>
                  <Input
                    id="scheduled-time"
                    type="time"
                    value={scheduledTime}
                    onChange={(e) => setScheduledTime(e.target.value)}
                    min={scheduledDate === minDateTime.date ? minDateTime.time : undefined}
                  />
                </div>
              </div>

              <Button 
                onClick={handleSchedule} 
                disabled={sending}
                className="w-full"
              >
                {sending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Scheduling...
                  </>
                ) : (
                  <>
                    <Calendar className="mr-2 h-4 w-4" />
                    Schedule Notification
                  </>
                )}
              </Button>
            </TabsContent>

            <TabsContent value="schedule-recurring" className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="recurring-title">Title</Label>
                <Input
                  id="recurring-title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Enter notification title"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="recurring-body">Message</Label>
                <Textarea
                  id="recurring-body"
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="Enter notification message"
                  rows={4}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="recurring-date">Start Date</Label>
                  <Input
                    id="recurring-date"
                    type="date"
                    value={scheduledDate}
                    onChange={(e) => setScheduledDate(e.target.value)}
                    min={minDateTime.date}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="recurring-time">Start Time</Label>
                  <Input
                    id="recurring-time"
                    type="time"
                    value={scheduledTime}
                    onChange={(e) => setScheduledTime(e.target.value)}
                    min={scheduledDate === minDateTime.date ? minDateTime.time : undefined}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="interval">Interval (minutes)</Label>
                <Input
                  id="interval"
                  type="number"
                  value={intervalMinutes}
                  onChange={(e) => setIntervalMinutes(e.target.value)}
                  placeholder="60"
                  min="1"
                />
                <p className="text-xs text-muted-foreground">
                  How often to send this notification (minimum 1 minute)
                </p>
              </div>

              <Button 
                onClick={handleSchedule} 
                disabled={sending}
                className="w-full"
              >
                {sending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Scheduling...
                  </>
                ) : (
                  <>
                    <Repeat className="mr-2 h-4 w-4" />
                    Schedule Recurring Notification
                  </>
                )}
              </Button>
            </TabsContent>
          </Tabs>

          {message && (
            <StatusMessage
              message={message}
              onDismiss={() => setMessage(null)}
            />
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Scheduled Notifications</CardTitle>
          <CardDescription>
            View and manage your scheduled notifications
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {loadingScheduled ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin" />
              </div>
            ) : scheduledNotifications.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">
                No scheduled notifications
              </p>
            ) : (
              <div className="space-y-3">
                {scheduledNotifications.map((notification) => (
                  <div
                    key={notification.id}
                    className="border rounded-lg p-4 space-y-2"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <h4 className="font-semibold">{notification.title}</h4>
                        <p className="text-sm text-muted-foreground mt-1">
                          {notification.body}
                        </p>
                        <div className="flex flex-wrap gap-4 mt-3 text-xs text-muted-foreground">
                          <span>
                            <strong>Type:</strong>{' '}
                            {notification.isRecurring ? (
                              <>
                                <Repeat className="inline h-3 w-3 mr-1" />
                                Recurring ({notification.intervalMinutes} min)
                              </>
                            ) : (
                              <>
                                <Calendar className="inline h-3 w-3 mr-1" />
                                One-time
                              </>
                            )}
                          </span>
                          <span>
                            <strong>Status:</strong>{' '}
                            <span
                              className={
                                notification.status === 'active'
                                  ? 'text-green-600'
                                  : notification.status === 'sent'
                                  ? 'text-blue-600'
                                  : 'text-gray-600'
                              }
                            >
                              {notification.status.charAt(0).toUpperCase() +
                                notification.status.slice(1)}
                            </span>
                          </span>
                          {notification.nextSendAt && (
                            <span>
                              <strong>Next:</strong> {formatDateTime(notification.nextSendAt)}
                            </span>
                          )}
                          {notification.lastSentAt && (
                            <span>
                              <strong>Last Sent:</strong> {formatDateTime(notification.lastSentAt)}
                            </span>
                          )}
                          <span>
                            <strong>Sent:</strong> {notification.sendCount} times
                          </span>
                        </div>
                      </div>
                      <div className="flex gap-2 ml-4">
                        {notification.status !== 'sent' && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() =>
                              handleToggleNotification(notification.id, notification.status)
                            }
                          >
                            {notification.status === 'active' ? 'Pause' : 'Resume'}
                          </Button>
                        )}
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => handleDeleteNotification(notification.id)}
                        >
                          Delete
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
            <Button
              variant="outline"
              onClick={loadScheduledNotifications}
              disabled={loadingScheduled}
              className="w-full"
            >
              {loadingScheduled ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Loading...
                </>
              ) : (
                'Refresh'
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

