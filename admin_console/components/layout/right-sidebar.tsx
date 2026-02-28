'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Bell, User2, Settings, LogOut, Eye } from 'lucide-react'
import { cn } from '@/lib/utils'



export function RightSidebar() {
    const router = useRouter()
    const [showNotifications, setShowNotifications] = useState(false)
    const [showProfileMenu, setShowProfileMenu] = useState(false)
    const [profileMenuOpen, setProfileMenuOpen] = useState(false)
    const [userData, setUserData] = useState<any>(null)
    const [loading, setLoading] = useState(true)
    const [notifications, setNotifications] = useState<any[]>([])

    const unreadCount = notifications.filter((n) => !n.isRead).length

    // Fetch user data and notifications
    useEffect(() => {
        fetchUserData()
        fetchNotifications()

        const handleUserUpdate = () => {
            fetchUserData()
        }
        window.addEventListener('user-updated', handleUserUpdate)

        // Poll for notifications
        const interval = setInterval(fetchNotifications, 30000)

        return () => {
            window.removeEventListener('user-updated', handleUserUpdate)
            clearInterval(interval)
        }
    }, [])

    const fetchUserData = async () => {
        try {
            const response = await fetch('/api/user/profile')
            if (response.ok) {
                const data = await response.json()
                setUserData(data.user)
            }
        } catch (error) {
            console.error('Failed to fetch user data:', error)
        } finally {
            setLoading(false)
        }
    }

    const fetchNotifications = async () => {
        try {
            const response = await fetch('/api/notifications/list')

            // Silently handle unauthorized (e.g. session expired)
            if (response.status === 401) return

            const data = await response.json()
            if (data.success) {
                setNotifications(data.notifications.slice(0, 5))
            }
        } catch (error) {
            // Silently ignore network errors during polling
        }
    }

    const handleLogout = async () => {
        await fetch('/api/auth/logout', { method: 'POST' })
        router.push('/login')
    }

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

    if (loading) {
        return (
            <aside className="fixed right-0 top-0 z-40 flex h-screen w-16 flex-col items-center gap-4 border-l bg-card py-4">
                <div className="h-10 w-10 animate-pulse rounded-full bg-muted" />
                <div className="h-10 w-10 animate-pulse rounded-full bg-muted" />
            </aside>
        )
    }

    return (
        <aside className="fixed right-0 top-0 z-40 flex h-screen w-16 flex-col items-center gap-4 border-l bg-card py-4">
            {/* Profile - First at top */}
            <div className="relative">
                <button
                    onMouseEnter={() => setShowProfileMenu(true)}
                    onMouseLeave={() => setShowProfileMenu(false)}
                    onClick={() => {
                        setProfileMenuOpen(!profileMenuOpen)
                        setShowProfileMenu(false)
                    }}
                    className={cn(
                        'flex h-10 w-10 items-center justify-center rounded-full transition-colors',
                        (showProfileMenu || profileMenuOpen) ? 'bg-primary text-primary-foreground' : 'bg-primary/10 text-primary hover:bg-primary hover:text-primary-foreground',
                        userData?.photoURL && 'p-0 ring-2 ring-transparent hover:ring-primary'
                    )}
                >
                    {userData?.photoURL ? (
                        <img
                            src={userData.photoURL}
                            alt="Profile"
                            className="h-full w-full rounded-full object-cover"
                        />
                    ) : (
                        <User2 className="h-5 w-5" />
                    )}
                </button>

                {/* Hover Tooltip - Basic Info */}
                {showProfileMenu && !profileMenuOpen && (
                    <div
                        onMouseEnter={() => setShowProfileMenu(true)}
                        onMouseLeave={() => setShowProfileMenu(false)}
                        className="absolute top-0 right-full mr-2 rounded-lg border bg-card p-3 shadow-lg z-50 min-w-[200px]"
                    >
                        <p className="font-medium text-sm">{userData?.displayName || 'Loading...'}</p>
                        <p className="text-xs text-muted-foreground">{userData?.email}</p>
                        {userData?.isSuperAdmin && (
                            <span className="mt-2 inline-block rounded-full bg-purple-100 px-2 py-0.5 text-xs font-medium text-purple-700">
                                Super Admin
                            </span>
                        )}
                    </div>
                )}

                {/* Click Menu - Full Options */}
                {profileMenuOpen && (
                    <>
                        {/* Backdrop */}
                        <div
                            className="fixed inset-0 z-40"
                            onClick={() => setProfileMenuOpen(false)}
                        />

                        {/* Menu */}
                        <div className="absolute top-0 right-full mr-2 rounded-lg border bg-card shadow-lg z-50 min-w-[220px]">
                            <div className="border-b p-4">
                                <p className="font-medium">{userData?.displayName}</p>
                                <p className="text-xs text-muted-foreground">{userData?.email}</p>
                                {userData?.isSuperAdmin && (
                                    <span className="mt-2 inline-block rounded-full bg-purple-100 px-2 py-1 text-xs font-medium text-purple-700">
                                        Super Admin
                                    </span>
                                )}
                            </div>
                            <div className="p-2">
                                <button
                                    onClick={() => {
                                        setProfileMenuOpen(false)
                                        router.push('/profile')
                                    }}
                                    className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm hover:bg-muted"
                                >
                                    <Eye className="h-4 w-4" />
                                    View Profile
                                </button>
                                <button
                                    onClick={() => {
                                        setProfileMenuOpen(false)
                                        router.push('/settings')
                                    }}
                                    className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm hover:bg-muted"
                                >
                                    <Settings className="h-4 w-4" />
                                    Settings
                                </button>
                                <button
                                    onClick={handleLogout}
                                    className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-destructive hover:bg-destructive/10"
                                >
                                    <LogOut className="h-4 w-4" />
                                    Logout
                                </button>
                            </div>
                        </div>
                    </>
                )}
            </div>

            {/* Notifications - Second at top */}
            <div className="relative">
                <button
                    onClick={() => setShowNotifications(!showNotifications)}
                    className={cn(
                        'relative flex h-10 w-10 items-center justify-center rounded-full transition-colors',
                        showNotifications ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                    )}
                    aria-label="Notifications"
                >
                    <Bell className="h-5 w-5" />
                    {unreadCount > 0 && (
                        <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white animate-pulse">
                            {unreadCount}
                        </span>
                    )}
                </button>

                {/* Notifications Dropdown */}
                {showNotifications && (
                    <>
                        {/* Backdrop */}
                        <div
                            className="fixed inset-0 z-40"
                            onClick={() => setShowNotifications(false)}
                        />

                        {/* Dropdown */}
                        <div className="absolute top-0 right-full mr-2 z-50 w-80 rounded-lg border bg-card shadow-lg">
                            <div className="flex items-center justify-between border-b p-4">
                                <h3 className="font-semibold">Notifications</h3>
                                <button
                                    onClick={() => {
                                        setShowNotifications(false)
                                        router.push('/notifications')
                                    }}
                                    className="text-xs text-primary hover:underline"
                                >
                                    View all
                                </button>
                            </div>
                            <div className="max-h-96 overflow-y-auto">
                                {notifications.length === 0 ? (
                                    <div className="p-4 text-center text-sm text-muted-foreground">
                                        No notifications
                                    </div>
                                ) : (
                                    notifications.map((notification) => (
                                        <div
                                            key={notification.id}
                                            className={cn(
                                                'border-b p-4 transition-colors hover:bg-muted cursor-pointer',
                                                !notification.isRead && 'bg-primary/5'
                                            )}
                                        >
                                            <p className="text-sm font-medium">{notification.title}</p>
                                            <p className="text-xs text-muted-foreground">{notification.message}</p>
                                            <p className="text-xs text-muted-foreground mt-1">{getRelativeTime(notification.createdAt)}</p>
                                        </div>
                                    ))
                                )}
                            </div>
                        </div>
                    </>
                )}
            </div>
        </aside>
    )
}
