'use client'

import { useState, useEffect } from 'react'
import { Shield, User, Clock, CheckCircle, XCircle, Edit, Loader2 } from 'lucide-react'

export default function AuditLogsPage() {
    const [logs, setLogs] = useState<any[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [filter, setFilter] = useState('all')
    const [timeRange, setTimeRange] = useState('Last 7 days')
    const [currentPage, setCurrentPage] = useState(1)
    const logsPerPage = 10

    useEffect(() => {
        fetchAuditLogs()
    }, [])

    const fetchAuditLogs = async () => {
        setIsLoading(true)
        try {
            const response = await fetch('/api/audit/logs')
            if (response.ok) {
                const data = await response.json()
                setLogs(data.logs || [])
            }
        } catch (error) {
            console.error('Failed to fetch audit logs:', error)
        } finally {
            setIsLoading(false)
        }
    }

    // Filter logs
    const filteredLogs = logs.filter(log => {
        if (filter === 'all') return true
        return log.action?.toLowerCase().includes(filter) ||
            log.details?.toLowerCase().includes(filter) ||
            log.category?.toLowerCase() === filter.replace('_', ' ') || // Precise category match
            log.category?.toLowerCase() === filter // Or match raw filter string
    })

    // Pagination logic
    const indexOfLastLog = currentPage * logsPerPage
    const indexOfFirstLog = indexOfLastLog - logsPerPage
    const currentLogs = filteredLogs.slice(indexOfFirstLog, indexOfLastLog)
    const totalPages = Math.ceil(filteredLogs.length / logsPerPage)

    const handleNextPage = () => {
        if (currentPage < totalPages) {
            setCurrentPage(prev => prev + 1)
        }
    }

    const handlePrevPage = () => {
        if (currentPage > 1) {
            setCurrentPage(prev => prev - 1)
        }
    }

    // Reset pagination when filter changes
    useEffect(() => {
        setCurrentPage(1)
    }, [filter])

    const categories = ['all', 'verification', 'moderation', 'settings', 'user_management']

    const formatTimestamp = (timestamp: any) => {
        if (!timestamp) return 'Unknown'

        try {
            let date: Date
            if (timestamp._seconds) {
                date = new Date(timestamp._seconds * 1000)
            } else if (timestamp.seconds) {
                date = new Date(timestamp.seconds * 1000)
            } else {
                date = new Date(timestamp)
            }

            const now = new Date()
            const diffMs = now.getTime() - date.getTime()
            const diffMins = Math.floor(diffMs / 60000)
            const diffHours = Math.floor(diffMs / 3600000)
            const diffDays = Math.floor(diffMs / 86400000)

            if (diffMins < 60) return `${diffMins} min${diffMins !== 1 ? 's' : ''} ago`
            if (diffHours < 24) return `${diffHours} hour${diffHours !== 1 ? 's' : ''} ago`
            if (diffDays < 7) return `${diffDays} day${diffDays !== 1 ? 's' : ''} ago`

            return date.toLocaleDateString()
        } catch {
            return 'Unknown'
        }
    }

    if (isLoading) {
        return (
            <div className="flex items-center justify-center min-h-[400px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        )
    }

    return (
        <div className="space-y-6">
            {/* Page Title */}
            <div className="space-y-1">
                <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Audit Logs</h1>
                <p className="text-sm text-muted-foreground sm:text-base">
                    Track all administrative actions and system events
                </p>
            </div>

            {/* Filters */}
            <div className="flex items-center gap-4 rounded-lg border bg-card p-4">
                <Shield className="h-5 w-5 text-muted-foreground" />
                <div className="flex-1">
                    <p className="text-sm font-medium">Filter by Category</p>
                    <div className="mt-2 flex flex-wrap gap-2">
                        {categories.map((category) => (
                            <button
                                key={category}
                                onClick={() => setFilter(category)}
                                className={`rounded-md border px-3 py-1 text-xs font-medium hover:bg-muted ${filter === category ? 'bg-primary text-primary-foreground' : ''
                                    }`}
                            >
                                {category.replace('_', ' ').charAt(0).toUpperCase() +
                                    category.replace('_', ' ').slice(1)}
                            </button>
                        ))}
                    </div>
                </div>
                <div>
                    <select
                        value={timeRange}
                        onChange={(e) => setTimeRange(e.target.value)}
                        className="rounded-md border border-input bg-background px-3 py-2 text-sm"
                    >
                        <option>Last 7 days</option>
                        <option>Last 30 days</option>
                        <option>Last 3 months</option>
                        <option>All time</option>
                    </select>
                </div>
            </div>

            {/* Audit Logs List */}
            <div className="space-y-3">
                {currentLogs.length === 0 ? (
                    <div className="text-center p-8 rounded-lg border bg-card">
                        <p className="text-muted-foreground">No audit logs found</p>
                    </div>
                ) : (
                    currentLogs.map((log) => (
                        <AuditLogCard
                            key={log.id}
                            action={log.action}
                            details={log.details}
                            timestamp={formatTimestamp(log.timestamp)}
                            userId={log.userId}
                        />
                    ))
                )}
            </div>

            {/* Pagination */}
            {filteredLogs.length > 0 && (
                <div className="flex items-center justify-between border-t pt-4">
                    <p className="text-sm text-muted-foreground">
                        Showing {indexOfFirstLog + 1} to {Math.min(indexOfLastLog, filteredLogs.length)} of {filteredLogs.length} logs
                    </p>
                    <div className="flex gap-2">
                        <button
                            onClick={handlePrevPage}
                            disabled={currentPage === 1}
                            className="rounded-md border px-3 py-1 text-sm hover:bg-muted disabled:opacity-50"
                        >
                            Previous
                        </button>
                        <button
                            onClick={handleNextPage}
                            disabled={currentPage === totalPages}
                            className="rounded-md border px-3 py-1 text-sm hover:bg-muted disabled:opacity-50"
                        >
                            Next
                        </button>
                    </div>
                </div>
            )}
        </div>
    )
}

function AuditLogCard({
    action,
    details,
    timestamp,
    userId,
}: {
    action: string
    details: string
    timestamp: string
    userId: string
}) {
    const actionConfig: Record<string, { icon: any; color: string }> = {
        'Profile photo updated': { icon: Edit, color: 'text-blue-600' },
        'Password changed': { icon: CheckCircle, color: 'text-green-600' },
        '2FA enabled': { icon: Shield, color: 'text-purple-600' },
        'Profile updated': { icon: Edit, color: 'text-blue-600' },
        'Login': { icon: CheckCircle, color: 'text-green-600' },
        'Logout': { icon: XCircle, color: 'text-gray-600' },
    }

    const config = actionConfig[action] || { icon: Shield, color: 'text-gray-600' }
    const ActionIcon = config.icon

    return (
        <div className="flex items-start gap-4 rounded-lg border bg-card p-4 transition-all hover:shadow-md">
            {/* Icon */}
            <div className="flex flex-col items-center">
                <div className={`flex h-8 w-8 items-center justify-center rounded-full bg-muted ${config.color}`}>
                    <ActionIcon className="h-4 w-4" />
                </div>
            </div>

            {/* Content */}
            <div className="flex-1 space-y-2">
                <div className="flex items-start justify-between">
                    <div className="flex items-center gap-2">
                        <p className="text-sm font-semibold">{action}</p>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                        <Clock className="h-3 w-3" />
                        {timestamp}
                    </div>
                </div>

                <p className="text-sm text-muted-foreground">{details}</p>

                <div className="flex items-center gap-2 text-xs">
                    <User className="h-3 w-3 text-muted-foreground" />
                    <span className="text-muted-foreground">User ID: {userId}</span>
                </div>
            </div>
        </div>
    )
}
