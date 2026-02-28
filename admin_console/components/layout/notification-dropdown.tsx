'use client'

import { useState, useEffect } from 'react'
import { Bell } from 'lucide-react'
import { cn } from '@/lib/utils'
import Link from 'next/link'

interface Notification {
    id: string
    recipientId: string
    senderId: string
    type: string
    title: string
    message: string
    entityId: string | null
    isRead: boolean
    createdAt: string
}

export function NotificationDropdown() {
    const [isOpen, setIsOpen] = useState(false)
    const [notifications, setNotifications] = useState<Notification[]>([])
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        fetchNotifications()
        // Poll for notifications every 30 seconds
        const interval = setInterval(fetchNotifications, 30000)
        return () => clearInterval(interval)
    }, [])

    const fetchNotifications = async () => {
        try {
            const response = await fetch('/api/notifications/list')
            const data = await response.json()
            if (data.success) {
                // Get only the 5 most recent notifications
                setNotifications(data.notifications.slice(0, 5))
            }
        } catch (error) {
            console.error('Failed to fetch notifications:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const markAllAsRead = async () => {
        const unreadIds = notifications.filter(n => !n.isRead).map(n => n.id)
        if (unreadIds.length === 0) return

        try {
            const response = await fetch('/api/notifications/mark-read', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ notificationIds: unreadIds }),
            })

            if (response.ok) {
                setNotifications(notifications.map(n => ({ ...n, isRead: true })))
            }
        } catch (error) {
            console.error('Failed to mark as read:', error)
        }
    }

    const unreadCount = notifications.filter((n) => !n.isRead).length

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

    return (
        <div className="relative">
            <button
                type="button"
                onClick={() => setIsOpen(!isOpen)}
                className="relative rounded-full p-2 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                aria-label="View notifications"
            >
                <Bell className="h-5 w-5" />
                {unreadCount > 0 && (
                    <span className="absolute right-1 top-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white animate-pulse">
                        {unreadCount}
                    </span>
                )}
            </button>

            {/* Dropdown */}
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <div
                        className="fixed inset-0 z-40"
                        onClick={() => setIsOpen(false)}
                    />

                    {/* Notification Panel */}
                    <div className="absolute right-0 z-50 mt-2 w-80 animate-in slide-in-from-top-2 rounded-lg border bg-card shadow-lg">
                        {/* Header */}
                        <div className="flex items-center justify-between border-b p-4">
                            <h3 className="font-semibold">Notifications</h3>
                            {unreadCount > 0 && (
                                <button
                                    onClick={markAllAsRead}
                                    className="text-xs text-primary hover:underline"
                                >
                                    Mark all as read
                                </button>
                            )}
                        </div>

                        {/* Notifications List */}
                        <div className="max-h-96 overflow-y-auto">
                            {isLoading ? (
                                <div className="p-8 text-center text-sm text-muted-foreground">
                                    Loading...
                                </div>
                            ) : notifications.length === 0 ? (
                                <div className="p-8 text-center text-sm text-muted-foreground">
                                    No notifications
                                </div>
                            ) : (
                                notifications.map((notification) => (
                                    <NotificationItem
                                        key={notification.id}
                                        notification={notification}
                                        relativeTime={getRelativeTime(notification.createdAt)}
                                    />
                                ))
                            )}
                        </div>

                        {/* Footer */}
                        <div className="border-t p-2">
                            <Link
                                href="/dashboard/notifications"
                                className="block w-full rounded-md py-2 text-center text-sm font-medium text-primary hover:bg-muted"
                                onClick={() => setIsOpen(false)}
                            >
                                View all notifications
                            </Link>
                        </div>
                    </div>
                </>
            )}
        </div>
    )
}

function NotificationItem({ notification, relativeTime }: { notification: Notification; relativeTime: string }) {
    // Map notification types to display styles
    const getTypeStyles = (type: string) => {
        const styles: Record<string, string> = {
            accountVerified: 'bg-green-100 text-green-700',
            accountRejected: 'bg-red-100 text-red-700',
            accountPending: 'bg-yellow-100 text-yellow-700',
            info: 'bg-blue-100 text-blue-700',
        }
        return styles[type] || styles.info
    }

    return (
        <div
            className={cn(
                'border-b p-4 transition-colors hover:bg-muted',
                !notification.isRead && 'bg-primary/5'
            )}
        >
            <div className="flex gap-3">
                <div className={cn('mt-1 h-2 w-2 shrink-0 rounded-full', getTypeStyles(notification.type))} />
                <div className="flex-1 space-y-1">
                    <p className="text-sm font-medium">{notification.title}</p>
                    <p className="text-xs text-muted-foreground line-clamp-2">{notification.message}</p>
                    <p className="text-xs text-muted-foreground">{relativeTime}</p>
                </div>
                {!notification.isRead && (
                    <div className="h-2 w-2 shrink-0 rounded-full bg-primary" />
                )}
            </div>
        </div>
    )
}
