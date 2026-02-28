'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { cn } from '@/lib/utils'
import {
    LayoutDashboard,
    Users,
    Package,
    Truck,
    ShieldCheck,
    BarChart3,
    Settings,
    FileText,
    ChevronLeft,
    ChevronRight,
    Bell,
    User2,
    LogOut,
} from 'lucide-react'
import { useSidebar } from '@/contexts/sidebar-context'
import { useState, useEffect } from 'react'

const navigation = [
    {
        name: 'Dashboard',
        href: '/dashboard',
        icon: LayoutDashboard,
    },
    {
        name: 'User Verification',
        href: '/verify',
        icon: ShieldCheck,
    },
    {
        name: 'Donations Monitoring',
        href: '/donations',
        icon: Package,
    },
    {
        name: 'Tasks & Deliveries',
        href: '/deliveries',
        icon: Truck,
    },
    {
        name: 'Content Moderation',
        href: '/moderation',
        icon: Users,
    },
    {
        name: 'Reports & Analytics',
        href: '/reports',
        icon: BarChart3,
    },
    {
        name: 'System Settings',
        href: '/settings',
        icon: Settings,
    },
    {
        name: 'Audit Logs',
        href: '/audit',
        icon: FileText,
    },
]



export function Sidebar() {
    const pathname = usePathname()
    const router = useRouter()
    const { isCollapsed, toggleSidebar } = useSidebar()
    const [showNotifications, setShowNotifications] = useState(false)
    const [showProfileMenu, setShowProfileMenu] = useState(false)
    const [userData, setUserData] = useState<any>(null)
    const [notifications, setNotifications] = useState<any[]>([])
    const [loading, setLoading] = useState(true)

    const unreadCount = notifications.filter((n) => !n.isRead).length

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
            const data = await response.json()
            if (data.success) {
                setNotifications(data.notifications.slice(0, 5))
            }
        } catch (error) {
            console.error('Failed to fetch notifications:', error)
        }
    }

    const handleLogout = async () => {
        await fetch('/api/auth/logout', { method: 'POST' })
        router.push('/login')
    }

    // Helper to get relative time (duplicated from RightSidebar/NotificationDropdown for self-containment)
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
            <aside
                className={cn(
                    'hidden border-r bg-card lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:flex-col transition-all duration-300',
                    isCollapsed ? 'lg:w-16' : 'lg:w-64'
                )}
            >
                <div className="flex h-16 items-center justify-center">
                    <div className="h-8 w-8 animate-pulse rounded-lg bg-muted" />
                </div>
            </aside>
        )
    }

    return (
        <aside
            className={cn(
                'hidden border-r bg-card lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:flex-col transition-all duration-300',
                isCollapsed ? 'lg:w-16' : 'lg:w-64'
            )}
        >
            <div className="flex grow flex-col gap-y-5 overflow-y-auto px-3 py-4">
                {/* Logo */}
                <Link
                    href="/dashboard"
                    className={cn(
                        'flex h-16 shrink-0 items-center cursor-pointer hover:opacity-80 transition-opacity',
                        isCollapsed ? 'justify-center' : 'gap-3 px-3'
                    )}
                >
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-transparent overflow-hidden">
                        <img
                            src="/logo.jpg"
                            alt="Logo"
                            className="h-full w-full object-cover"
                        />
                    </div>
                    {!isCollapsed && (
                        <div>
                            <h1 className="text-lg font-bold text-foreground">NoMoreWaste</h1>
                            <p className="text-xs text-muted-foreground">Admin Portal</p>
                        </div>
                    )}
                </Link>

                {/* Navigation */}
                <nav className="flex flex-1 flex-col">
                    <ul role="list" className="flex flex-1 flex-col gap-y-1">
                        {navigation.map((item) => {
                            const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
                            return (
                                <li key={item.name} className="relative group">
                                    <Link
                                        href={item.href}
                                        className={cn(
                                            'flex items-center gap-x-3 rounded-md p-3 text-sm font-medium leading-6 transition-colors',
                                            isActive
                                                ? 'bg-primary text-primary-foreground'
                                                : 'text-muted-foreground hover:bg-muted hover:text-foreground',
                                            isCollapsed && 'justify-center'
                                        )}
                                    >
                                        <item.icon
                                            className={cn(
                                                'h-5 w-5 shrink-0',
                                                isActive ? 'text-primary-foreground' : 'text-muted-foreground group-hover:text-foreground'
                                            )}
                                            aria-hidden="true"
                                        />
                                        {!isCollapsed && item.name}
                                    </Link>

                                    {/* Tooltip for collapsed state */}
                                    {isCollapsed && (
                                        <div className="absolute left-full ml-2 top-1/2 -translate-y-1/2 px-2 py-1 bg-popover text-popover-foreground text-sm rounded-md shadow-md border opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
                                            {item.name}
                                        </div>
                                    )}
                                </li>
                            )
                        })}
                    </ul>
                </nav>

                {/* Bottom Section - Notifications, Profile, Toggle */}
                <div className="border-t pt-4 space-y-2">
                    {/* Notifications */}
                    <div className="relative">
                        <button
                            onClick={() => setShowNotifications(!showNotifications)}
                            className={cn(
                                'relative flex items-center gap-x-3 rounded-md p-3 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground transition-colors w-full',
                                isCollapsed && 'justify-center'
                            )}
                            aria-label="View notifications"
                        >
                            <Bell className="h-5 w-5" />
                            {!isCollapsed && <span>Notifications</span>}
                            {unreadCount > 0 && (
                                <span className={cn(
                                    "flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white",
                                    isCollapsed ? "absolute -right-1 -top-1" : "ml-auto"
                                )}>
                                    {unreadCount}
                                </span>
                            )}
                        </button>

                        {/* Notifications Dropdown */}
                        {showNotifications && !isCollapsed && (
                            <div className="absolute bottom-full left-0 right-0 mb-2 rounded-lg border bg-card shadow-lg max-h-96 overflow-y-auto">
                                <div className="flex items-center justify-between border-b p-4">
                                    <h3 className="font-semibold">Notifications</h3>
                                    <button
                                        onClick={() => router.push('/notifications')}
                                        className="text-xs text-primary hover:underline"
                                    >
                                        View all
                                    </button>
                                </div>
                                <div>
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
                        )}
                    </div>

                    {/* Profile */}
                    <div className="relative group">
                        <button
                            onMouseEnter={() => setShowProfileMenu(true)}
                            onMouseLeave={() => setShowProfileMenu(false)}
                            className={cn(
                                'flex items-center gap-x-3 rounded-md p-3 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground transition-colors w-full',
                                isCollapsed && 'justify-center'
                            )}
                        >
                            {userData?.photoURL ? (
                                <img
                                    src={userData.photoURL}
                                    alt="Profile"
                                    className="h-8 w-8 rounded-full object-cover"
                                />
                            ) : (
                                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground">
                                    <User2 className="h-5 w-5" />
                                </div>
                            )}
                            {!isCollapsed && (
                                <div className="flex-1 text-left overflow-hidden">
                                    <p className="text-sm font-medium truncate">{userData?.displayName || 'User'}</p>
                                    <p className="text-xs text-muted-foreground truncate">{userData?.role || 'Admin'}</p>
                                </div>
                            )}
                        </button>

                        {/* Profile Dropdown */}
                        {showProfileMenu && (
                            <div
                                onMouseEnter={() => setShowProfileMenu(true)}
                                onMouseLeave={() => setShowProfileMenu(false)}
                                className={cn(
                                    "absolute bottom-full mb-2 rounded-lg border bg-card shadow-lg z-50 min-w-[200px]",
                                    isCollapsed ? "left-full ml-2 bottom-0" : "left-0 right-0"
                                )}
                            >
                                <div className="p-4 border-b">
                                    <p className="font-medium truncate">{userData?.displayName}</p>
                                    <p className="text-xs text-muted-foreground truncate">{userData?.email}</p>
                                    {userData?.isSuperAdmin && (
                                        <span className="mt-2 inline-block rounded-full bg-purple-100 px-2 py-1 text-xs font-medium text-purple-700">
                                            Super Admin
                                        </span>
                                    )}
                                </div>
                                <div className="p-2">
                                    <button
                                        onClick={() => router.push('/profile')}
                                        className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm hover:bg-muted"
                                    >
                                        <User2 className="h-4 w-4" />
                                        View Profile
                                    </button>
                                    <button
                                        onClick={() => router.push('/settings')}
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
                        )}

                        {/* Tooltip for collapsed state */}
                        {isCollapsed && !showProfileMenu && (
                            <div className="absolute left-full ml-2 top-1/2 -translate-y-1/2 px-2 py-1 bg-popover text-popover-foreground text-sm rounded-md shadow-md border opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
                                Profile
                            </div>
                        )}
                    </div>

                    {/* Toggle Button */}
                    <button
                        onClick={toggleSidebar}
                        className={cn(
                            'flex items-center gap-x-3 rounded-md p-3 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground transition-colors w-full',
                            isCollapsed && 'justify-center'
                        )}
                        aria-label={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
                    >
                        {isCollapsed ? (
                            <ChevronRight className="h-5 w-5" />
                        ) : (
                            <ChevronLeft className="h-5 w-5" />
                        )}
                    </button>
                </div>
            </div>
        </aside>
    )
}
