"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { Loader2, Save, Plus, Trash2, Edit2, X } from "lucide-react"
import { Textarea } from "@/components/ui/textarea"
import { Switch } from "@/components/ui/switch"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { StatusMessage } from "@/components/status-message"

interface WalletCatalogItem {
  id: string
  country: string[]
  curFactor: number
  enabled: boolean
  ex_country: string[]
  imageUrl?: string
  instructions: string
  symbol: string
  title: string
  denominations?: Denomination[]
}

interface Denomination {
  id: string
  amount: number
  coins: number
  enabled: boolean
  imageUrl?: string
}

interface WalletManagementFormProps {
  onGetAuthToken: () => Promise<string>
}

export function WalletManagementForm({ onGetAuthToken }: WalletManagementFormProps) {
  const [items, setItems] = useState<WalletCatalogItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<WalletCatalogItem | null>(null)
  const [expandedItem, setExpandedItem] = useState<string | null>(null)

  // Form state
  const [formData, setFormData] = useState<WalletCatalogItem>({
    id: "",
    country: [],
    curFactor: 100,
    enabled: true,
    ex_country: [],
    imageUrl: "",
    instructions: "",
    symbol: "",
    title: "",
    denominations: [],
  })

  useEffect(() => {
    fetchItems()
  }, [])

  const fetchItems = async () => {
    try {
      setLoading(true)
      const token = await onGetAuthToken()
      const response = await fetch("/api/admin/wallet-catalog", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error("Failed to fetch wallet catalog")
      }

      const data = await response.json()
      setItems(data.items || [])
    } catch (error) {
      console.error("Error fetching wallet catalog:", error)
      setMessage({ type: "error", text: "Failed to load wallet catalog" })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setLoading(false)
    }
  }

  const handleOpenDialog = (item?: WalletCatalogItem) => {
    if (item) {
      setEditingItem(item)
      setFormData({
        ...item,
        denominations: item.denominations || [],
      })
    } else {
      setEditingItem(null)
      setFormData({
        id: "",
        country: [],
        curFactor: 100,
        enabled: true,
        ex_country: [],
        imageUrl: "",
        instructions: "",
        symbol: "",
        title: "",
        denominations: [],
      })
    }
    setIsDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setIsDialogOpen(false)
    setEditingItem(null)
  }

  const handleSave = async () => {
    if (!formData.id || !formData.title) {
      setMessage({ type: "error", text: "ID and Title are required" })
      setTimeout(() => setMessage(null), 3000)
      return
    }

    try {
      setSaving(true)
      const token = await onGetAuthToken()
      const method = editingItem ? "PUT" : "POST"
      const response = await fetch("/api/admin/wallet-catalog", {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        throw new Error("Failed to save wallet catalog item")
      }

      setMessage({
        type: "success",
        text: editingItem
          ? "Wallet catalog item updated successfully"
          : "Wallet catalog item created successfully",
      })
      setTimeout(() => setMessage(null), 3000)
      handleCloseDialog()
      fetchItems()
    } catch (error) {
      console.error("Error saving wallet catalog item:", error)
      setMessage({ type: "error", text: "Failed to save wallet catalog item" })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm(`Are you sure you want to delete ${id}? This will also delete all denominations.`)) {
      return
    }

    try {
      const token = await onGetAuthToken()
      const response = await fetch(`/api/admin/wallet-catalog?id=${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error("Failed to delete wallet catalog item")
      }

      setMessage({ type: "success", text: "Wallet catalog item deleted successfully" })
      setTimeout(() => setMessage(null), 3000)
      fetchItems()
    } catch (error) {
      console.error("Error deleting wallet catalog item:", error)
      setMessage({ type: "error", text: "Failed to delete wallet catalog item" })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  const handleAddDenomination = () => {
    const newDenom: Denomination = {
      id: `denom_${Date.now()}`,
      amount: 0,
      coins: 0,
      enabled: true,
    }
    setFormData({
      ...formData,
      denominations: [...(formData.denominations || []), newDenom],
    })
  }

  const handleRemoveDenomination = (index: number) => {
    const newDenoms = [...(formData.denominations || [])]
    newDenoms.splice(index, 1)
    setFormData({ ...formData, denominations: newDenoms })
  }

  const handleUpdateDenomination = (index: number, field: keyof Denomination, value: any) => {
    const newDenoms = [...(formData.denominations || [])]
    newDenoms[index] = { ...newDenoms[index], [field]: value }
    setFormData({ ...formData, denominations: newDenoms })
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

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Wallet Catalog Management</CardTitle>
              <CardDescription>
                Manage payment methods and their denominations
              </CardDescription>
            </div>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="mr-2 h-4 w-4" />
              Add Payment Method
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {items.length === 0 ? (
              <div className="text-center py-12 text-muted-foreground">
                No wallet catalog items found. Click "Add Payment Method" to create one.
              </div>
            ) : (
              items.map((item) => (
                <Card key={item.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3">
                          <h3 className="text-lg font-semibold">{item.title}</h3>
                          <span className="text-sm text-muted-foreground">({item.id})</span>
                          <Switch
                            checked={item.enabled}
                            onCheckedChange={async (checked) => {
                              try {
                                const token = await onGetAuthToken()
                                const response = await fetch("/api/admin/wallet-catalog", {
                                  method: "PUT",
                                  headers: {
                                    "Content-Type": "application/json",
                                    Authorization: `Bearer ${token}`,
                                  },
                                  body: JSON.stringify({ ...item, enabled: checked }),
                                })
                                if (response.ok) {
                                  fetchItems()
                                }
                              } catch (error) {
                                console.error("Error updating enabled status:", error)
                              }
                            }}
                          />
                        </div>
                        <div className="mt-2 space-y-1 text-sm text-muted-foreground">
                          <p>Symbol: {item.symbol}</p>
                          <p>Currency Factor: {item.curFactor}</p>
                          <p>Countries: {item.country.join(", ") || "None"}</p>
                          <p>Excluded Countries: {item.ex_country.join(", ") || "None"}</p>
                          <p>Denominations: {item.denominations?.length || 0}</p>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setExpandedItem(expandedItem === item.id ? null : item.id)
                          }}
                        >
                          {expandedItem === item.id ? "Collapse" : "Expand"}
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleOpenDialog(item)}
                        >
                          <Edit2 className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => handleDelete(item.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                    {expandedItem === item.id && (
                      <div className="mt-4 pt-4 border-t">
                        <div className="space-y-2">
                          <h4 className="font-semibold">Instructions:</h4>
                          <p className="text-sm text-muted-foreground whitespace-pre-line">
                            {item.instructions || "No instructions"}
                          </p>
                          {item.denominations && item.denominations.length > 0 && (
                            <>
                              <h4 className="font-semibold mt-4">Denominations:</h4>
                              <div className="space-y-2">
                                {item.denominations.map((denom, idx) => (
                                  <div
                                    key={denom.id || idx}
                                    className="flex items-center justify-between p-2 bg-muted rounded"
                                  >
                                    <div>
                                      <span className="font-medium">
                                        {item.symbol}
                                        {denom.amount} = {denom.coins} coins
                                      </span>
                                      <span className="ml-2 text-xs text-muted-foreground">
                                        ({denom.enabled ? "Enabled" : "Disabled"})
                                      </span>
                                    </div>
                                  </div>
                                ))}
                              </div>
                            </>
                          )}
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      {/* Edit/Create Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingItem ? "Edit Payment Method" : "Create Payment Method"}
            </DialogTitle>
            <DialogDescription>
              {editingItem
                ? "Update the payment method details"
                : "Add a new payment method to the wallet catalog"}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="id">ID *</Label>
                <Input
                  id="id"
                  value={formData.id}
                  onChange={(e) => setFormData({ ...formData, id: e.target.value.toUpperCase() })}
                  placeholder="AMAZON"
                  disabled={!!editingItem}
                />
                <p className="text-xs text-muted-foreground">
                  {editingItem ? "ID cannot be changed" : "Unique identifier (e.g., AMAZON)"}
                </p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="title">Title *</Label>
                <Input
                  id="title"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="Amazon Shopping Voucher"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="imageUrl">Image URL</Label>
              <Input
                id="imageUrl"
                type="url"
                value={formData.imageUrl || ""}
                onChange={(e) => setFormData({ ...formData, imageUrl: e.target.value })}
                placeholder="https://.../amazon.png"
              />
              <p className="text-xs text-muted-foreground">
                Optional. Shown in the app for the payment method.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="symbol">Symbol</Label>
                <Input
                  id="symbol"
                  value={formData.symbol}
                  onChange={(e) => setFormData({ ...formData, symbol: e.target.value })}
                  placeholder="₹"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="curFactor">Currency Factor</Label>
                <Input
                  id="curFactor"
                  type="number"
                  value={formData.curFactor}
                  onChange={(e) =>
                    setFormData({ ...formData, curFactor: Number(e.target.value) })
                  }
                  placeholder="100"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="country">Countries (comma-separated)</Label>
              <Input
                id="country"
                value={formData.country.join(", ")}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    country: e.target.value.split(",").map((s) => s.trim()).filter(Boolean),
                  })
                }
                placeholder="IN, US, UK"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="ex_country">Excluded Countries (comma-separated)</Label>
              <Input
                id="ex_country"
                value={formData.ex_country.join(", ")}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    ex_country: e.target.value.split(",").map((s) => s.trim()).filter(Boolean),
                  })
                }
                placeholder="CN, RU"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="instructions">Instructions</Label>
              <Textarea
                id="instructions"
                value={formData.instructions}
                onChange={(e) => setFormData({ ...formData, instructions: e.target.value })}
                placeholder="Enter step-by-step instructions..."
                rows={4}
              />
            </div>

            <div className="flex items-center space-x-2">
              <Switch
                id="enabled"
                checked={formData.enabled}
                onCheckedChange={(checked) => setFormData({ ...formData, enabled: checked })}
              />
              <Label htmlFor="enabled">Enabled</Label>
            </div>

            <Separator />

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="text-base font-semibold">Denominations</Label>
                <Button variant="outline" size="sm" onClick={handleAddDenomination}>
                  <Plus className="mr-2 h-4 w-4" />
                  Add Denomination
                </Button>
              </div>

              {formData.denominations && formData.denominations.length > 0 ? (
                <div className="space-y-3">
                  {formData.denominations.map((denom, index) => (
                    <Card key={denom.id || index}>
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between gap-4">
                          <div className="grid grid-cols-4 gap-4 flex-1">
                            <div className="space-y-2">
                              <Label>Amount</Label>
                              <Input
                                type="number"
                                value={denom.amount}
                                onChange={(e) =>
                                  handleUpdateDenomination(
                                    index,
                                    "amount",
                                    Number(e.target.value)
                                  )
                                }
                                placeholder="100"
                              />
                            </div>
                            <div className="space-y-2">
                              <Label>Coins</Label>
                              <Input
                                type="number"
                                value={denom.coins}
                                onChange={(e) =>
                                  handleUpdateDenomination(
                                    index,
                                    "coins",
                                    Number(e.target.value)
                                  )
                                }
                                placeholder="10000"
                              />
                            </div>
                            <div className="space-y-2">
                              <Label>Image URL</Label>
                              <Input
                                type="url"
                                value={denom.imageUrl || ""}
                                onChange={(e) =>
                                  handleUpdateDenomination(index, "imageUrl", e.target.value)
                                }
                                placeholder="https://.../voucher.png"
                              />
                            </div>
                            <div className="space-y-2">
                              <Label>Enabled</Label>
                              <div className="flex items-center space-x-2 pt-2">
                                <Switch
                                  checked={denom.enabled}
                                  onCheckedChange={(checked) =>
                                    handleUpdateDenomination(index, "enabled", checked)
                                  }
                                />
                              </div>
                            </div>
                          </div>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleRemoveDenomination(index)}
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-muted-foreground text-center py-4">
                  No denominations added. Click "Add Denomination" to add one.
                </p>
              )}
            </div>

            <Separator />

            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={handleCloseDialog}>
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
                    {editingItem ? "Update" : "Create"}
                  </>
                )}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}

