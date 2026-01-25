"use client"

import { useState, useEffect, type ChangeEvent } from "react"
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
import { Save, Loader2, Plus, X } from "lucide-react"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { StatusMessage } from "@/components/status-message"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

interface AppDataFormProps {
  initialData: any
  onSave: (data: any) => Promise<void>
  saving: boolean
}

interface AppDataFields {
  adjoeHash: string
  chatbot: string
  contactUsMailto: string
  privacyPolicyUrl: string
  currentBuildNumber: number
  indiaCoinCurFactor: number
  foreignCoinCurFactor: number
  howToEarnYoutubeUrl: string
  redeemNotice: string
  followTaskDefaultCoins: number
  followTaskMinBackgroundTime: number
  followTaskInstructions: string
  reviewTaskDefaultCoins: number
  reviewTaskMinBackgroundTime: number
  reviewTaskInstructions: string
  moreAppsDefaultCoins: number
  moreAppsMinBackgroundTime: number
  moreAppsInstructions: string
  rateUsCoins: number
  rateUsCardText: string
  rateUsDialogText: string
  geemeeAppId: string
  geemeeOfferwallPlacementId: string
  maxAccountsPerDevice: number
  normalLayoutEnabled: boolean
  internationalLayoutEnabled: boolean
  forceNormalLayout: boolean
  forceGoogleLayout: boolean
  forceInternationalLayout: boolean
  dailyGameLimit: number
  geemeeOfferwallRewardCoins: number
  forceUserToPlayJackpot: boolean
  mintegralAppId: string
  mintegralAppKey: string
  mintegralInterstitialPlacementId: string
  mintegralInterstitialUnitId: string
  normalUserTrackingParams: string[]
  ipApiBaseUrl: string
  ipApiKey: string
  joiningBonusCoins: number
  referralCoins: number
}

