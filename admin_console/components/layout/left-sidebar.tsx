'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
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
    Menu,
    X,
} from 'lucide-react'
import { useSidebar } from '@/contexts/sidebar-context'

const navigation = [
    { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    { name: 'User Verification', href: '/verify', icon: ShieldCheck },
    { name: 'Donations Monitoring', href: '/donations', icon: Package },
    { name: 'Tasks & Deliveries', href: '/deliveries', icon: Truck },
    { name: 'Content Moderation', href: '/moderation', icon: Users },
    { name: 'Reports & Analytics', href: '/reports', icon: BarChart3 },
    { name: 'System Settings', href: '/settings', icon: Settings },
    { name: 'Audit Logs', href: '/audit', icon: FileText },
]

export function LeftSidebar() {
    const pathname = usePathname()
    const { isCollapsed, toggleSidebar } = useSidebar()
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

    return (
        <>
            {/* Mobile Menu Button */}
            <button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                className="fixed left-4 top-4 z-50 rounded-md bg-card p-2 shadow-lg lg:hidden"
            >
                {mobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>

            {/* Mobile Backdrop */}
            {mobileMenuOpen && (
                <div
                    className="fixed inset-0 z-40 bg-black/50 lg:hidden"
                    onClick={() => setMobileMenuOpen(false)}
                />
            )}

            {/* Sidebar */}
            <aside
                className={cn(
                    'fixed inset-y-0 left-0 z-40 border-r bg-card transition-all duration-300',
                    'flex flex-col',
                    isCollapsed ? 'w-16' : 'w-64',
                    // Mobile: Transform in/out from left
                    mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
                )}
            >
                <div className="flex grow flex-col gap-y-5 overflow-y-auto px-3 py-4">
                    {/* Logo */}
                    <Link
                        href="/dashboard"
                        onClick={() => setMobileMenuOpen(false)}
                        className={cn(
                            'flex h-16 shrink-0 items-center cursor-pointer hover:opacity-80 transition-opacity',
                            isCollapsed ? 'justify-center' : 'gap-3 px-3'
                        )}
                    >
                        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-transparent overflow-hidden">
                            <img
                                src="/app_icon.png"
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
                                            onClick={() => setMobileMenuOpen(false)}
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

                    {/* Toggle Button - Right side when expanded */}
                    <div className="border-t pt-4">
                        <button
                            onClick={toggleSidebar}
                            className={cn(
                                'flex items-center rounded-md p-3 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground transition-colors w-full group relative',
                                isCollapsed ? 'justify-center' : 'justify-end'
                            )}
                            aria-label={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
                        >
                            {isCollapsed ? (
                                <>
                                    <ChevronRight className="h-5 w-5" />
                                    {/* Tooltip */}
                                    <div className="absolute left-full ml-2 top-1/2 -translate-y-1/2 px-2 py-1 bg-popover text-popover-foreground text-sm rounded-md shadow-md border opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
                                        Expand
                                    </div>
                                </>
                            ) : (
                                <ChevronLeft className="h-5 w-5" />
                            )}
                        </button>
                    </div>
                </div>
            </aside>
        </>
    )
}
