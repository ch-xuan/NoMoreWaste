'use client'

import { useState, useEffect } from 'react'
import { Bell, CheckCircle2, AlertCircle, Info, Trash2, Check, Truck, Clock, FileText, Package } from 'lucide-react'
import Link from 'next/link'

interface Notification {
    id: string
    recipientId: string
    senderId: string
    type: string
    title: string
    message: string
    entityId: string | null
    linkTo?: string
    isRead: boolean
    createdAt: string
}

export default function NotificationsPage() {
    // ... (rest of the component remains the same until NotificationCard)
    const [notifications, setNotifications] = useState<Notification[]>([])
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        // Initial fetch
        fetchNotifications()

        // Trigger check for expiring donations (lazy cron)
        fetch('/api/notifications/check-expiring', { method: 'POST' }).catch(console.error)

        // Poll every 3 seconds to provide near real-time updates
        const interval = setInterval(fetchNotifications, 3000)
        return () => clearInterval(interval)
    }, [])

    const fetchNotifications = async () => {
        try {
            const response = await fetch('/api/notifications/list')
            const data = await response.json()
            if (data.success) {
                setNotifications(data.notifications)
            }
        } catch (error) {
            console.error('Failed to fetch notifications:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const markAsRead = async (id: string) => {
        try {
            const response = await fetch('/api/notifications/mark-read', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ notificationIds: [id] }),
            })

            if (response.ok) {
                setNotifications(notifications.map(n =>
                    n.id === id ? { ...n, isRead: true } : n
                ))
            }
        } catch (error) {
            console.error('Failed to mark as read:', error)
        }
    }

    const markAllAsRead = async () => {
        // Filter out pending user notifications which cannot be marked as read via API
        const unreadIds = notifications
            .filter(n => !n.isRead && !n.id.startsWith('pending_user_'))
            .map(n => n.id)

        if (unreadIds.length === 0) return

        try {
            const response = await fetch('/api/notifications/mark-read', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ notificationIds: unreadIds }),
            })

            if (response.ok) {
                setNotifications(notifications.map(n =>
                    // Optimistically update all, even pending ones, locally
                    ({ ...n, isRead: true })
                ))
            }
        } catch (error) {
            console.error('Failed to mark all as read:', error)
        }
    }

    const deleteNotification = (id: string) => {
        setNotifications(notifications.filter(n => n.id !== id))
    }

    const unreadCount = notifications.filter(n => !n.isRead).length

    // Helper to get relative time
    const getRelativeTime = (timestamp: string) => {
        const now = new Date()
        const past = new Date(timestamp)
        const diffMs = now.getTime() - past.getTime()
        const diffMins = Math.floor(diffMs / 60000)
        const diffHours = Math.floor(diffMs / 3600000)
        const diffDays = Math.floor(diffMs / 86400000)

        if (diffMins < 1) return 'Just now'
        if (diffMins < 60) return `${diffMins} min ago`
        if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`
        return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`
    }

    if (isLoading) {
        return (
            <div className="flex h-64 items-center justify-center">
                <div className="text-center">
                    <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent mx-auto" />
                    <p className="mt-4 text-sm text-muted-foreground">Loading notifications...</p>
                </div>
            </div>
        )
    }

    return (
        <div className="mx-auto max-w-4xl space-y-6">
            {/* Page Title */}
            <div className="flex items-center justify-between">
                <div className="space-y-1">
                    <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Notifications</h1>
                    <p className="text-sm text-muted-foreground sm:text-base">
                        Stay updated with your platform activities
                    </p>
                </div>
                {unreadCount > 0 && (
                    <button
                        onClick={markAllAsRead}
                        className="text-sm text-primary hover:underline"
                    >
                        Mark all as read
                    </button>
                )}
            </div>

            {/* Stats */}
            <div className="grid gap-4 sm:grid-cols-2">
                <div className="rounded-lg border bg-card p-4">
                    <p className="text-sm font-medium text-muted-foreground">Total Notifications</p>
                    <p className="mt-2 text-3xl font-bold">{notifications.length}</p>
                </div>
                <div className="rounded-lg border bg-card p-4">
                    <p className="text-sm font-medium text-muted-foreground">Unread</p>
                    <p className="mt-2 text-3xl font-bold">{unreadCount}</p>
                </div>
            </div>

            {/* Notifications List */}
            <div className="space-y-3">
                {notifications.length === 0 ? (
                    <div className="rounded-lg border bg-card p-12 text-center">
                        <Bell className="mx-auto h-12 w-12 text-muted-foreground" />
                        <p className="mt-4 text-sm text-muted-foreground">No notifications</p>
                    </div>
                ) : (
                    notifications.map((notification) => (
                        <NotificationCard
                            key={notification.id}
                            notification={notification}
                            relativeTime={getRelativeTime(notification.createdAt)}
                            onMarkAsRead={markAsRead}
                            onDelete={deleteNotification}
                        />
                    ))
                )}
            </div>
        </div>
    )
}