export function AppDataForm({ initialData, onSave, saving }: AppDataFormProps) {
  const [formData, setFormData] = useState<AppDataFields>({
    adjoeHash: "",
    chatbot: "",
    contactUsMailto: "",
    privacyPolicyUrl: "",
    currentBuildNumber: 1,
    indiaCoinCurFactor: 0,
    foreignCoinCurFactor: 0,
    howToEarnYoutubeUrl: "",
    redeemNotice: "",
    followTaskDefaultCoins: 10,
    followTaskMinBackgroundTime: 30,
    followTaskInstructions: "",
    reviewTaskDefaultCoins: 150,
    reviewTaskMinBackgroundTime: 60,
    reviewTaskInstructions: "",
    moreAppsDefaultCoins: 0,
    moreAppsMinBackgroundTime: 120,
    moreAppsInstructions: "",
    rateUsCoins: 50,
    rateUsCardText: "",
    rateUsDialogText: "",
    geemeeAppId: "",
    geemeeOfferwallPlacementId: "",
    maxAccountsPerDevice: 2,
    normalLayoutEnabled: false,
    internationalLayoutEnabled: false,
    forceNormalLayout: false,
    forceGoogleLayout: false,
    forceInternationalLayout: false,
    dailyGameLimit: 10,
    geemeeOfferwallRewardCoins: 10,
    forceUserToPlayJackpot: false,
    mintegralAppId: "",
    mintegralAppKey: "",
    mintegralInterstitialPlacementId: "",
    mintegralInterstitialUnitId: "",
    normalUserTrackingParams: ['gclid', 'fbclid'],
    ipApiBaseUrl: "https://pro.ip-api.com/json/",
    ipApiKey: "CSkfd5JdFbyfF8V",
    joiningBonusCoins: 50,
    referralCoins: 100,
  })
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  useEffect(() => {
    if (initialData) {
      setFormData({
        adjoeHash: initialData.adjoeHash || "",
        chatbot: initialData.chatbot || "",
        contactUsMailto: initialData.contactUsMailto || "",
        privacyPolicyUrl: initialData.privacyPolicyUrl || "",
        currentBuildNumber: initialData.currentBuildNumber || 1,
        indiaCoinCurFactor: Number(initialData.indiaCoinCurFactor ?? 0),
        foreignCoinCurFactor: Number(initialData.foreignCoinCurFactor ?? 0),
        howToEarnYoutubeUrl: initialData.howToEarnYoutubeUrl || "",
        redeemNotice: initialData.redeemNotice || "",
        followTaskDefaultCoins: initialData.followTaskDefaultCoins ?? 10,
        followTaskMinBackgroundTime: initialData.followTaskMinBackgroundTime ?? 30,
        followTaskInstructions: initialData.followTaskInstructions || "",
        reviewTaskDefaultCoins: initialData.reviewTaskDefaultCoins ?? 150,
        reviewTaskMinBackgroundTime: initialData.reviewTaskMinBackgroundTime ?? 60,
        reviewTaskInstructions: initialData.reviewTaskInstructions || "",
        moreAppsDefaultCoins: initialData.moreAppsDefaultCoins ?? 0,
        moreAppsMinBackgroundTime: initialData.moreAppsMinBackgroundTime ?? 120,
        moreAppsInstructions: initialData.moreAppsInstructions || "",
        rateUsCoins: initialData.rateUsCoins ?? 50,
        rateUsCardText: initialData.rateUsCardText || "",
        rateUsDialogText: initialData.rateUsDialogText || "",
        geemeeAppId: initialData.geemeeAppId || "",
        geemeeOfferwallPlacementId: initialData.geemeeOfferwallPlacementId || "",
        maxAccountsPerDevice: initialData.maxAccountsPerDevice || 2,
        normalLayoutEnabled: initialData.normalLayoutEnabled ?? false,
        internationalLayoutEnabled: initialData.internationalLayoutEnabled ?? false,
        forceNormalLayout: initialData.forceNormalLayout ?? false,
        forceGoogleLayout: initialData.forceGoogleLayout ?? false,
        forceInternationalLayout: initialData.forceInternationalLayout ?? false,
        dailyGameLimit: initialData.dailyGameLimit ?? 10,
        geemeeOfferwallRewardCoins: initialData.geemeeOfferwallRewardCoins ?? 10,
        forceUserToPlayJackpot: initialData.forceUserToPlayJackpot ?? false,
        mintegralAppId: initialData.mintegralAppId || "",
        mintegralAppKey: initialData.mintegralAppKey || "",
        mintegralInterstitialPlacementId: initialData.mintegralInterstitialPlacementId || "",
        mintegralInterstitialUnitId: initialData.mintegralInterstitialUnitId || "",
        normalUserTrackingParams: Array.isArray(initialData.normalUserTrackingParams) 
          ? initialData.normalUserTrackingParams 
          : ['gclid', 'fbclid'],
        ipApiBaseUrl: initialData.ipApiBaseUrl || "https://pro.ip-api.com/json/",
        ipApiKey: initialData.ipApiKey || "CSkfd5JdFbyfF8V",
        joiningBonusCoins: initialData.joiningBonusCoins ?? 50,
        referralCoins: initialData.referralCoins ?? 100,
      })
    }
  }, [initialData])

  const handleChange = (field: keyof AppDataFields, value: string | number | boolean | string[]) => {
    setFormData({ ...formData, [field]: value })
  }

  const addTrackingParam = () => {
    setFormData({
      ...formData,
      normalUserTrackingParams: [...formData.normalUserTrackingParams, ''],
    })
  }

  const removeTrackingParam = (index: number) => {
    setFormData({
      ...formData,
      normalUserTrackingParams: formData.normalUserTrackingParams.filter((_, i) => i !== index),
    })
  }

  const updateTrackingParam = (index: number, value: string) => {
    const updated = [...formData.normalUserTrackingParams]
    updated[index] = value.trim().toLowerCase()
    setFormData({
      ...formData,
      normalUserTrackingParams: updated,
    })
  }

  const handleSave = async () => {
    try {
      // Filter out empty tracking parameters before saving
      const dataToSave = {
        ...formData,
        normalUserTrackingParams: formData.normalUserTrackingParams.filter(p => p.trim().length > 0),
      }
      await onSave(dataToSave)
      setMessage({ type: 'success', text: 'App data saved successfully!' })
      setTimeout(() => setMessage(null), 3000)
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to save app data' })
      setTimeout(() => setMessage(null), 3000)
    }
  }

  return (
    <div className="space-y-6">
      <StatusMessage message={message} onDismiss={() => setMessage(null)} />

      <Tabs defaultValue="basics" className="w-full">
        <TabsList className="grid h-auto w-full grid-cols-2 gap-1 bg-muted/60 p-1 md:grid-cols-4">
          <TabsTrigger value="basics">Basics</TabsTrigger>
          <TabsTrigger value="tasks">Tasks</TabsTrigger>
          <TabsTrigger value="integrations">Integrations</TabsTrigger>
          <TabsTrigger value="layouts">Layouts</TabsTrigger>
        </TabsList>

        <TabsContent value="basics" className="mt-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Basics</CardTitle>
              <CardDescription>General configuration used across the app.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="adjoeHash">Adjoe Hash</Label>
                  <Input
                    id="adjoeHash"
                    value={formData.adjoeHash}
                    onChange={(e) => handleChange("adjoeHash", e.target.value)}
                    placeholder="Enter adjoe hash"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="chatbot">Chatbot URL</Label>
                  <Input
                    id="chatbot"
                    type="url"
                    value={formData.chatbot}
                    onChange={(e) => handleChange("chatbot", e.target.value)}
                    placeholder="https://telegram.me/..."
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="contactUsMailto">Contact Us (mailto)</Label>
                  <Input
                    id="contactUsMailto"
                    value={formData.contactUsMailto}
                    onChange={(e) => handleChange("contactUsMailto", e.target.value)}
                    placeholder="mailto:support@example.com (or just support@example.com)"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="privacyPolicyUrl">Privacy Policy URL</Label>
                  <Input
                    id="privacyPolicyUrl"
                    type="url"
                    value={formData.privacyPolicyUrl}
                    onChange={(e) => handleChange("privacyPolicyUrl", e.target.value)}
                    placeholder="https://sites.google.com/view/your-privacy-policy"
                  />
                  <p className="text-xs text-muted-foreground">
                    URL for the privacy policy page. Shown in the Profile page.
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="currentBuildNumber">Current Build Number</Label>
                  <Input
                    id="currentBuildNumber"
                    type="number"
                    value={formData.currentBuildNumber}
                    onChange={(e) =>
                      handleChange("currentBuildNumber", Number(e.target.value))
                    }
                    placeholder="1"
                  />
                </div>

                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="howToEarnYoutubeUrl">How To Earn YouTube URL</Label>
                  <Input
                    id="howToEarnYoutubeUrl"
                    type="url"
                    value={formData.howToEarnYoutubeUrl}
                    onChange={(e) => handleChange("howToEarnYoutubeUrl", e.target.value)}
                    placeholder="https://www.youtube.com/watch?v=..."
                  />
                  <p className="text-xs text-muted-foreground">
                    Optional. If set, the app will show this video at the top of the How To Earn page.
                  </p>
                </div>
              </div>

              <Separator />

              <div className="space-y-2">
                <h3 className="text-base font-semibold">Coin Conversion Rates</h3>
                <p className="text-sm text-muted-foreground">
                  Shown on the Redeem screen as a hint (e.g. “1000 coins = ₹1”).
                </p>
              </div>

              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="indiaCoinCurFactor">India (coins per ₹1)</Label>
                  <Input
                    id="indiaCoinCurFactor"
                    type="number"
                    value={formData.indiaCoinCurFactor}
                    onChange={(e) => {
                      const n = e.currentTarget.valueAsNumber
                      handleChange("indiaCoinCurFactor", Number.isFinite(n) ? n : 0)
                    }}
                    min={0}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="foreignCoinCurFactor">Foreign (coins per $1)</Label>
                  <Input
                    id="foreignCoinCurFactor"
                    type="number"
                    value={formData.foreignCoinCurFactor}
                    onChange={(e) => {
                      const n = e.currentTarget.valueAsNumber
                      handleChange("foreignCoinCurFactor", Number.isFinite(n) ? n : 0)
                    }}
                    min={0}
                  />
                  <p className="text-xs text-muted-foreground">Used for all non-India countries.</p>
                </div>
              </div>

              <Separator />

              <div className="space-y-2">
                <h3 className="text-base font-semibold">User Bonuses</h3>
                <p className="text-sm text-muted-foreground">
                  Coin amounts awarded to users for joining and referrals.
                </p>
              </div>

              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="joiningBonusCoins">Joining Bonus Coins</Label>
                  <Input
                    id="joiningBonusCoins"
                    type="number"
                    value={formData.joiningBonusCoins}
                    onChange={(e) => {
                      const n = e.currentTarget.valueAsNumber
                      handleChange("joiningBonusCoins", Number.isFinite(n) ? n : 0)
                    }}
                    min={0}
                  />
                  <p className="text-xs text-muted-foreground">
                    Coins awarded to new users when they sign up (if not using a referral).
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="referralCoins">Referral Signup Bonus Coins</Label>
                  <Input
                    id="referralCoins"
                    type="number"
                    value={formData.referralCoins}
                    onChange={(e) => {
                      const n = e.currentTarget.valueAsNumber
                      handleChange("referralCoins", Number.isFinite(n) ? n : 0)
                    }}
                    min={0}
                  />
                  <p className="text-xs text-muted-foreground">
                    Coins awarded to new users when they sign up using a referral code.
                  </p>
                </div>
              </div>

              <Separator />

              <div className="space-y-2">
                <h3 className="text-base font-semibold">Redeem Page Notice</h3>
                <p className="text-sm text-muted-foreground">
                  Optional warning/notice message displayed at the top of the Redeem page. Leave empty to hide.
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="redeemNotice">Redeem Notice/Warning</Label>
                <Textarea
                  id="redeemNotice"
                  value={formData.redeemNotice}
                  onChange={(e: ChangeEvent<HTMLTextAreaElement>) =>
                    handleChange("redeemNotice", e.target.value)
                  }
                  placeholder="Example: Please ensure your payment details are correct. Redemptions may take 24-48 hours to process."
                  rows={3}
                />
                <p className="text-xs text-muted-foreground">
                  This message will be displayed prominently on the Redeem page as a warning or notice banner.
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="tasks" className="mt-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Tasks</CardTitle>
              <CardDescription>
                Default rewards, timings, and instructions. Use placeholders like{" "}
                <code>{"{coins}"}</code>, <code>{"{seconds}"}</code>, <code>{"{name}"}</code>.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="followTaskDefaultCoins">Follow Tasks - Default Coins</Label>
                  <Input
                    id="followTaskDefaultCoins"
                    type="number"
                    value={formData.followTaskDefaultCoins}
                    onChange={(e) =>
                      handleChange("followTaskDefaultCoins", Number(e.target.value))
                    }
                    min={0}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="followTaskMinBackgroundTime">
                    Follow Tasks - Default Background Time (sec)
                  </Label>
                  <Input
                    id="followTaskMinBackgroundTime"
                    type="number"
                    value={formData.followTaskMinBackgroundTime}
                    onChange={(e) =>
                      handleChange("followTaskMinBackgroundTime", Number(e.target.value))
                    }
                    min={0}
                  />
                </div>
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="followTaskInstructions">Follow Tasks - Instructions</Label>
                  <Textarea
                    id="followTaskInstructions"
                    value={formData.followTaskInstructions}
                    onChange={(e: ChangeEvent<HTMLTextAreaElement>) =>
                      handleChange("followTaskInstructions", e.target.value)
                    }
                    placeholder={
                      "1. Open {name}\n2. Follow the account\n3. Stay for {seconds} seconds\n4. Come back to claim {coins} coins"
                    }
                    rows={4}
                  />
                </div>

                <Separator className="md:col-span-2" />

                <div className="space-y-2">
                  <Label htmlFor="reviewTaskDefaultCoins">Review Tasks - Default Coins</Label>
                  <Input
                    id="reviewTaskDefaultCoins"
                    type="number"
                    value={formData.reviewTaskDefaultCoins}
                    onChange={(e) =>
                      handleChange("reviewTaskDefaultCoins", Number(e.target.value))
                    }
                    min={0}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="reviewTaskMinBackgroundTime">
                    Review Tasks - Default Background Time (sec)
                  </Label>
                  <Input
                    id="reviewTaskMinBackgroundTime"
                    type="number"
                    value={formData.reviewTaskMinBackgroundTime}
                    onChange={(e) =>
                      handleChange("reviewTaskMinBackgroundTime", Number(e.target.value))
                    }
                    min={0}
                  />
                </div>
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="reviewTaskInstructions">Review Tasks - Instructions</Label>
                  <Textarea
                    id="reviewTaskInstructions"
                    value={formData.reviewTaskInstructions}
                    onChange={(e: ChangeEvent<HTMLTextAreaElement>) =>
                      handleChange("reviewTaskInstructions", e.target.value)
                    }
                    placeholder={
                      "1. Open Play Store\n2. Review {name}\n3. Stay for {seconds} seconds\n4. Come back to claim {coins} coins"
                    }
                    rows={4}
                  />
                </div>

                <Separator className="md:col-span-2" />

                <div className="space-y-2">
                  <Label htmlFor="moreAppsDefaultCoins">
                    More Apps - Default Coins (0 = use per-app)
                  </Label>
                  <Input
                    id="moreAppsDefaultCoins"
                    type="number"
                    value={formData.moreAppsDefaultCoins}
                    onChange={(e) =>
                      handleChange("moreAppsDefaultCoins", Number(e.target.value))
                    }
                    min={0}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="moreAppsMinBackgroundTime">
                    More Apps - Default Background Time (sec)
                  </Label>
                  <Input
                    id="moreAppsMinBackgroundTime"
                    type="number"
                    value={formData.moreAppsMinBackgroundTime}
                    onChange={(e) =>
                      handleChange("moreAppsMinBackgroundTime", Number(e.target.value))
                    }
                    min={0}
                  />
                </div>
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="moreAppsInstructions">More Apps - Instructions</Label>
                  <Textarea
                    id="moreAppsInstructions"
                    value={formData.moreAppsInstructions}
                    onChange={(e: ChangeEvent<HTMLTextAreaElement>) =>
                      handleChange("moreAppsInstructions", e.target.value)
                    }
                    placeholder={
                      "1. Open Play Store\n2. Install {name}\n3. Use for {seconds} seconds\n4. Come back to claim {coins} coins"
                    }
                    rows={4}
                  />
                </div>

                <Separator className="md:col-span-2" />

                <div className="space-y-2">
                  <Label htmlFor="rateUsCoins">Rate Us - Reward Coins</Label>
                  <Input
                    id="rateUsCoins"
                    type="number"
                    value={formData.rateUsCoins}
                    onChange={(e) => handleChange("rateUsCoins", Number(e.target.value))}
                    min={0}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="rateUsCardText">Rate Us - Card Text</Label>
                  <Input
                    id="rateUsCardText"
                    value={formData.rateUsCardText}
                    onChange={(e) => handleChange("rateUsCardText", e.target.value)}
                    placeholder={"Rate us 5 star and get {coins} coins"}
                  />
                </div>
                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="rateUsDialogText">Rate Us - Dialog Text</Label>
                  <Textarea
                    id="rateUsDialogText"
                    value={formData.rateUsDialogText}
                    onChange={(e: ChangeEvent<HTMLTextAreaElement>) =>
                      handleChange("rateUsDialogText", e.target.value)
                    }
                    placeholder={"Rate us on Play Store then come back to claim {coins} coins."}
                    rows={3}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="integrations" className="mt-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Integrations</CardTitle>
              <CardDescription>Provider IDs, SDK keys, and feature toggles.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="geemeeAppId">Geemee App ID</Label>
                  <Input
                    id="geemeeAppId"
                    value={formData.geemeeAppId}
                    onChange={(e) => handleChange("geemeeAppId", e.target.value)}
                    placeholder="Enter geemee app ID"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="geemeeOfferwallPlacementId">Geemee Offerwall Placement ID</Label>
                  <Input
                    id="geemeeOfferwallPlacementId"
                    value={formData.geemeeOfferwallPlacementId}
                    onChange={(e) =>
                      handleChange("geemeeOfferwallPlacementId", e.target.value)
                    }
                    placeholder="Enter geemee offerwall placement ID"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="geemeeOfferwallRewardCoins">Geemee Offerwall Reward Coins</Label>
                  <Input
                    id="geemeeOfferwallRewardCoins"
                    type="number"
                    value={formData.geemeeOfferwallRewardCoins}
                    onChange={(e) => {
                      const n = e.currentTarget.valueAsNumber
                      handleChange("geemeeOfferwallRewardCoins", Number.isFinite(n) && n >= 0 ? n : 0)
                    }}
                    min={0}
                    placeholder="10"
                  />
                  <p className="text-xs text-muted-foreground">
                    Coins awarded to users when they successfully view the Geemee offerwall from the Jackpot card.
                  </p>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      id="forceUserToPlayJackpot"
                      checked={formData.forceUserToPlayJackpot}
                      onChange={(e) => handleChange("forceUserToPlayJackpot", e.target.checked)}
                      className="h-4 w-4 rounded border-gray-300"
                    />
                    <Label htmlFor="forceUserToPlayJackpot" className="cursor-pointer">
                      Force User to Play Jackpot
                    </Label>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    If enabled, users must play the Lucky Jackpot before accessing home components and redeeming coins. A dialog will appear prompting them to play.
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="maxAccountsPerDevice">Max Accounts Per Device</Label>
                  <Input
                    id="maxAccountsPerDevice"
                    type="number"
                    value={formData.maxAccountsPerDevice}
                    onChange={(e) =>
                      handleChange("maxAccountsPerDevice", Number(e.target.value))
                    }
                    placeholder="2"
                    min={1}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="dailyGameLimit">Max Game Limit (Daily)</Label>
                  <Input
                    id="dailyGameLimit"
                    type="number"
                    value={formData.dailyGameLimit}
                    onChange={(e) => {
                      const n = e.currentTarget.valueAsNumber
                      handleChange("dailyGameLimit", Number.isFinite(n) && n > 0 ? n : 1)
                    }}
                    min={1}
                    placeholder="10"
                  />
                  <p className="text-xs text-muted-foreground">
                    Maximum number of games a user can play per day. Users will be blocked from playing when they reach this limit.
                  </p>
                </div>

                <Separator className="md:col-span-2" />

                <div className="space-y-2">
                  <Label htmlFor="mintegralAppId">Mintegral App ID</Label>
                  <Input
                    id="mintegralAppId"
                    value={formData.mintegralAppId}
                    onChange={(e) => handleChange("mintegralAppId", e.target.value)}
                    placeholder="Enter Mintegral app ID"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="mintegralAppKey">Mintegral App Key</Label>
                  <Input
                    id="mintegralAppKey"
                    value={formData.mintegralAppKey}
                    onChange={(e) => handleChange("mintegralAppKey", e.target.value)}
                    placeholder="Enter Mintegral app key"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="mintegralInterstitialPlacementId">Mintegral Interstitial Placement ID</Label>
                  <Input
                    id="mintegralInterstitialPlacementId"
                    value={formData.mintegralInterstitialPlacementId}
                    onChange={(e) => handleChange("mintegralInterstitialPlacementId", e.target.value)}
                    placeholder="Enter Mintegral interstitial placement ID"
                  />
                  <p className="text-xs text-muted-foreground">
                    Used for interstitial ads in games (Claim Coins, Retry)
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="mintegralInterstitialUnitId">Mintegral Interstitial Unit ID</Label>
                  <Input
                    id="mintegralInterstitialUnitId"
                    value={formData.mintegralInterstitialUnitId}
                    onChange={(e) => handleChange("mintegralInterstitialUnitId", e.target.value)}
                    placeholder="Enter Mintegral interstitial unit ID"
                  />
                  <p className="text-xs text-muted-foreground">
                    Unit ID for interstitial ads in games
                  </p>
                </div>

                <Separator className="md:col-span-2" />

                <div className="space-y-2">
                  <Label htmlFor="ipApiBaseUrl">IP API Base URL</Label>
                  <Input
                    id="ipApiBaseUrl"
                    value={formData.ipApiBaseUrl}
                    onChange={(e) => handleChange("ipApiBaseUrl", e.target.value)}
                    placeholder="https://pro.ip-api.com/json/"
                  />
                  <p className="text-xs text-muted-foreground">
                    Base URL for IP geolocation API. The IP address will be appended automatically. Example: https://pro.ip-api.com/json/
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="ipApiKey">IP API Key</Label>
                  <Input
                    id="ipApiKey"
                    value={formData.ipApiKey}
                    onChange={(e) => handleChange("ipApiKey", e.target.value)}
                    placeholder="CSkfd5JdFbyfF8V"
                  />
                  <p className="text-xs text-muted-foreground">
                    API key for IP geolocation service. Used in the format: {"{baseUrl}/{ip}?key={apiKey}"}
                  </p>
                </div>

                <Separator className="md:col-span-2" />

                <div className="space-y-2 md:col-span-2">
                  <Label>Normal User Tracking Parameters</Label>
                  <p className="text-xs text-muted-foreground">
                    Parameters from Play Install Referrer that mark users as normal users. 
                    If any of these parameters are found in the install referrer URL, the user will be marked as a normal user and local rules won't apply.
                  </p>
                  <div className="space-y-2">
                    {formData.normalUserTrackingParams.map((param, index) => (
                      <div key={index} className="flex gap-2 items-center">
                        <Input
                          value={param}
                          onChange={(e) => updateTrackingParam(index, e.target.value)}
                          placeholder="e.g., gclid, fbclid, utm_source"
                          className="flex-1"
                        />
                        <Button
                          type="button"
                          variant="outline"
                          size="icon"
                          onClick={() => removeTrackingParam(index)}
                          disabled={formData.normalUserTrackingParams.length <= 1}
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    ))}
                    <Button
                      type="button"
                      variant="outline"
                      onClick={addTrackingParam}
                      className="w-full"
                    >
                      <Plus className="mr-2 h-4 w-4" />
                      Add Parameter
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground mt-2">
                    Default parameters: gclid, fbclid. Add more parameters as needed (e.g., utm_source, campaign_id).
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="layouts" className="mt-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Layouts</CardTitle>
              <CardDescription>
                Enable optional layouts and force a layout for all users.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div className="space-y-2">
                  <h3 className="text-base font-semibold">Layout Flags</h3>
                  <p className="text-sm text-muted-foreground">
                    Google layout is used by default. These flags enable alternative layouts for
                    specific conditions.
                  </p>
                </div>

                <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                  <div className="flex items-center justify-between space-x-2 rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <Label htmlFor="normalLayoutEnabled" className="text-base">
                        Normal Layout
                      </Label>
                      <p className="text-xs text-muted-foreground">
                        Enable normal layout (can be used with conditions)
                      </p>
                    </div>
                    <Switch
                      id="normalLayoutEnabled"
                      checked={formData.normalLayoutEnabled}
                      onCheckedChange={(checked) => handleChange("normalLayoutEnabled", checked)}
                    />
                  </div>

                  <div className="flex items-center justify-between space-x-2 rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <Label htmlFor="internationalLayoutEnabled" className="text-base">
                        International Layout
                      </Label>
                      <p className="text-xs text-muted-foreground">
                        Enable international layout (can be used with conditions)
                      </p>
                    </div>
                    <Switch
                      id="internationalLayoutEnabled"
                      checked={formData.internationalLayoutEnabled}
                      onCheckedChange={(checked) =>
                        handleChange("internationalLayoutEnabled", checked)
                      }
                    />
                  </div>
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <div className="space-y-2">
                  <h3 className="text-base font-semibold">Force Layout</h3>
                  <p className="text-sm text-muted-foreground">
                    When enabled, this bypasses all detection logic (emulator, VPN, country, UPI
                    apps) and applies the selected layout to everyone.
                  </p>
                </div>

                <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
                  <div className="flex items-center justify-between space-x-2 rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <Label htmlFor="forceNormalLayout" className="text-base">
                        Force Normal
                      </Label>
                      <p className="text-xs text-muted-foreground">Force normal layout for all users</p>
                    </div>
                    <Switch
                      id="forceNormalLayout"
                      checked={formData.forceNormalLayout}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          handleChange("forceGoogleLayout", false)
                          handleChange("forceInternationalLayout", false)
                        }
                        handleChange("forceNormalLayout", checked)
                      }}
                    />
                  </div>

                  <div className="flex items-center justify-between space-x-2 rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <Label htmlFor="forceGoogleLayout" className="text-base">
                        Force Google
                      </Label>
                      <p className="text-xs text-muted-foreground">Force google layout for all users</p>
                    </div>
                    <Switch
                      id="forceGoogleLayout"
                      checked={formData.forceGoogleLayout}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          handleChange("forceNormalLayout", false)
                          handleChange("forceInternationalLayout", false)
                        }
                        handleChange("forceGoogleLayout", checked)
                      }}
                    />
                  </div>

                  <div className="flex items-center justify-between space-x-2 rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <Label htmlFor="forceInternationalLayout" className="text-base">
                        Force International
                      </Label>
                      <p className="text-xs text-muted-foreground">
                        Force international layout for all users
                      </p>
                    </div>
                    <Switch
                      id="forceInternationalLayout"
                      checked={formData.forceInternationalLayout}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          handleChange("forceNormalLayout", false)
                          handleChange("forceGoogleLayout", false)
                        }
                        handleChange("forceInternationalLayout", checked)
                      }}
                    />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

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
              Save App Data
            </>
          )}
        </Button>
      </div>
    </div>
  )
}
