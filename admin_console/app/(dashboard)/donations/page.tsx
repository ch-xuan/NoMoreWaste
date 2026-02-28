'use client'

import { useState, useEffect } from 'react'
import { Package, MapPin, Clock, CheckCircle2, AlertCircle, X, Phone, Loader2 } from 'lucide-react'

export default function DonationsPage() {
    const [selectedDonation, setSelectedDonation] = useState<any>(null)
    const [donations, setDonations] = useState<any[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [selectedImage, setSelectedImage] = useState<string | null>(null)

    useEffect(() => {
        fetchDonations()
    }, [])

    const fetchDonations = async () => {
        setIsLoading(true)
        try {
            const response = await fetch('/api/donations/list')
            if (response.ok) {
                const data = await response.json()
                setDonations(data.donations || [])
            }
        } catch (error) {
            console.error('Failed to fetch donations:', error)
        } finally {
            setIsLoading(false)
        }
    }

    if (isLoading) {
        return (
            <div className="flex items-center justify-center min-h-[400px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        )
    }

    const statusCounts = {
        available: donations.filter((d) => d.status === 'available').length,
        inTransit: donations.filter((d) => ['in-transit', 'assigned', 'accepted', 'picked-up'].includes(d.status)).length,
        completed: donations.filter((d) => d.status === 'completed').length,
    }

    return (
        <>
            <div className="space-y-6">
                {/* Status Overview */}
                <div className="grid gap-4 md:grid-cols-3">
                    <StatusCard
                        label="Available"
                        count={statusCounts.available}
                        color="yellow"
                    />
                    <StatusCard
                        label="In Transit"
                        count={statusCounts.inTransit}
                        color="blue"
                    />
                    <StatusCard
                        label="Completed"
                        count={statusCounts.completed}
                        color="gray"
                    />
                </div>

                {/* Donations List */}
                <div className="space-y-4">
                    {donations.length === 0 ? (
                        <div className="text-center p-8 rounded-lg border bg-card">
                            <Package className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
                            <p className="text-muted-foreground">No donations found</p>
                            <p className="text-sm text-muted-foreground mt-2">Donations will appear here once they are created in the system.</p>
                        </div>
                    ) : (
                        donations.map((donation) => (
                            <DonationCard
                                key={donation.id}
                                donation={donation}
                                onViewDetails={() => setSelectedDonation(donation)}
                            />
                        ))
                    )}
                </div>
            </div>

            {/* Donation Details Modal */}
            {selectedDonation && (
                <DonationDetailModal
                    donation={selectedDonation}
                    onClose={() => setSelectedDonation(null)}
                    onImageClick={(img) => setSelectedImage(img)}
                />
            )}

            {/* Image Lightbox Modal */}
            {selectedImage && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80" onClick={() => setSelectedImage(null)}>
                    <div className="relative max-w-4xl max-h-[90vh]">
                        <button
                            onClick={() => setSelectedImage(null)}
                            className="absolute -top-10 right-0 text-white hover:text-gray-300"
                        >
                            <X className="h-8 w-8" />
                        </button>
                        <img
                            src={selectedImage}
                            alt="Full size"
                            className="max-w-full max-h-[90vh] object-contain rounded-lg"
                            onClick={(e) => e.stopPropagation()}
                        />
                    </div>
                </div>
            )}
        </>
    )
}

function StatusCard({ label, count, color }: { label: string; count: number; color: string }) {
    const colors = {
        yellow: 'border-yellow-200 bg-yellow-50',
        blue: 'border-blue-200 bg-blue-50',
        green: 'border-green-200 bg-green-50',
        gray: 'border-gray-200 bg-gray-50',
    }

    return (
        <div className={`rounded-lg border p-4 ${colors[color as keyof typeof colors]}`}>
            <p className="text-sm font-medium text-muted-foreground">{label}</p>
            <p className="mt-2 text-3xl font-bold">{count}</p>
        </div>
    )
}

function DonationCard({ donation, onViewDetails }: { donation: any; onViewDetails: () => void }) {
    const statusConfig: Record<string, { label: string; color: string; icon: any }> = {
        available: {
            label: 'Available',
            color: 'bg-yellow-100 text-yellow-700',
            icon: Package,
        },
        pending: {
            label: 'Pending Pickup',
            color: 'bg-yellow-100 text-yellow-700',
            icon: Clock,
        },
        'in-transit': {
            label: 'In Transit',
            color: 'bg-blue-100 text-blue-700',
            icon: Package,
        },
        assigned: {
            label: 'In Transit', // Display assigned as In Transit per request
            color: 'bg-blue-100 text-blue-700',
            icon: Package,
        },
        accepted: {
            label: 'In Transit',
            color: 'bg-blue-100 text-blue-700',
            icon: Package,
        },
        'picked-up': {
            label: 'In Transit',
            color: 'bg-blue-100 text-blue-700',
            icon: Package,
        },
        completed: {
            label: 'Completed',
            color: 'bg-gray-100 text-gray-700',
            icon: CheckCircle2,
        },
    }

    const config = statusConfig[donation.status] || statusConfig.available
    const StatusIcon = config.icon

    // Helper to format timestamps
    const formatDate = (timestamp: string | null) => {
        if (!timestamp) return 'N/A'
        try {
            const date = new Date(timestamp)
            return date.toLocaleString('en-MY', {
                day: 'numeric',
                month: 'short',
                hour: '2-digit',
                minute: '2-digit'
            })
        } catch {
            return 'N/A'
        }
    }

    // Get max 2 photos
    const displayPhotos = donation.photos?.slice(0, 2) || []

    return (
        <div className="rounded-lg border bg-card p-6 shadow-sm">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                {/* Left: Images + Details */}
                <div className="flex-1 flex gap-4">
                    {/* Images */}
                    {displayPhotos.length > 0 && (
                        <div className="flex gap-2">
                            {displayPhotos.map((photo: string, idx: number) => (
                                <div
                                    key={idx}
                                    className="h-24 w-24 rounded-md border overflow-hidden cursor-pointer hover:opacity-80 transition-opacity"
                                    onClick={onViewDetails}
                                >
                                    <img
                                        src={photo}
                                        alt={`${donation.title} ${idx + 1}`}
                                        className="h-full w-full object-cover"
                                        onError={(e) => {
                                            const target = e.target as HTMLImageElement;
                                            target.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23ddd" width="100" height="100"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" dominant-baseline="middle" text-anchor="middle"%3ENo Image%3C/text%3E%3C/svg%3E';
                                        }}
                                    />
                                </div>
                            ))}
                        </div>
                    )}

                    {/* Text Details */}
                    <div className="flex-1 space-y-3">
                        {/* Header */}
                        <div className="flex flex-wrap items-center gap-3">
                            <h3 className="text-lg font-semibold">{donation.title}</h3>
                            <span className={`rounded-full px-3 py-1 text-xs font-medium ${config.color}`}>
                                <StatusIcon className="mr-1 inline h-3 w-3" />
                                {config.label}
                            </span>
                        </div>

                        {/* Description */}
                        {donation.description && (
                            <p className="text-sm text-muted-foreground">{donation.description}</p>
                        )}

                        {/* Details Grid */}
                        <div className="grid gap-3 sm:grid-cols-2">
                            <div>
                                <p className="text-sm text-muted-foreground">Vendor</p>
                                <p className="font-medium">{donation.vendorName}</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Quantity</p>
                                <p className="font-medium">{donation.quantity} {donation.unit}</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Food Type</p>
                                <p className="font-medium capitalize">{donation.foodType?.replace(/([A-Z])/g, ' $1').trim()}</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Pickup Location</p>
                                <p className="font-medium">{donation.pickupAddress || 'N/A'}</p>
                            </div>
                        </div>

                        {/* Pickup Window */}
                        {donation.pickupWindowStart && (
                            <div className="space-y-1 text-sm">
                                <p className="flex items-center gap-2 text-muted-foreground">
                                    <Clock className="h-4 w-4" />
                                    Pickup: {formatDate(donation.pickupWindowStart)} - {formatDate(donation.pickupWindowEnd)}
                                </p>
                            </div>
                        )}

                        {/* Expiry */}
                        {donation.expiryTime && (
                            <p className="flex items-center gap-2 text-sm text-orange-600">
                                <AlertCircle className="h-4 w-4" />
                                Expires: {formatDate(donation.expiryTime)}
                            </p>
                        )}
                    </div>
                </div>

                {/* Actions */}
                <div className="flex flex-row gap-2 lg:flex-col">
                    <button
                        onClick={onViewDetails}
                        className="flex-1 rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted lg:flex-none"
                    >
                        View Details
                    </button>
                </div>
            </div>
        </div>
    )
}

function DonationDetailModal({ donation, onClose, onImageClick }: { donation: any; onClose: () => void; onImageClick: (img: string) => void }) {
    // Helper to format timestamps
    const formatDate = (timestamp: string | null) => {
        if (!timestamp) return 'N/A'
        try {
            const date = new Date(timestamp)
            return date.toLocaleString('en-MY', {
                weekday: 'short',
                day: 'numeric',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            })
        } catch {
            return 'N/A'
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* Backdrop */}
            <div className="absolute inset-0 bg-black/50" onClick={onClose} />

            {/* Modal */}
            <div className="relative z-10 w-full max-w-3xl max-h-[90vh] overflow-y-auto rounded-lg border bg-card shadow-lg">
                {/* Header */}
                <div className="sticky top-0 flex items-center justify-between border-b bg-card p-6">
                    <h2 className="text-xl font-bold">{donation.title}</h2>
                    <button
                        onClick={onClose}
                        className="rounded-md p-2 hover:bg-muted"
                        aria-label="Close"
                    >
                        <X className="h-5 w-5" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-6">
                    {/* Photos Gallery */}
                    {donation.photos && donation.photos.length > 0 && (
                        <div>
                            <h3 className="mb-3 font-semibold">Photos</h3>
                            <div className="grid grid-cols-2 gap-3">
                                {donation.photos.map((photo: string, idx: number) => (
                                    <div
                                        key={idx}
                                        className="relative aspect-video rounded-lg border overflow-hidden cursor-pointer hover:opacity-80 transition-opacity group"
                                        onClick={() => onImageClick(photo)}
                                    >
                                        <img
                                            src={photo}
                                            alt={`${donation.title} ${idx + 1}`}
                                            className="w-full h-full object-cover"
                                            onError={(e) => {
                                                const target = e.target as HTMLImageElement;
                                                target.src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23ddd" width="100" height="100"/%3E%3Ctext fill="%23999" x="50%25" y="50%25" dominant-baseline="middle" text-anchor="middle"%3ENo Image%3C/text%3E%3C/svg%3E';
                                            }}
                                        />
                                        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center">
                                            <span className="text-white opacity-0 group-hover:opacity-100 transition-opacity">Click to expand</span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Description */}
                    {donation.description && (
                        <div>
                            <h3 className="mb-3 font-semibold">Description</h3>
                            <p className="text-sm text-muted-foreground">{donation.description}</p>
                        </div>
                    )}

                    {/* Vendor Information */}
                    <div>
                        <h3 className="mb-3 font-semibold">Vendor Information</h3>
                        <div className="rounded-lg bg-muted p-4 space-y-2">
                            <div className="flex items-center gap-2">
                                <Package className="h-4 w-4 text-muted-foreground" />
                                <span className="font-medium">{donation.vendorName}</span>
                            </div>
                            {donation.vendorPhone && (
                                <div className="flex items-center gap-2">
                                    <Phone className="h-4 w-4 text-muted-foreground" />
                                    <span className="text-sm">{donation.vendorPhone}</span>
                                </div>
                            )}
                            <div className="flex items-center gap-2">
                                <MapPin className="h-4 w-4 text-muted-foreground" />
                                <span className="text-sm">{donation.pickupAddress || 'Pickup location not specified'}</span>
                            </div>
                        </div>
                    </div>

                    {/* Donation Details */}
                    <div>
                        <h3 className="mb-3 font-semibold">Donation Details</h3>
                        <div className="grid gap-4 sm:grid-cols-2">
                            <div>
                                <p className="text-sm text-muted-foreground">Food Type</p>
                                <p className="font-medium capitalize">{donation.foodType?.replace(/([A-Z])/g, ' $1').trim()}</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Quantity</p>
                                <p className="font-medium">{donation.quantity} {donation.unit}</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Recipient NGO</p>
                                <p className="font-medium">{donation.recipientNGO || '-'}</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Status</p>
                                <p className="font-medium capitalize">{donation.status.replace('-', ' ')}</p>
                            </div>
                        </div>
                    </div>

                    {/* Timeline */}
                    <div>
                        <h3 className="mb-3 font-semibold">Timeline</h3>
                        <div className="space-y-3">
                            {donation.pickupWindowStart && (
                                <div className="flex items-start gap-3">
                                    <Clock className="h-4 w-4 text-muted-foreground mt-1" />
                                    <div>
                                        <p className="text-sm font-medium">Pickup Window</p>
                                        <p className="text-sm text-muted-foreground">
                                            {formatDate(donation.pickupWindowStart)}
                                        </p>
                                        <p className="text-sm text-muted-foreground">
                                            to {formatDate(donation.pickupWindowEnd)}
                                        </p>
                                    </div>
                                </div>
                            )}
                            {donation.expiryTime && (
                                <div className="flex items-start gap-3">
                                    <AlertCircle className="h-4 w-4 text-orange-600 mt-1" />
                                    <div>
                                        <p className="text-sm font-medium">Expiry Time</p>
                                        <p className="text-sm text-muted-foreground">{formatDate(donation.expiryTime)}</p>
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Allergen Warning */}
                    {donation.containsAllergens && (
                        <div>
                            <h3 className="mb-3 font-semibold">Allergen Information</h3>
                            <div className="rounded-lg bg-orange-50 border border-orange-200 p-4">
                                <div className="flex items-start gap-2">
                                    <AlertCircle className="h-4 w-4 text-orange-600 mt-0.5" />
                                    <p className="text-sm text-orange-900 font-medium">This donation contains allergens. Please verify ingredients before distribution.</p>
                                </div>
                            </div>
                        </div>
                    )}
                </div>

                {/* Footer Actions */}
                <div className="border-t p-6">
                    <div className="flex justify-end gap-2">
                        <button
                            onClick={onClose}
                            className="rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted"
                        >
                            Close
                        </button>
                    </div>
                </div>
            </div>
        </div>
    )
}
