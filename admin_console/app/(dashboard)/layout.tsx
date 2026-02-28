'use client'

import { LeftSidebar } from '@/components/layout/left-sidebar'
import { RightSidebar } from '@/components/layout/right-sidebar'
import { SidebarProvider, useSidebar } from '@/contexts/sidebar-context'
import { cn } from '@/lib/utils'

function DashboardContent({ children }: { children: React.ReactNode }) {
    const { isCollapsed } = useSidebar()

    return (
        <div className="min-h-screen bg-background">
            {/* Left Navigation Sidebar */}
            <LeftSidebar />

            {/* Right Utilities Sidebar */}
            <RightSidebar />

            {/* Main Content Area - Adjusts based on both sidebars */}
            <div
                className={cn(
                    'transition-all duration-300 min-h-screen',
                    // Left padding for left sidebar
                    isCollapsed ? 'lg:pl-16' : 'lg:pl-64',
                    // Right padding for right sidebar
                    'lg:pr-16'
                )}
            >
                {/* Page Content */}
                <main className="p-4 sm:p-6">
                    <div className="mx-auto max-w-7xl">
                        {children}
                    </div>
                </main>
            </div>
        </div>
    )
}

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <SidebarProvider>
            <DashboardContent>{children}</DashboardContent>
        </SidebarProvider>
    )
}
