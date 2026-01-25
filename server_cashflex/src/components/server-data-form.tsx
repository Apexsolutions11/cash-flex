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
import { Separator } from "@/components/ui/separator"
import { Save, Loader2 } from "lucide-react"
import { StatusMessage } from "@/components/status-message"

interface ServerDataFormProps {
  initialData: any
  onSave: (data: any) => Promise<void>
  saving: boolean
}

interface ServerDataFields {
  link: string
  walletEnabled: boolean
}

export function ServerDataForm({ initialData, onSave, saving }: ServerDataFormProps) {
  const [formData, setFormData] = useState<ServerDataFields>({
    link: "",
    walletEnabled: false,
  })
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  useEffect(() => {
    if (initialData) {
      setFormData({
        link: initialData.link || "",
        walletEnabled: initialData.walletEnabled ?? false,
      })
    }
  }, [initialData])

  const handleChange = (field: keyof ServerDataFields, value: string | boolean) => {
    setFormData({ ...formData, [field]: value })
  }

  const handleSave = async () => {
    try {
      await onSave(formData)
      setMessage({ type: 'success', text: 'Server data saved successfully!' })
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to save server data' })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <Label htmlFor="link">Play Store Link</Label>
          <Input
            id="link"
            type="url"
            value={formData.link}
            onChange={(e) => handleChange('link', e.target.value)}
            placeholder="https://play.google.com/store/apps/details?id=..."
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="walletEnabled">Wallet Enabled</Label>
          <Select
            value={String(formData.walletEnabled)}
            onValueChange={(value) => handleChange('walletEnabled', value === 'true')}
          >
            <SelectTrigger id="walletEnabled">
              <SelectValue placeholder="Select option" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="true">True</SelectItem>
              <SelectItem value="false">False</SelectItem>
            </SelectContent>
          </Select>
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
              Save Server Data
            </>
          )}
        </Button>
      </div>
    </div>
  )
}

