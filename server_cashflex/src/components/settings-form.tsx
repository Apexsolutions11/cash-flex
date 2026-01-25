"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { Save, Loader2 } from "lucide-react"
import { StatusMessage } from "@/components/status-message"

interface SettingsFormProps {
  initialData: any
  onSave: (data: any) => Promise<void>
  saving: boolean
}

interface SettingsFields {
  secureKey: string
  ipKey: string
  payoutKey: string
  adjoeKey: string
  mysteryKey: string
  adminEmail: string
  appName: string
  appNameSH: string
  dailyMaxPayout: number
  referrerCommision: number
  batchSize: number
}

export function SettingsForm({ initialData, onSave, saving }: SettingsFormProps) {
  const [formData, setFormData] = useState<SettingsFields>({
    secureKey: "",
    ipKey: "",
    payoutKey: "",
    adjoeKey: "",
    mysteryKey: "",
    adminEmail: "",
    appName: "Cash Flex",
    appNameSH: "GR",
    dailyMaxPayout: 1,
    referrerCommision: 0.5,
    batchSize: 5000,
  })
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  useEffect(() => {
    if (initialData) {
      setFormData({
        secureKey: initialData.secureKey || "",
        ipKey: initialData.ipKey || "",
        payoutKey: initialData.payoutKey || "",
        adjoeKey: initialData.adjoeKey || "",
        mysteryKey: initialData.mysteryKey || "",
        adminEmail: initialData.adminEmail || "",
        appName: initialData.appName || "Cash Flex",
        appNameSH: initialData.appNameSH || "GR",
        dailyMaxPayout: initialData.dailyMaxPayout ?? 1,
        referrerCommision: initialData.referrerCommision ?? 0.5,
        batchSize: initialData.batchSize ?? 5000,
      })
    }
  }, [initialData])

  const handleChange = (field: keyof SettingsFields, value: string | number) => {
    setFormData({ ...formData, [field]: value })
  }

  const handleSave = async () => {
    try {
      await onSave(formData)
      setMessage({ type: 'success', text: 'Settings saved successfully!' })
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to save settings' })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <div className="space-y-4">
        <h3 className="text-lg font-semibold">API Keys</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label htmlFor="secureKey">Secure Key</Label>
            <Input
              id="secureKey"
              type="password"
              value={formData.secureKey}
              onChange={(e) => handleChange('secureKey', e.target.value)}
              placeholder="Enter secure key"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="ipKey">IP API Key</Label>
            <Input
              id="ipKey"
              type="password"
              value={formData.ipKey}
              onChange={(e) => handleChange('ipKey', e.target.value)}
              placeholder="Enter IP API key"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="payoutKey">Payout Key</Label>
            <Input
              id="payoutKey"
              type="password"
              value={formData.payoutKey}
              onChange={(e) => handleChange('payoutKey', e.target.value)}
              placeholder="Enter payout key"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="adjoeKey">Adjoe Key</Label>
            <Input
              id="adjoeKey"
              type="password"
              value={formData.adjoeKey}
              onChange={(e) => handleChange('adjoeKey', e.target.value)}
              placeholder="Enter Adjoe key"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="mysteryKey">Mystery Key</Label>
            <Input
              id="mysteryKey"
              type="password"
              value={formData.mysteryKey}
              onChange={(e) => handleChange('mysteryKey', e.target.value)}
              placeholder="Enter mystery key"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="adminEmail">Admin Email</Label>
            <Input
              id="adminEmail"
              type="email"
              value={formData.adminEmail}
              onChange={(e) => handleChange('adminEmail', e.target.value)}
              placeholder="admin@example.com"
            />
          </div>
        </div>
      </div>

      <Separator />

      <div className="space-y-4">
        <h3 className="text-lg font-semibold">App Configuration</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label htmlFor="appName">App Name</Label>
            <Input
              id="appName"
              value={formData.appName}
              onChange={(e) => handleChange('appName', e.target.value)}
              placeholder="Cash Flex"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="appNameSH">App Name (Short)</Label>
            <Input
              id="appNameSH"
              value={formData.appNameSH}
              onChange={(e) => handleChange('appNameSH', e.target.value)}
              placeholder="GR"
            />
          </div>
        </div>
      </div>

      <Separator />

      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Limits & Thresholds</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label htmlFor="dailyMaxPayout">Daily Max Payout</Label>
            <Input
              id="dailyMaxPayout"
              type="number"
              min="1"
              value={formData.dailyMaxPayout}
              onChange={(e) => handleChange('dailyMaxPayout', Number(e.target.value))}
              placeholder="1"
            />
            <p className="text-xs text-muted-foreground">
              Maximum number of payouts allowed per user per day
            </p>
          </div>
          <div className="space-y-2">
            <Label htmlFor="referrerCommision">Referrer Commission</Label>
            <Input
              id="referrerCommision"
              type="number"
              min="0"
              max="1"
              step="0.1"
              value={formData.referrerCommision}
              onChange={(e) => handleChange('referrerCommision', Number(e.target.value))}
              placeholder="0.5"
            />
            <p className="text-xs text-muted-foreground">
              Commission rate for referrers (0.0 to 1.0)
            </p>
          </div>
          <div className="space-y-2">
            <Label htmlFor="batchSize">Batch Size</Label>
            <Input
              id="batchSize"
              type="number"
              min="1"
              value={formData.batchSize}
              onChange={(e) => handleChange('batchSize', Number(e.target.value))}
              placeholder="5000"
            />
            <p className="text-xs text-muted-foreground">
              Batch size for cron job operations
            </p>
          </div>
        </div>
      </div>

      <Separator />

      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={saving} size="lg">
          {saving ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Saving...
            </>
          ) : (
            <>
              <Save className="mr-2 h-4 w-4" />
              Save Settings
            </>
          )}
        </Button>
      </div>
    </div>
  )
}

