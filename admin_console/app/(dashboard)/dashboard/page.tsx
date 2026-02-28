'use client'

import { AlertCircle, Package, Truck, Users } from 'lucide-react'
import { StatsCard } from '@/components/dashboard/stats-card'
import { useState, useEffect } from 'react'

export default function DashboardPage() {
    const [activities, setActivities] = useState<any[]>([])
    const [isLoading, setIsLoading] = useState(true)

    // Mock stats - keeping these as requested focus was on Recent Activity
    const stats = {
        foodSaved: {
            value: '2,487',
            unit: 'kg',
            trend: { value: 12.5, isPositive: true },
        },
        activePickups: {
            value: 23,
            trend: { value: 8.2, isPositive: true },
        },
        pendingVerifications: {
            value: 7,
            trend: { value: 15.0, isPositive: false },
        },
        totalUsers: {
            value: 142,
            trend: { value: 5.3, isPositive: true },
        },
    }

    useEffect(() => {
        const fetchActivities = async () => {
            try {
                const response = await fetch('/api/admin/audit-logs/list')
                const data = await response.json()
                if (data.success) {
                    setActivities(data.logs)
                }
            } catch (error) {
                console.error('Failed to fetch activities:', error)
            } finally {
                setIsLoading(false)
            }
        }

        fetchActivities()
    }, [])

    const getRelativeTime = (timestamp: string) => {
        const now = new Date()
        const past = new Date(timestamp)
        const diffMs = now.getTime() - past.getTime()
        const diffMins = Math.floor(diffMs / 60000)
        const diffHours = Math.floor(diffMs / 3600000)

        if (diffMins < 1) return 'Just now'
        if (diffMins < 60) return `${diffMins} mins ago`
        if (diffHours < 24) return `${diffHours} hours ago`
        return past.toLocaleDateString()
    }

    return (
        <div className="space-y-8">
            {/* Page Header */}
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
                <p className="text-muted-foreground">
                    Welcome back! Here's an overview of your food redistribution platform.
                </p>
            </div>

            {/* Stats Grid */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard
                    title="Total Food Saved"
                    value={`${stats.foodSaved.value} ${stats.foodSaved.unit}`}
                    icon={Package}
                    trend={stats.foodSaved.trend}
                    description="This month"
                />
                <StatsCard
                    title="Active Pickups"
                    value={stats.activePickups.value}
                    icon={Truck}
                    trend={stats.activePickups.trend}
                    description="In progress"
                />
                <StatsCard
                    title="Pending Verifications"
                    value={stats.pendingVerifications.value}
                    icon={AlertCircle}
                    trend={stats.pendingVerifications.trend}
                    description="Requires action"
                />
                <StatsCard
                    title="Total Users"
                    value={stats.totalUsers.value}
                    icon={Users}
                    trend={stats.totalUsers.trend}
                    description="Donors + NGOs"
                />
            </div>

            {/* Quick Actions / Recent Activity Section */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
                {/* Recent Activity */}
                <div className="col-span-4 rounded-lg border bg-card p-6">
                    <h3 className="mb-4 text-lg font-semibold">Recent Activity</h3>
                    <div className="space-y-4">
                        {isLoading ? (
                            <div className="p-4 text-center text-sm text-muted-foreground">Loading activity...</div>
                        ) : activities.length === 0 ? (
                            <div className="p-4 text-center text-sm text-muted-foreground">No recent activity</div>
                        ) : (
                            activities.slice(0, 3).map((activity) => (
                                <ActivityItem
                                    key={activity.id}
                                    type={activity.category}
                                    title={activity.action}
                                    description={activity.details}
                                    time={getRelativeTime(activity.timestamp)}
                                />
                            ))
                        )}
                    </div>
                </div>

                {/* Quick Actions */}
                <div className="col-span-3 rounded-lg border bg-card p-6">
                    <h3 className="mb-4 text-lg font-semibold">Quick Actions</h3>
                    <div className="space-y-2">
                        <QuickActionButton href="/verify" label="Review Verifications" badge={7} />
                        <QuickActionButton href="/donations" label="Monitor Donations" />
                        <QuickActionButton href="/reports" label="Generate Report" />
                    </div>
                </div>
            </div>
        </div>
    )
}

// Helper Components
function ActivityItem({
    type,
    title,
    description,
    time,
}: {
    type: string
    title: string
    description: string
    time: string
}) {
    // Map categories to colors
    const colors: Record<string, string> = {
        Verification: 'bg-yellow-100 text-yellow-700',
        Logistics: 'bg-green-100 text-green-700',
        User: 'bg-blue-100 text-blue-700',
        System: 'bg-gray-100 text-gray-700',
        Moderation: 'bg-red-100 text-red-700',
    }

    const colorClass = colors[type] || colors.System

    return (
        <div className="flex items-start gap-4 border-b pb-4 last:border-0 last:pb-0">
            <div className={`mt-1 h-2 w-2 rounded-full ${colorClass}`} />
            <div className="flex-1 space-y-1">
                <p className="text-sm font-medium">{title}</p>
                <p className="text-xs text-muted-foreground">{description}</p>
                <p className="text-xs text-muted-foreground">{time}</p>
            </div>
        </div>
    )
}

function QuickActionButton({ href, label, badge }: { href: string; label: string; badge?: number }) {
    return (
        <a
            href={href}
            className="flex items-center justify-between rounded-md border p-3 text-sm font-medium transition-colors hover:bg-muted"
        >
            <span>{label}</span>
            {badge && (
                <span className="flex h-6 w-6 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                    {badge}
                </span>
            )}
        </a>
    )
}
