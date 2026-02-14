"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { Loader2, Save, GripVertical } from "lucide-react"
import { Switch } from "@/components/ui/switch"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragEndEvent,
} from "@dnd-kit/core"
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable"
import { CSS } from "@dnd-kit/utilities"
import { StatusMessage } from "@/components/status-message"

export type ComponentId =
  | "promo-app-1"
  | "promo-app-2"
  | "promo-app-3"
  | "promo-app-4"
  | "review-offers"
  | "gemee-jackpot"
  | "tic-tac-toe"
  | "math-quiz"
  | "adjoe"
  | "more-apps"
  | "rate-us"
  | "how-to-earn-follow-us"
  | "wallet-redeem-button"
  | "wallet-transaction-section"
  | "wallet-transaction-history-section"
  | "wallet-reward-history-section"
  | "invite-share-via"
  | "invite-how-it-works"

export type LayoutType = "normal" | "google" | "international"
export type PageType = "homepage" | "wallet" | "invite"

type LayoutItemType = "component" | "heading"

interface ComponentConfig {
  id: string
  enabled: boolean
  order: number
  type?: LayoutItemType
  title?: string
  badgeText?: string
  badgeVariant?: "none" | "default" | "popular" | "new" | "hot"
  shakeAnimationEnabled?: boolean
}

interface PageLayoutConfig {
  homepage: ComponentConfig[]
  wallet: ComponentConfig[]
  invite: ComponentConfig[]
}

interface LayoutManagementFormProps {
  onGetAuthToken: () => Promise<string>
}

const COMPONENT_LABELS: Record<ComponentId, string> = {
  "promo-app-1": "Promotion App 1",
  "promo-app-2": "Promotion App 2",
  "promo-app-3": "Promotion App 3",
  "promo-app-4": "Promotion App 4",
  "review-offers": "Review Offers",
  "gemee-jackpot": "Gemee Jackpot",
  "tic-tac-toe": "Tic Tac Toe",
  "math-quiz": "Math Quiz",
  "adjoe": "Adjoe",
  "more-apps": "More Apps",
  "rate-us": "Rate Us",
  "how-to-earn-follow-us": "How to Earn & Follow Us",
  "wallet-redeem-button": "Redeem Button",
  "wallet-transaction-section": "History Section (Master)",
  "wallet-transaction-history-section": "Transaction History",
  "wallet-reward-history-section": "Reward History",
  "invite-share-via": "Share Via",
  "invite-how-it-works": "How It Works",
}

const getComponentLabel = (id: string) =>
  (COMPONENT_LABELS as Record<string, string>)[id] ?? id

// Fixed components that cannot be rearranged
// These components have fixed positions in the UI:
// - promo-app-1, promo-app-2: Always at top row (horizontal, side-by-side)
// - how-to-earn-follow-us: Always at second row right (Watch & Follow buttons)
// Admins can enable/disable these but cannot change their position or order
const FIXED_HOMEPAGE_COMPONENTS: ComponentId[] = [
  "promo-app-1",  // Fixed top row left
  "promo-app-2",  // Fixed top row right
  "how-to-earn-follow-us",  // Fixed second row right
]

// Draggable components (can be reordered via admin panel)
const DEFAULT_HOMEPAGE_COMPONENTS: ComponentId[] = [
  "promo-app-3",
  "promo-app-4",
  "review-offers",
  "tic-tac-toe",
  "math-quiz",
  "gemee-jackpot",
  "adjoe",
  "more-apps",
  "rate-us",
]

const DEFAULT_WALLET_COMPONENTS: ComponentId[] = [
  "wallet-redeem-button",
  "wallet-transaction-section",
  "wallet-transaction-history-section",
  "wallet-reward-history-section",
]

const DEFAULT_INVITE_COMPONENTS: ComponentId[] = [
  "invite-share-via",
  "invite-how-it-works",
]

