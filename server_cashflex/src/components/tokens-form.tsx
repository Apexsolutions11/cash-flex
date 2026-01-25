"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { Save, Loader2 } from "lucide-react"
import { StatusMessage } from "@/components/status-message"

interface TokensFormProps {
  initialData: any
  onSave: (data: any) => Promise<void>
  saving: boolean
}

interface TokensFields {
  appDataToken: string
}

export function TokensForm({ initialData, onSave, saving }: TokensFormProps) {
  const [formData, setFormData] = useState<TokensFields>({
    appDataToken: "",
  })
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  useEffect(() => {
    if (initialData) {
      setFormData({
        appDataToken: initialData.appDataToken || "",
      })
    }
  }, [initialData])

  const handleChange = (field: keyof TokensFields, value: string) => {
    setFormData({ ...formData, [field]: value })
  }

  const handleSave = async () => {
    try {
      await onSave(formData)
      setMessage({ type: 'success', text: 'Tokens saved successfully!' })
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to save tokens' })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <Label htmlFor="appDataToken">App Data Token</Label>
          <Input
            id="appDataToken"
            value={formData.appDataToken}
            onChange={(e) => handleChange('appDataToken', e.target.value)}
            placeholder="Enter app data token"
          />
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
              Save Tokens
            </>
          )}
        </Button>
      </div>
    </div>
  )
}

