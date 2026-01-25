"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Label } from "@/components/ui/label"
import { Loader2, TrendingUp, Users, DollarSign, Gift, Calendar } from "lucide-react"
import { Skeleton } from "@/components/ui/skeleton"

interface StatsViewProps {
  onGetAuthToken: () => Promise<string>
}

interface DateStats {
  date: any
  payoutByProvider: Record<string, number>
  rewardByProvider: Record<string, number>
  totalPayout: number
  totalReferrerReward: number
  totalReward: number
  uploadTimestamp: any
  usersJoined: number
}

interface MonthData {
  [date: string]: DateStats
}

interface YearData {
  [month: string]: MonthData
}

export function StatsView({ onGetAuthToken }: StatsViewProps) {
  const [loading, setLoading] = useState(true)
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear().toString())
  const [selectedMonth, setSelectedMonth] = useState<string>("all")
  const [statsData, setStatsData] = useState<YearData>({})
  const [availableYears, setAvailableYears] = useState<string[]>([])
  const [availableMonths, setAvailableMonths] = useState<string[]>([])

  useEffect(() => {
    fetchStats()
  }, [selectedYear, selectedMonth])

  const fetchStats = async () => {
    setLoading(true)
    try {
      const token = await onGetAuthToken()
      const url = `/api/admin/app-stats?year=${selectedYear}${selectedMonth && selectedMonth !== 'all' ? `&month=${selectedMonth}` : ''}`
      const response = await fetch(url, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        const data = await response.json()
        if (data.months) {
          setStatsData({ [selectedYear]: data.months })
          setAvailableMonths(Object.keys(data.months))
        } else if (data.dates) {
          setStatsData({ [selectedYear]: { [selectedMonth]: data.dates } })
        }
      }
    } catch (error) {
      console.error('Error fetching stats:', error)
    } finally {
      setLoading(false)
    }
  }

  const getMonthName = (month: string) => {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ]
    const monthNum = parseInt(month) - 1
    return months[monthNum] || month
  }

  const formatDate = (timestamp: any) => {
    if (!timestamp) return "N/A"
    if (timestamp.toDate) {
      return timestamp.toDate().toLocaleDateString()
    }
    return new Date(timestamp).toLocaleDateString()
  }

  const calculateTotals = () => {
    let totalPayout = 0
    let totalReward = 0
    let totalReferrerReward = 0
    let totalUsers = 0
    const payoutByProvider: Record<string, number> = {}
    const rewardByProvider: Record<string, number> = {}

    Object.values(statsData[selectedYear] || {}).forEach((monthData) => {
      Object.values(monthData).forEach((dateData) => {
        totalPayout += dateData.totalPayout || 0
        totalReward += dateData.totalReward || 0
        totalReferrerReward += dateData.totalReferrerReward || 0
        totalUsers += dateData.usersJoined || 0

        Object.entries(dateData.payoutByProvider || {}).forEach(([provider, amount]) => {
          payoutByProvider[provider] = (payoutByProvider[provider] || 0) + (amount as number)
        })

        Object.entries(dateData.rewardByProvider || {}).forEach(([provider, amount]) => {
          rewardByProvider[provider] = (rewardByProvider[provider] || 0) + (amount as number)
        })
      })
    })

    return {
      totalPayout,
      totalReward,
      totalReferrerReward,
      totalUsers,
      payoutByProvider,
      rewardByProvider,
    }
  }

  const totals = calculateTotals()

  if (loading) {
    return (
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <Skeleton className="h-5 w-28" />
            <Skeleton className="h-4 w-72" />
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Skeleton className="h-4 w-12" />
                <Skeleton className="h-10 w-full" />
              </div>
              <div className="space-y-2">
                <Skeleton className="h-4 w-16" />
                <Skeleton className="h-10 w-full" />
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <Skeleton className="h-4 w-24" />
                <Skeleton className="mt-3 h-8 w-32" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    )
  }

  const hasAnyData =
    Object.keys(statsData[selectedYear] || {}).length > 0 &&
    Object.values(statsData[selectedYear] || {}).some((m) => Object.keys(m || {}).length > 0)

  return (
    <div className="space-y-6">
      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle>Filters</CardTitle>
          <CardDescription>Select year and month to view statistics</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="year-select">Year</Label>
              <Select
                value={selectedYear}
                onValueChange={(value) => {
                  setSelectedYear(value)
                  setSelectedMonth("all")
                }}
              >
                <SelectTrigger id="year-select">
                  <SelectValue placeholder="Select year" />
                </SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 5 }, (_, i) => {
                    const year = new Date().getFullYear() - i
                    return (
                      <SelectItem key={year} value={year.toString()}>
                        {year}
                      </SelectItem>
                    )
                  })}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="month-select">Month</Label>
              <Select
                value={selectedMonth}
                onValueChange={(value) => setSelectedMonth(value)}
              >
                <SelectTrigger id="month-select">
                  <SelectValue placeholder="Select month" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Months</SelectItem>
                  {availableMonths.map((month) => (
                    <SelectItem key={month} value={month}>
                      {getMonthName(month)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {!hasAnyData && (
        <Card>
          <CardContent className="py-10 text-center">
            <p className="text-sm font-medium">No stats available</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Try a different year or month.
            </p>
          </CardContent>
        </Card>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Payout</p>
                <p className="text-3xl font-bold mt-2">{totals.totalPayout.toLocaleString()}</p>
              </div>
              <DollarSign className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Reward</p>
                <p className="text-3xl font-bold mt-2">{totals.totalReward.toLocaleString()}</p>
              </div>
              <Gift className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Referrer Reward</p>
                <p className="text-3xl font-bold mt-2">{totals.totalReferrerReward.toLocaleString()}</p>
              </div>
              <TrendingUp className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Users Joined</p>
                <p className="text-3xl font-bold mt-2">{totals.totalUsers.toLocaleString()}</p>
              </div>
              <Users className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Provider Breakdown */}
      {(Object.keys(totals.payoutByProvider).length > 0 || Object.keys(totals.rewardByProvider).length > 0) && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {Object.keys(totals.payoutByProvider).length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Payout by Provider</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {Object.entries(totals.payoutByProvider).map(([provider, amount]) => (
                    <div
                      key={provider}
                      className="flex items-center justify-between rounded-lg border bg-muted/40 px-3 py-2"
                    >
                      <span className="font-medium">{provider}</span>
                      <span className="text-lg font-bold">{amount.toLocaleString()}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
          {Object.keys(totals.rewardByProvider).length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Reward by Provider</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {Object.entries(totals.rewardByProvider).map(([provider, amount]) => (
                    <div
                      key={provider}
                      className="flex items-center justify-between rounded-lg border bg-muted/40 px-3 py-2"
                    >
                      <span className="font-medium">{provider}</span>
                      <span className="text-lg font-bold">{amount.toLocaleString()}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {/* Daily Breakdown */}
      {selectedMonth && selectedMonth !== 'all' && statsData[selectedYear]?.[selectedMonth] && (
        <Card>
          <CardHeader>
            <CardTitle>Daily Breakdown - {getMonthName(selectedMonth)} {selectedYear}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {Object.entries(statsData[selectedYear][selectedMonth])
                .sort(([a], [b]) => b.localeCompare(a))
                .map(([date, data]) => (
                  <Card key={date}>
                    <CardContent className="pt-6">
                      <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center gap-2">
                          <Calendar className="h-5 w-5 text-muted-foreground" />
                          <span className="font-semibold">{date}</span>
                        </div>
                        <span className="text-sm text-muted-foreground">
                          {formatDate(data.uploadTimestamp)}
                        </span>
                      </div>
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <div>
                          <p className="text-sm text-muted-foreground">Payout</p>
                          <p className="text-xl font-bold">{data.totalPayout.toLocaleString()}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Reward</p>
                          <p className="text-xl font-bold">{data.totalReward.toLocaleString()}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Referrer</p>
                          <p className="text-xl font-bold">{data.totalReferrerReward.toLocaleString()}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Users</p>
                          <p className="text-xl font-bold">{data.usersJoined.toLocaleString()}</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