function NotificationCard({
    notification,
    relativeTime,
    onMarkAsRead,
    onDelete,
}: {
    notification: Notification
    relativeTime: string
    onMarkAsRead: (id: string) => void
    onDelete: (id: string) => void
}) {
    // Map notification types to display config
    const getTypeConfig = (type: string) => {
        const configs: Record<string, { icon: any; color: string; bg: string }> = {
            // User Verification
            accountVerified: { icon: CheckCircle2, color: 'text-green-600', bg: 'bg-green-100' },
            accountRejected: { icon: AlertCircle, color: 'text-red-600', bg: 'bg-red-100' },
            accountPending: { icon: AlertCircle, color: 'text-yellow-600', bg: 'bg-yellow-100' },

            // Logistics
            pickup_complete: { icon: Package, color: 'text-green-600', bg: 'bg-green-100' },
            pickup_completed: { icon: Package, color: 'text-green-600', bg: 'bg-green-100' },
            delivery_complete: { icon: Truck, color: 'text-blue-600', bg: 'bg-blue-100' },
            delivery_completed: { icon: Truck, color: 'text-blue-600', bg: 'bg-blue-100' },
            in_transit: { icon: Truck, color: 'text-blue-600', bg: 'bg-blue-100' },

            // Inventory
            expiring_soon: { icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-100' },
            stock_low: { icon: AlertCircle, color: 'text-red-600', bg: 'bg-red-100' },

            // Reports / System
            new_report: { icon: FileText, color: 'text-purple-600', bg: 'bg-purple-100' },
            report_available: { icon: FileText, color: 'text-purple-600', bg: 'bg-purple-100' },

            // Default
            info: { icon: Info, color: 'text-blue-600', bg: 'bg-blue-100' },
        }
        return configs[type] || configs[type.toLowerCase()] || configs.info
    }

    const config = getTypeConfig(notification.type)
    const Icon = config.icon

    // Check if this is a pending user verification (synthetic)
    const isPendingUser = notification.id.startsWith('pending_user_') || notification.type === 'accountPending'

    const Wrapper = ({ children }: { children: React.ReactNode }) => {
        if (notification.linkTo) {
            return (
                <Link href={notification.linkTo} className="block">
                    {children}
                </Link>
            )
        }
        return <>{children}</>
    }

    return (
        <div
            className={`group rounded-lg border bg-card p-4 transition-colors hover:bg-muted ${!notification.isRead ? 'border-primary/50 bg-primary/5' : ''
                }`}
        >
            <Wrapper>
                <div className="flex items-start gap-4">
                    {/* Icon */}
                    <div className={`shrink-0 rounded-full p-2 ${config.bg}`}>
                        <Icon className={`h-5 w-5 ${config.color}`} />
                    </div>

                    {/* Content */}
                    <div className="flex-1 space-y-1">
                        <div className="flex items-start justify-between gap-2">
                            <h3 className="font-semibold">{notification.title}</h3>
                            {!notification.isRead && (
                                <div className="h-2 w-2 shrink-0 rounded-full bg-primary" />
                            )}
                        </div>
                        <p className="text-sm text-muted-foreground">{notification.message}</p>
                        <p className="text-xs text-muted-foreground">{relativeTime}</p>
                    </div>

                    {/* Actions. Stop propagation to prevent Link click */}
                    <div
                        className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {!notification.isRead && !isPendingUser && (
                            <button
                                onClick={(e) => {
                                    e.preventDefault()
                                    onMarkAsRead(notification.id)
                                }}
                                className="rounded-md p-2 hover:bg-background"
                                title="Mark as read"
                            >
                                <Check className="h-4 w-4" />
                            </button>
                        )}
                        <button
                            onClick={(e) => {
                                e.preventDefault()
                                onDelete(notification.id) // Local hide
                            }}
                            className="rounded-md p-2 text-destructive hover:bg-destructive/10"
                            title="Delete"
                        >
                            <Trash2 className="h-4 w-4" />
                        </button>
                    </div>
                </div>
            </Wrapper>
        </div>
    )
}
