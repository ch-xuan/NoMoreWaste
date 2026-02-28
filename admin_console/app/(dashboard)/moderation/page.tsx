'use client'

import { useState, useEffect } from 'react'
import { Package, AlertTriangle, CheckCircle, XCircle, Clock } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

export default function ModerationPage() {
    const [donations, setDonations] = useState<any[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [actionLoading, setActionLoading] = useState<string | null>(null)

    useEffect(() => {
        fetchDonations()
    }, [])

    const fetchDonations = async () => {
        try {
            const response = await fetch('/api/donations/list')
            const data = await response.json()
            if (data.success) {
                setDonations(data.donations)
            }
        } catch (error) {
            console.error('Failed to fetch donations:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleModerationAction = async (donationId: string, action: 'remove' | 'warn' | 'dismiss', reason?: string) => {
        setActionLoading(`${donationId}-${action}`)
        try {
            const response = await fetch('/api/moderation/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action, donationId, reason }),
            })

            if (response.ok) {
                // Refresh donations list
                await fetchDonations()
                alert(`${action} action completed successfully`)
            } else {
                const errorData = await response.json()
                alert(`Failed: ${errorData.error}`)
            }
        } catch (error) {
            console.error('Moderation action error:', error)
            alert('Failed to perform action')
        } finally {
            setActionLoading(null)
        }
    }

    const stats = {
        total: donations.length,
        available: donations.filter((d) => d.status === 'available').length,
        inTransit: donations.filter((d) => d.status === 'in-transit').length,
    }

    if (isLoading) {
        return (
            <div className="flex h-64 items-center justify-center">
                <div className="text-center">
                    <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent mx-auto" />
                    <p className="mt-4 text-sm text-muted-foreground">Loading donations...</p>
                </div>
            </div>
        )
    }

    return (
        <div className="space-y-6">
            {/* Stats Overview */}
            <div className="grid gap-4 md:grid-cols-3">
                <StatCard label="Total Donations" count={stats.total} color="blue" />
                <StatCard label="Available" count={stats.available} color="yellow" />
                <StatCard label="In Transit" count={stats.inTransit} color="green" />
            </div>

            {/* Donations List */}
            <div className="space-y-4">
                <h2 className="text-xl font-bold">Content Review</h2>
                {donations.map((donation) => (
                    <DonationCard
                        key={donation.id}
                        donation={donation}
                        onAction={handleModerationAction}
                        actionLoading={actionLoading}
                    />
                ))}
            </div>

            {donations.length === 0 && (
                <div className="flex h-64 items-center justify-center rounded-lg border border-dashed">
                    <div className="text-center">
                        <CheckCircle className="mx-auto h-12 w-12 text-muted-foreground" />
                        <h3 className="mt-4 text-lg font-semibold">No Donations</h3>
                        <p className="text-sm text-muted-foreground">No donations available for review.</p>
                    </div>
                </div>
            )}
        </div>
    )
}

function StatCard({ label, count, color }: { label: string; count: number; color: string }) {
    const colors = {
        yellow: 'border-yellow-200 bg-yellow-50',
        green: 'border-green-200 bg-green-50',
        blue: 'border-blue-200 bg-blue-50',
    }

    return (
        <div className={`rounded-lg border p-4 ${colors[color as keyof typeof colors]}`}>
            <p className="text-sm font-medium text-muted-foreground">{label}</p>
            <p className="mt-2 text-3xl font-bold">{count}</p>
        </div>
    )
}

function DonationCard({
    donation,
    onAction,
    actionLoading,
}: {
    donation: any
    onAction: (id: string, action: 'remove' | 'warn' | 'dismiss', reason?: string) => void
    actionLoading: string | null
}) {
    const [showWarnInput, setShowWarnInput] = useState(false)
    const [warnReason, setWarnReason] = useState('')

    const formatDate = (timestamp: string | null) => {
        if (!timestamp) return 'N/A'
        try {
            return new Date(timestamp).toLocaleString('en-MY', {
                day: 'numeric',
                month: 'short',
                hour: '2-digit',
                minute: '2-digit',
            })
        } catch {
            return 'N/A'
        }
    }

    const statusConfig: Record<string, { label: string; color: string; icon: any }> = {
        available: {
            label: 'Available',
            color: 'bg-yellow-100 text-yellow-700',
            icon: Package,
        },
        'in-transit': {
            label: 'In Transit',
            color: 'bg-blue-100 text-blue-700',
            icon: Clock,
        },
        completed: {
            label: 'Completed',
            color: 'bg-gray-100 text-gray-700',
            icon: CheckCircle,
        },
    }

    const config = statusConfig[donation.status] || statusConfig.available
    const StatusIcon = config.icon

    const isLoading = (action: string) => actionLoading === `${donation.id}-${action}`

    return (
        <div className="rounded-lg border bg-card p-6 shadow-sm">
            <div className="flex items-start justify-between gap-4">
                <div className="flex-1 space-y-4">
                    {/* Header */}
                    <div className="flex items-center gap-3">
                        <StatusIcon className="h-5 w-5 text-primary" />
                        <h3 className="font-semibold">{donation.title}</h3>
                        <Badge className={config.color}>{config.label}</Badge>
                    </div>

                    {/* Donation Info */}
                    <div className="rounded-md bg-muted p-4">
                        <div className="grid gap-2 text-sm">
                            <div className="flex justify-between">
                                <span className="text-muted-foreground">Vendor:</span>
                                <span className="font-medium">{donation.vendorName}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-muted-foreground">Food Type:</span>
                                <span className="font-medium capitalize">
                                    {donation.foodType?.replace(/([A-Z])/g, ' $1').trim()}
                                </span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-muted-foreground">Quantity:</span>
                                <span className="font-medium">
                                    {donation.quantity} {donation.unit}
                                </span>
                            </div>
                            {donation.expiryTime && (
                                <div className="flex justify-between">
                                    <span className="text-muted-foreground">Expires:</span>
                                    <span className="font-medium text-orange-600">{formatDate(donation.expiryTime)}</span>
                                </div>
                            )}
                            {donation.containsAllergens && (
                                <div className="flex items-center gap-2 rounded-md bg-orange-50 border border-orange-200 p-2 mt-2">
                                    <AlertTriangle className="h-4 w-4 text-orange-600" />
                                    <span className="text-sm text-orange-900 font-medium">Contains allergens</span>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Description */}
                    {donation.description && (
                        <div>
                            <p className="text-sm font-medium mb-1">Description:</p>
                            <p className="text-sm text-muted-foreground">{donation.description}</p>
                        </div>
                    )}

                    {/* Photos */}
                    {donation.photos && donation.photos.length > 0 && (
                        <div>
                            <p className="text-sm font-medium mb-2">Photos:</p>
                            <div className="flex gap-2">
                                {donation.photos.slice(0, 3).map((photo: string, idx: number) => (
                                    <img
                                        key={idx}
                                        src={photo}
                                        alt={`${donation.title} ${idx + 1}`}
                                        className="h-20 w-20 rounded-md object-cover border"
                                        onError={(e) => {
                                            const target = e.target as HTMLImageElement
                                            target.src =
                                                'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23ddd" width="100" height="100"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" dominant-baseline="middle" text-anchor="middle"%3ENo Image%3C/text%3E%3C/svg%3E'
                                        }}
                                    />
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Warn Input */}
                    {showWarnInput && (
                        <div className="space-y-2">
                            <label className="text-sm font-medium">Warning Reason:</label>
                            <input
                                type="text"
                                value={warnReason}
                                onChange={(e) => setWarnReason(e.target.value)}
                                className="w-full rounded-md border px-3 py-2 text-sm"
                                placeholder="Enter reason for warning..."
                            />
                        </div>
                    )}
                </div>

                {/* Actions */}
                <div className="flex flex-col gap-2">
                    <button
                        onClick={() => onAction(donation.id, 'remove')}
                        disabled={!!actionLoading}
                        className="flex items-center gap-2 rounded-md bg-destructive px-4 py-2 text-sm font-medium text-destructive-foreground hover:bg-destructive/90 disabled:opacity-50 whitespace-nowrap"
                    >
                        {isLoading('remove') ? (
                            <>Processing...</>
                        ) : (
                            <>
                                <XCircle className="h-4 w-4" />
                                Remove Content
                            </>
                        )}
                    </button>
                    <button
                        onClick={() => {
                            if (showWarnInput && warnReason) {
                                onAction(donation.id, 'warn', warnReason)
                                setShowWarnInput(false)
                                setWarnReason('')
                            } else {
                                setShowWarnInput(true)
                            }
                        }}
                        disabled={!!actionLoading}
                        className="flex items-center gap-2 rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50 whitespace-nowrap"
                    >
                        {isLoading('warn') ? <>Processing...</> : showWarnInput ? 'Submit Warning' : 'Warn User'}
                    </button>
                    {showWarnInput && (
                        <button
                            onClick={() => {
                                setShowWarnInput(false)
                                setWarnReason('')
                            }}
                            className="rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted"
                        >
                            Cancel
                        </button>
                    )}
                    <button
                        onClick={() => onAction(donation.id, 'dismiss')}
                        disabled={!!actionLoading}
                        className="flex items-center gap-2 rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50 whitespace-nowrap"
                    >
                        {isLoading('dismiss') ? (
                            <>Processing...</>
                        ) : (
                            <>
                                <CheckCircle className="h-4 w-4" />
                                Dismiss
                            </>
                        )}
                    </button>
                </div>
            </div>
        </div>
    )
}
