'use client'


import { UserPlus, FileText, User2, Settings, Package, Users, BarChart3, Shield } from 'lucide-react'
import { useRouter } from 'next/navigation'

export default function DashboardPage() {
    const router = useRouter()
    const quickActions = [
        {
            name: 'Review Verifications',
            description: 'Review pending users',
            icon: Shield,
            href: '/verify',
            color: 'bg-green-500',
        },
        {
            name: 'Monitor Donations',
            description: 'Monitor active donations',
            icon: Package,
            href: '/donations',
            color: 'bg-orange-500',
        },
        {
            name: 'Generate Report',
            description: 'Generate analytics',
            icon: BarChart3,
            href: '/reports',
            color: 'bg-purple-500',
        },
        {
            name: 'View Profile',
            description: 'Manage your account',
            icon: User2,
            href: '/profile',
            color: 'bg-blue-500',
        },
    ]

    return (
        <div className="flex flex-col gap-6">
            {/* Page Title */}
            <div className="space-y-1">
                <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Dashboard</h1>
                <p className="text-sm text-muted-foreground sm:text-base">
                    Welcome back! Here&apos;s an overview of your food redistribution platform.
                </p>
            </div>

            {/* Quick Actions */}
            <div>
                <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                    {quickActions.map((action) => (
                        <button
                            key={action.name}
                            onClick={() => router.push(action.href)}
                            className="group relative overflow-hidden rounded-lg border bg-card p-6 shadow-sm transition-all hover:shadow-md hover:border-primary text-left w-full"
                        >
                            <div className="flex flex-col gap-3">
                                <div className={`inline-flex h-12 w-12 items-center justify-center rounded-lg ${action.color} text-white`}>
                                    <action.icon className="h-6 w-6" />
                                </div>
                                <div>
                                    <h3 className="font-semibold group-hover:text-primary transition-colors">
                                        {action.name}
                                    </h3>
                                    <p className="text-sm text-muted-foreground mt-1">
                                        {action.description}
                                    </p>
                                </div>
                            </div>
                        </button>
                    ))}
                </div>
            </div>

            {/* Stats Overview */}
            <div>
                <h2 className="text-lg font-semibold mb-4">Platform Overview</h2>
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    <StatCard
                        title="Total Users"
                        value="1,284"
                        change="+12%"
                        positive
                    />
                    <StatCard
                        title="Active Donations"
                        value="47"
                        change="+8%"
                        positive
                    />
                    <StatCard
                        title="Pending Verifications"
                        value="7"
                        change="-3%"
                        positive={false}
                    />
                    <StatCard
                        title="Food Distributed"
                        value="2,450 kg"
                        change="+23%"
                        positive
                    />
                </div>
            </div>

            {/* Recent Activity placeholder */}
            <div>
                <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
                <div className="rounded-lg border bg-card p-8 text-center">
                    <p className="text-muted-foreground">Recent activity will appear here</p>
                </div>
            </div>
        </div>
    )
}

function StatCard({ title, value, change, positive }: { title: string; value: string; change: string; positive: boolean }) {
    return (
        <div className="rounded-lg border bg-card p-6 shadow-sm">
            <p className="text-sm font-medium text-muted-foreground">{title}</p>
            <div className="mt-2 flex items-baseline gap-2">
                <p className="text-2xl font-bold">{value}</p>
                <span className={`text-xs font-medium ${positive ? 'text-green-600' : 'text-red-600'}`}>
                    {change}
                </span>
            </div>
        </div>
    )
}
