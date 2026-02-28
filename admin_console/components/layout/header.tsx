'use client'

import { UserNav } from './user-nav'
import { NotificationDropdown } from './notification-dropdown'

export function Header() {
    return (
        <header className="sticky top-0 z-40 border-b bg-card px-4 py-4 shadow-sm transition-all duration-300 lg:ml-16 lg:px-6">
            <div className="flex items-start justify-between gap-4">
                {/* Page Title */}
                <div className="space-y-1 flex-1 min-w-0">
                    <h1 className="text-xl font-bold tracking-tight sm:text-2xl">Dashboard</h1>
                    <p className="text-xs sm:text-sm text-muted-foreground">
                        Welcome back! Here&apos;s an overview of your food redistribution platform.
                    </p>
                </div>

                {/* Right side - Notifications & User */}
                <div className="flex items-center gap-x-2 sm:gap-x-3 shrink-0">
                    <NotificationDropdown />
                    <UserNav />
                </div>
            </div>
        </header>
    )
}