function SortableComponentItem({
  component,
  onToggleEnabled,
  onUpdateTitle,
  onUpdateBadgeText,
  onUpdateBadgeVariant,
  onUpdateShakeAnimation,
}: {
  component: ComponentConfig
  onToggleEnabled: (id: string) => void
  onUpdateTitle: (id: string, title: string) => void
  onUpdateBadgeText: (id: string, text: string) => void
  onUpdateBadgeVariant: (id: string, variant: string) => void
  onUpdateShakeAnimation: (id: string, enabled: boolean) => void
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: component.id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  }

  return (
    <Card 
      ref={setNodeRef} 
      style={style} 
      className={isDragging ? "ring-2 ring-primary shadow-lg" : ""}
    >
      <CardContent className="p-4">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3 flex-1">
            <div
              {...attributes}
              {...listeners}
              className="cursor-grab active:cursor-grabbing touch-none p-1 hover:bg-muted rounded"
            >
              <GripVertical className="h-5 w-5 text-muted-foreground" />
            </div>
            <div className="flex-1">
              {component.type === "heading" ? (
                <div className="space-y-2">
                  <Label className="text-base font-medium">Section Heading</Label>
                  <Input
                    value={component.title || ""}
                    onChange={(e) => onUpdateTitle(component.id, e.target.value)}
                    placeholder="Enter heading name (e.g. Offers)"
                  />
                </div>
              ) : (
                <div className="space-y-2">
                  <Label className="text-base font-medium">
                    {getComponentLabel(component.id)}
                  </Label>
                  {component.id.startsWith("promo-app-") ? null : (
                    <div className="space-y-3">
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <div className="space-y-1">
                          <Label className="text-xs text-muted-foreground">Badge Text</Label>
                          <Input
                            value={component.badgeText || ""}
                            onChange={(e) => onUpdateBadgeText(component.id, e.target.value)}
                            placeholder="POPULAR"
                          />
                        </div>
                        <div className="space-y-1">
                          <Label className="text-xs text-muted-foreground">Badge Variant</Label>
                          <Select
                            value={(component.badgeVariant || "none") as string}
                            onValueChange={(value) => onUpdateBadgeVariant(component.id, value)}
                          >
                            <SelectTrigger>
                              <SelectValue placeholder="Select variant" />
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
                      {component.id === "gemee-jackpot" && (
                        <div className="flex items-center justify-between p-2 bg-muted/50 rounded-md">
                          <div className="space-y-0.5">
                            <Label className="text-xs font-medium">Shake Animation</Label>
                            <p className="text-xs text-muted-foreground">
                              Enable continuous shake effect on the card
                            </p>
                          </div>
                          <Switch
                            checked={component.shakeAnimationEnabled ?? false}
                            onCheckedChange={(checked) => onUpdateShakeAnimation(component.id, checked)}
                          />
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Switch
              checked={component.enabled}
              onCheckedChange={() => onToggleEnabled(component.id)}
            />
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

function WalletComponentItem({
  component,
  onToggleEnabled,
}: {
  component: ComponentConfig
  onToggleEnabled: (id: string) => void
}) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between gap-4">
          <div className="flex-1">
            <Label className="text-base font-medium">
              {getComponentLabel(component.id)}
            </Label>
          </div>

          <div className="flex items-center gap-2">
            <Switch
              checked={component.enabled}
              onCheckedChange={() => onToggleEnabled(component.id)}
            />
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

function FixedComponentItem({
  component,
  onToggleEnabled,
}: {
  component: ComponentConfig
  onToggleEnabled: (id: string) => void
}) {
  return (
    <Card className="border-2 border-dashed border-muted-foreground/30">
      <CardContent className="p-4">
        <div className="flex items-center justify-between gap-4">
          <div className="flex-1">
            <Label className="text-base font-medium">
              {getComponentLabel(component.id)}
            </Label>
            <p className="text-xs text-muted-foreground mt-1">
              (Fixed position - cannot be rearranged)
            </p>
          </div>

          <div className="flex items-center gap-2">
            <Switch
              checked={component.enabled}
              onCheckedChange={() => onToggleEnabled(component.id)}
            />
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export function LayoutManagementForm({ onGetAuthToken }: LayoutManagementFormProps) {
  const [selectedLayout, setSelectedLayout] = useState<LayoutType>("normal")
  const [selectedPage, setSelectedPage] = useState<PageType>("homepage")
  const [layouts, setLayouts] = useState<Record<LayoutType, PageLayoutConfig>>({
    normal: {
      homepage: [
        ...FIXED_HOMEPAGE_COMPONENTS.map((id, index) => ({
          id,
          enabled: true,
          order: -1000 + index,
        })),
        ...DEFAULT_HOMEPAGE_COMPONENTS.map((id, index) => ({
          id,
          enabled: true,
          order: index,
        })),
      ],
      wallet: DEFAULT_WALLET_COMPONENTS.map((id, index) => ({
        id,
        enabled: true,
        order: index,
      })),
      invite: DEFAULT_INVITE_COMPONENTS.map((id, index) => ({
        id,
        enabled: true,
        order: index,
      })),
    },
    google: {
      homepage: [
        ...FIXED_HOMEPAGE_COMPONENTS.map((id, index) => ({
          id,
          enabled: true,
          order: -1000 + index,
        })),
        ...DEFAULT_HOMEPAGE_COMPONENTS.map((id, index) => ({
          id,
          enabled: true,
          order: index,
        })),
      ],
      wallet: DEFAULT_WALLET_COMPONENTS.map((id, index) => ({
        id,
        enabled: true,
        order: index,
      })),
      invite: DEFAULT_INVITE_COMPONENTS.map((id, index) => ({
        id,
        enabled: true,
        order: index,
      })),
    },
    international: {
      homepage: [
        ...FIXED_HOMEPAGE_COMPONENTS.map((id, index) => ({
          id,
          enabled: true,
          order: -1000 + index,
        })),
        ...DEFAULT_HOMEPAGE_COMPONENTS.map((id, index) => ({
          id,
          enabled: true,
          order: index,
        })),
      ],
      wallet: DEFAULT_WALLET_COMPONENTS.map((id, index) => ({
        id,
        enabled: true,
        order: index,
      })),
      invite: DEFAULT_INVITE_COMPONENTS.map((id, index) => ({
        id,
        enabled: true,
        order: index,
      })),
    },
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null)

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  )

  useEffect(() => {
    fetchLayouts()
  }, [])

  const fetchLayouts = async () => {
    try {
      setLoading(true)
      const token = await onGetAuthToken()
      const response = await fetch("/api/admin/layouts", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error("Failed to fetch layouts")
      }

      const data = await response.json()
      
      // Merge with defaults to ensure all components exist
      const mergedLayouts: Record<LayoutType, PageLayoutConfig> = {
        normal: mergeLayoutWithDefaults(data.normal || {}),
        google: mergeLayoutWithDefaults(data.google || {}),
        international: mergeLayoutWithDefaults(data.international || {}),
      }

      setLayouts(mergedLayouts)
    } catch (error) {
      console.error("Error fetching layouts:", error)
      setMessage({ type: "error", text: "Failed to load layouts" })
      setTimeout(() => setMessage(null), 3000)
    } finally {
      setLoading(false)
    }
  }

  const mergeLayoutWithDefaults = (layoutData: any): PageLayoutConfig => {
    const normalize = (comp: any, fallbackOrder: number): ComponentConfig => ({
      id: String(comp?.id ?? ""),
      enabled: comp?.enabled ?? true,
      order: typeof comp?.order === "number" ? comp.order : fallbackOrder,
      type: comp?.type === "heading" ? "heading" : "component",
      title: typeof comp?.title === "string" ? comp.title : undefined,
      badgeText: typeof comp?.badgeText === "string" ? comp.badgeText : undefined,
      badgeVariant: typeof comp?.badgeVariant === "string" ? comp.badgeVariant : undefined,
      shakeAnimationEnabled: typeof comp?.shakeAnimationEnabled === "boolean" ? comp.shakeAnimationEnabled : undefined,
    })

    // Handle homepage components (preserve custom items like headings)
    const homepageExistingRaw: any[] = Array.isArray(layoutData.homepage) ? layoutData.homepage : []
    const homepageExisting = homepageExistingRaw.map((c, idx) => normalize(c, idx))

    const homepageById = new Map<string, ComponentConfig>()
    homepageExisting.forEach((c) => homepageById.set(c.id, c))

    // Fixed components always present
    const fixedComponents: ComponentConfig[] = FIXED_HOMEPAGE_COMPONENTS.map((id, index) => {
      const existing = homepageById.get(id)
      return existing
        ? { ...existing, id, type: "component" }
        : { id, enabled: true, order: -1000 + index, type: "component" }
    })

    // Keep everything else already saved (including headings)
    const fixedSet = new Set<string>(FIXED_HOMEPAGE_COMPONENTS)
    const restExisting = homepageExisting.filter((c) => !fixedSet.has(c.id))

    const presentDraggableIds = new Set<string>(
      restExisting.filter((c) => c.type !== "heading").map((c) => c.id),
    )

    const maxOrder = Math.max(
      -1,
      ...fixedComponents.map((c) => c.order),
      ...restExisting.map((c) => c.order),
    )

    const missingDraggables: ComponentConfig[] = DEFAULT_HOMEPAGE_COMPONENTS
      .filter((id) => !presentDraggableIds.has(id))
      .map((id, idx) => ({
        id,
        enabled: true,
        order: maxOrder + 1 + idx,
        type: "component",
      }))

    const homepage = [...fixedComponents, ...restExisting, ...missingDraggables].sort(
      (a, b) => a.order - b.order,
    )

    // Handle wallet components
    const walletExistingRaw: any[] = Array.isArray(layoutData.wallet) ? layoutData.wallet : []
    const walletExisting = walletExistingRaw.map((c, idx) => normalize(c, idx))
    const walletById = new Map<string, ComponentConfig>()
    walletExisting.forEach((c) => walletById.set(c.id, c))

    const wallet = DEFAULT_WALLET_COMPONENTS.map((id, index) => {
      const existing = walletById.get(id)
      return (
        existing ||
        ({
          id,
          enabled: true,
          order: index,
          type: "component",
        } as ComponentConfig)
      )
    }).sort((a, b) => a.order - b.order)

    // Handle invite page components
    const inviteExistingRaw: any[] = Array.isArray(layoutData.invite) ? layoutData.invite : []
    const inviteExisting = inviteExistingRaw.map((c, idx) => normalize(c, idx))
    const inviteById = new Map<string, ComponentConfig>()
    inviteExisting.forEach((c) => inviteById.set(c.id, c))

    const invite = DEFAULT_INVITE_COMPONENTS.map((id, index) => {
      const existing = inviteById.get(id)
      return (
        existing ||
        ({
          id,
          enabled: true,
          order: index,
          type: "component",
        } as ComponentConfig)
      )
    }).sort((a, b) => a.order - b.order)

    return { homepage, wallet, invite }
  }

  const handleToggleEnabled = (componentId: string) => {
    setLayouts((prev) => {
      const newLayouts = { ...prev }
      const currentPageLayout = newLayouts[selectedLayout][selectedPage]
      const updatedPageLayout = currentPageLayout.map((comp) =>
        comp.id === componentId ? { ...comp, enabled: !comp.enabled } : comp
      )
      newLayouts[selectedLayout] = {
        ...newLayouts[selectedLayout],
        [selectedPage]: updatedPageLayout,
      }
      return newLayouts
    })
  }

  const handleUpdateTitle = (id: string, title: string) => {
    setLayouts((prev) => {
      const next = { ...prev }
      const currentPageLayout = next[selectedLayout][selectedPage]
      next[selectedLayout] = {
        ...next[selectedLayout],
        [selectedPage]: currentPageLayout.map((c) => (c.id === id ? { ...c, title } : c)),
      }
      return next
    })
  }

  const handleUpdateBadgeText = (id: string, badgeText: string) => {
    setLayouts((prev) => {
      const next = { ...prev }
      const currentPageLayout = next[selectedLayout][selectedPage]
      next[selectedLayout] = {
        ...next[selectedLayout],
        [selectedPage]: currentPageLayout.map((c) => (c.id === id ? { ...c, badgeText } : c)),
      }
      return next
    })
  }

  const handleUpdateBadgeVariant = (id: string, badgeVariant: string) => {
    setLayouts((prev) => {
      const next = { ...prev }
      const currentPageLayout = next[selectedLayout][selectedPage]
      next[selectedLayout] = {
        ...next[selectedLayout],
        [selectedPage]: currentPageLayout.map((c) => (c.id === id ? { ...c, badgeVariant } : c)),
      }
      return next
    })
  }

  const handleUpdateShakeAnimation = (id: string, enabled: boolean) => {
    setLayouts((prev) => {
      const next = { ...prev }
      const currentPageLayout = next[selectedLayout][selectedPage]
      next[selectedLayout] = {
        ...next[selectedLayout],
        [selectedPage]: currentPageLayout.map((c) => (c.id === id ? { ...c, shakeAnimationEnabled: enabled } : c)),
      }
      return next
    })
  }

  const handleAddHeading = () => {
    const title = window.prompt("Heading name (will show in app):", "Offers")
    if (title == null) return
    const trimmed = title.trim()
    const id = `heading-${Date.now()}`

    setLayouts((prev) => {
      const next = { ...prev }
      const pageLayout = next[selectedLayout][selectedPage]
      const maxOrder = Math.max(-1, ...pageLayout.map((c) => c.order))
      const newItem: ComponentConfig = {
        id,
        enabled: true,
        order: maxOrder + 1,
        type: "heading",
        title: trimmed,
      }
      next[selectedLayout] = {
        ...next[selectedLayout],
        [selectedPage]: [...pageLayout, newItem],
      }
      return next
    })
  }

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event

    if (over && active.id !== over.id && selectedPage === "homepage") {
      setLayouts((prev) => {
        const newLayouts = { ...prev }
        const pageLayout = newLayouts[selectedLayout][selectedPage]

        const fixed = pageLayout.filter((c) => FIXED_HOMEPAGE_COMPONENTS.includes(c.id as ComponentId))
        fixed.forEach((c, idx) => {
          c.order = -1000 + idx
        })

        const draggable = pageLayout.filter((c) => !FIXED_HOMEPAGE_COMPONENTS.includes(c.id as ComponentId))
        const oldIndex = draggable.findIndex((c) => c.id === active.id)
        const newIndex = draggable.findIndex((c) => c.id === over.id)

        const reordered = arrayMove(draggable, oldIndex, newIndex)
        reordered.forEach((comp, i) => {
          comp.order = i
        })

        newLayouts[selectedLayout][selectedPage] = [...fixed, ...reordered]
        return newLayouts
      })
    }
  }

  const handleSave = async () => {
    try {
      setSaving(true)
      setMessage(null)
      const token = await onGetAuthToken()
      
      // Transform data to match API format
      const payload = {
        normal: {
          type: "normal",
          homepage: layouts.normal.homepage,
          wallet: layouts.normal.wallet,
          invite: layouts.normal.invite,
        },
        google: {
          type: "google",
          homepage: layouts.google.homepage,
          wallet: layouts.google.wallet,
          invite: layouts.google.invite,
        },
        international: {
          type: "international",
          homepage: layouts.international.homepage,
          wallet: layouts.international.wallet,
          invite: layouts.international.invite,
        },
      }

      // Add timeout to prevent hanging
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 20000) // 20 second timeout

      const response = await fetch("/api/admin/layouts", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      })

      clearTimeout(timeoutId)

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: "Failed to save layouts" }))
        throw new Error(errorData.error || `HTTP ${response.status}`)
      }

      const result = await response.json()
      setMessage({
        type: "success",
        text: result.message || "Layouts saved successfully",
      })
      setTimeout(() => setMessage(null), 3000)
    } catch (error: any) {
      console.error("Error saving layouts:", error)
      if (error.name === 'AbortError') {
        setMessage({ 
          type: "error", 
          text: "Save request timed out. The data might be too large. Please try again or contact support." 
        })
      } else {
        setMessage({ 
          type: "error", 
          text: error.message || "Failed to save layouts. Please try again." 
        })
      }
      setTimeout(() => setMessage(null), 5000)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    )
  }

  const currentPageLayout = layouts[selectedLayout][selectedPage]
  const sortedComponents = [...currentPageLayout].sort((a, b) => a.order - b.order)

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <Card>
        <CardHeader>
          <CardTitle>Layout Management</CardTitle>
          <CardDescription>
            Configure component visibility and ordering for different user layouts and pages.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="layout-type">Select Layout</Label>
              <Select
                value={selectedLayout}
                onValueChange={(value) => setSelectedLayout(value as LayoutType)}
              >
                <SelectTrigger id="layout-type">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="normal">Normal User Layout</SelectItem>
                  <SelectItem value="google">Google Layout</SelectItem>
                  <SelectItem value="international">International Layout</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="page-type">Select Page</Label>
              <Select
                value={selectedPage}
                onValueChange={(value) => setSelectedPage(value as PageType)}
              >
                <SelectTrigger id="page-type">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="homepage">Homepage</SelectItem>
                  <SelectItem value="wallet">Wallet Page</SelectItem>
                <SelectItem value="invite">Invite Page</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <Separator />

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <Label className="text-base">
                {selectedPage === "homepage"
                  ? "Homepage Components"
                  : selectedPage === "wallet"
                    ? "Wallet Page Components"
                    : "Invite Page Components"}
              </Label>
              <p className="text-sm text-muted-foreground">
                {selectedPage === "homepage" 
                  ? "Fixed components shown first • Drag to reorder others • Toggle to enable/disable"
                  : "Toggle to enable/disable"}
              </p>
            </div>

            {selectedPage === "homepage" ? (
              <>
                {/* Fixed components (cannot be dragged) */}
                {sortedComponents
                  .filter((c) => FIXED_HOMEPAGE_COMPONENTS.includes(c.id as ComponentId))
                  .map((component) => (
                    <FixedComponentItem
                      key={component.id}
                      component={component}
                      onToggleEnabled={handleToggleEnabled}
                    />
                  ))}
                
                {/* Draggable components */}
                <DndContext
                  sensors={sensors}
                  collisionDetection={closestCenter}
                  onDragEnd={handleDragEnd}
                >
                  <SortableContext
                    items={sortedComponents
                      .filter((c) => !FIXED_HOMEPAGE_COMPONENTS.includes(c.id as ComponentId))
                      .map((c) => c.id)}
                    strategy={verticalListSortingStrategy}
                  >
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <div className="text-xs text-muted-foreground">
                          Tip: Place <b>Tic Tac Toe</b> and <b>Promotion App 3</b> next to each other to show them in a row in the app.
                        </div>
                        <Button variant="secondary" onClick={handleAddHeading}>
                          Add Heading
                        </Button>
                      </div>
                      {sortedComponents
                        .filter((c) => !FIXED_HOMEPAGE_COMPONENTS.includes(c.id as ComponentId))
                        .map((component) => (
                          <SortableComponentItem
                            key={component.id}
                            component={component}
                            onToggleEnabled={handleToggleEnabled}
                            onUpdateTitle={handleUpdateTitle}
                            onUpdateBadgeText={handleUpdateBadgeText}
                            onUpdateBadgeVariant={handleUpdateBadgeVariant}
                            onUpdateShakeAnimation={handleUpdateShakeAnimation}
                          />
                        ))}
                    </div>
                  </SortableContext>
                </DndContext>
              </>
            ) : (
              <div className="space-y-2">
                {sortedComponents.map((component) => (
                  <WalletComponentItem
                    key={component.id}
                    component={component}
                    onToggleEnabled={handleToggleEnabled}
                  />
                ))}
              </div>
            )}
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
                  Save Layouts
                </>
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
