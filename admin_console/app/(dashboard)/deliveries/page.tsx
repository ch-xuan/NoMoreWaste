'use client'

import { useState, useEffect } from 'react'
import { Truck, MapPin, User2, Clock, CheckCircle2, Package, X, Phone, Navigation, Loader2 } from 'lucide-react'

// Task interface based on Firestore data model
interface Task {
    id: string
    volunteerId: string
    volunteerName?: string
    volunteerPhone?: string
    status: 'pending' | 'accepted' | 'picked-up' | 'in-transit' | 'delivered' | 'completed'
    donationId: string
    donationTitle: string
    description: string
    quantity: string
    unit?: string
    pickupName: string
    pickupAddress: string
    dropoffName: string
    dropoffAddress: string
    vendorId: string
    ngoId: string
    requestId: string
    imageUrl?: string
    createdAt: string
    acceptedAt?: string
    pickedUpAt?: string
    deliveredAt?: string
    completedAt?: string
    pickupWindowStart?: string
    pickupWindowEnd?: string
    proof?: {
        pickupCode?: string
        deliveryCode?: string
        deliveryNote?: string
    }
}

export default function DeliveriesPage() {
    const [selectedTask, setSelectedTask] = useState<any>(null)
    const [tasks, setTasks] = useState<Task[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const [volunteerData, setVolunteerData] = useState<Record<string, { name: string; phone: string }>>({})

    useEffect(() => {
        fetchTasks()
    }, [])

    const fetchTasks = async () => {
        try {
            setIsLoading(true)
            setError(null)
            console.log('Fetching tasks from /api/tasks/list...')
            const response = await fetch('/api/tasks/list')
            console.log('Response status:', response.status, 'OK:', response.ok)

            if (!response.ok) {
                if (response.status === 401) {
                    console.warn('Unauthorized, redirecting to login...')
                    // Don't set error state, just redirect
                    window.location.href = '/login'
                    return
                }

                const text = await response.text()
                console.error('Failed to fetch tasks, status:', response.status)
                console.error('Response text:', text.substring(0, 500))
                setError(`Failed to load tasks (${response.status})`)
                return
            }

            const data = await response.json()
            console.log('Tasks data received:', data.tasks?.length, 'tasks')

            if (data.success) {
                setTasks(data.tasks)
                // Fetch volunteer details for all unique volunteer IDs 
                const volunteerIds = [...new Set(data.tasks.map((t: Task) => t.volunteerId).filter(Boolean))] as string[]
                await fetchVolunteerDetails(volunteerIds)
            }
        } catch (error) {
            console.error('Failed to fetch tasks:', error)
            setError('Failed to load tasks. Please check the console for details.')
        } finally {
            setIsLoading(false)
        }
    }

    const fetchVolunteerDetails = async (volunteerIds: string[]) => {
        try {
            const details: Record<string, { name: string; phone: string }> = {}

            // Fetch user details for each volunteer
            for (const id of volunteerIds) {
                try {
                    const response = await fetch(`/api/user/details?userId=${id}`)

                    if (!response.ok) {
                        console.warn(`Failed to fetch volunteer ${id}, status:`, response.status)
                        continue
                    }

                    const data = await response.json()
                    if (data.success && data.user) {
                        details[id] = {
                            name: data.user.displayName || 'Unknown Volunteer',
                            phone: data.user.phoneNumber || 'N/A'
                        }
                    }
                } catch (error) {
                    console.warn(`Error fetching volunteer ${id}:`, error)
                    // Continue with other volunteers even if one fails
                }
            }

            setVolunteerData(details)
        } catch (error) {
            console.error('Failed to fetch volunteer details:', error)
        }
    }

    // Map Firestore status to UI status
    const mapStatus = (status: string): 'assigned' | 'in-transit' | 'completed' => {
        if (status === 'completed' || status === 'delivered') return 'completed'
        // User request: "when tasks is pickup (assigned), tagged will change to in-transit"
        if (['picked-up', 'in-transit', 'assigned', 'accepted'].includes(status)) return 'in-transit'
        return 'assigned' // Pending tasks
    }

    // Helper to format relative time
    const getRelativeTime = (timestamp?: string) => {
        if (!timestamp) return 'N/A'
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

    // Transform Firestore task data to UI format
    const transformTask = (task: Task) => {
        const volunteer = volunteerData[task.volunteerId] || { name: 'Unknown Volunteer', phone: 'N/A' }
        const uiStatus = mapStatus(task.status)

        return {
            id: task.id,
            volunteer: volunteer.name,
            phone: volunteer.phone,
            status: uiStatus,
            donation: {
                vendor: task.pickupName,
                ngo: task.dropoffName,
                foodType: task.donationTitle,
                quantity: `${task.quantity}${task.unit ? ' ' + task.unit : ''}`,
            },
            pickup: {
                address: task.pickupAddress,
                time: task.pickedUpAt
                    ? `${new Date(task.pickedUpAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })} (Completed)`
                    : task.acceptedAt
                        ? `${new Date(task.acceptedAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })} (Scheduled)`
                        : 'Pending',
            },
            delivery: {
                address: task.dropoffAddress,
                time: task.deliveredAt
                    ? `${new Date(task.deliveredAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })} (Completed)`
                    : task.pickedUpAt
                        ? 'In Transit'
                        : 'Pending',
            },
            estimatedDuration: task.pickupWindowEnd ? `${task.pickupWindowEnd} mins` : '30 mins',
            distance: '5 km', // Default as per request
            completedAt: task.completedAt ? getRelativeTime(task.completedAt) : undefined,
            currentLocation: uiStatus === 'in-transit'
                ? `${task.pickupAddress} → ${task.dropoffAddress}`
                : undefined,
            proof: task.proof,
            description: task.description,
        }
    }

    const transformedTasks = tasks.map(transformTask)

    const stats = {
        assigned: transformedTasks.filter((t) => t.status === 'assigned').length,
        inTransit: transformedTasks.filter((t) => t.status === 'in-transit').length,
        completed: transformedTasks.filter((t) => t.status === 'completed').length,
    }

    return (
        <>
            <div className="space-y-6">
                {/* Stats Overview */}
                <div className="grid gap-4 md:grid-cols-3">
                    <StatCard label="Assigned Tasks" count={stats.assigned} color="yellow" />
                    <StatCard label="In Transit" count={stats.inTransit} color="blue" />
                    <StatCard label="Completed" count={stats.completed} color="green" />
                </div>

                {/* Tasks List */}
                {error ? (
                    <div className="flex items-center justify-center p-12 rounded-lg border bg-card border-destructive/50">
                        <div className="text-center">
                            <p className="text-destructive font-medium">{error}</p>
                            <button
                                onClick={fetchTasks}
                                className="mt-4 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
                            >
                                Retry
                            </button>
                        </div>
                    </div>
                ) : isLoading ? (
                    <div className="flex items-center justify-center p-12 rounded-lg border bg-card">
                        <div className="text-center">
                            <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
                            <p className="mt-4 text-sm text-muted-foreground">Loading tasks...</p>
                        </div>
                    </div>
                ) : transformedTasks.length === 0 ? (
                    <div className="flex items-center justify-center p-12 rounded-lg border bg-card">
                        <p className="text-muted-foreground">No tasks found</p>
                    </div>
                ) : (
                    <div className="space-y-4">
                        {transformedTasks.map((task) => (
                            <TaskCard
                                key={task.id}
                                task={task}
                                onTrack={() => setSelectedTask(task)}
                            />
                        ))}
                    </div>
                )}
            </div>

            {/* Tracking Modal */}
            {selectedTask && (
                <TrackingModal
                    task={selectedTask}
                    onClose={() => setSelectedTask(null)}
                />
            )}
        </>
    )
}

function StatCard({ label, count, color }: { label: string; count: number; color: string }) {
    const colors = {
        yellow: 'border-yellow-200 bg-yellow-50',
        blue: 'border-blue-200 bg-blue-50',
        green: 'border-green-200 bg-green-50',
    }

    return (
        <div className={`rounded-lg border p-4 ${colors[color as keyof typeof colors]}`}>
            <p className="text-sm font-medium text-muted-foreground">{label}</p>
            <p className="mt-2 text-3xl font-bold">{count}</p>
        </div>
    )
}

function TaskCard({ task, onTrack }: { task: any; onTrack: (task: any) => void }) {
    const statusConfig: Record<string, { label: string; color: string; icon: any }> = {
        assigned: {
            label: 'Assigned',
            color: 'bg-yellow-100 text-yellow-700',
            icon: Clock,
        },
        'in-transit': {
            label: 'In Transit',
            color: 'bg-blue-100 text-blue-700',
            icon: Truck,
        },
        completed: {
            label: 'Completed',
            color: 'bg-green-100 text-green-700',
            icon: CheckCircle2,
        },
    }

    const config = statusConfig[task.status] || statusConfig.assigned
    const StatusIcon = config.icon

    return (
        <div className="rounded-lg border bg-card p-6 shadow-sm">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div className="flex-1 space-y-4">
                    {/* Header */}
                    <div className="flex flex-wrap items-center gap-3">
                        <User2 className="h-5 w-5 text-primary" />
                        <div>
                            <h3 className="font-semibold">{task.volunteer}</h3>
                            <p className="text-sm text-muted-foreground">{task.phone}</p>
                        </div>
                        <span className={`ml-auto rounded-full px-3 py-1 text-xs font-medium ${config.color} lg:ml-4`}>
                            <StatusIcon className="mr-1 inline h-3 w-3" />
                            {config.label}
                        </span>
                    </div>

                    {/* Donation Details */}
                    <div className="rounded-md bg-muted p-4">
                        <div className="grid gap-2 sm:grid-cols-3">
                            <div>
                                <p className="text-xs text-muted-foreground">Vendor</p>
                                <p className="font-medium">{task.donation.vendor}</p>
                            </div>
                            <div>
                                <p className="text-xs text-muted-foreground">Recipient</p>
                                <p className="font-medium">{task.donation.ngo}</p>
                            </div>
                            <div>
                                <p className="text-xs text-muted-foreground">Items</p>
                                <p className="font-medium">
                                    {task.donation.foodType} ({task.donation.quantity})
                                </p>
                            </div>
                        </div>
                    </div>

                    {/* Route */}
                    <div className="space-y-3">
                        <div className="flex items-start gap-3">
                            <Package className="mt-1 h-4 w-4 text-green-600" />
                            <div>
                                <p className="text-sm font-medium">Pickup</p>
                                <p className="text-xs text-muted-foreground">{task.pickup.address}</p>
                                <p className="text-xs text-muted-foreground">{task.pickup.time}</p>
                            </div>
                        </div>
                        <div className="ml-2 h-6 w-0.5 bg-border" />
                        <div className="flex items-start gap-3">
                            <MapPin className="mt-1 h-4 w-4 text-red-600" />
                            <div>
                                <p className="text-sm font-medium">Delivery</p>
                                <p className="text-xs text-muted-foreground">{task.delivery.address}</p>
                                <p className="text-xs text-muted-foreground">{task.delivery.time}</p>
                            </div>
                        </div>
                    </div>

                    {task.completedAt && (
                        <div className="flex items-center gap-2 text-green-600">
                            <CheckCircle2 className="h-4 w-4" />
                            <p className="text-sm">Completed {task.completedAt}</p>
                        </div>
                    )}
                </div>

                {/* Actions */}
                <div className="flex flex-row gap-2 lg:flex-col">
                    <button
                        onClick={onTrack}
                        className="flex-1 rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted lg:flex-none"
                    >
                        Track
                    </button>
                    <button className="flex-1 rounded-md border border-destructive px-4 py-2 text-sm font-medium text-destructive hover:bg-destructive/10 lg:flex-none">
                        Flag Issue
                    </button>
                </div>
            </div>
        </div>
    )
}

function TrackingModal({ task, onClose }: { task: any; onClose: () => void }) {
    const statusConfig: Record<string, { label: string; color: string; icon: any }> = {
        assigned: {
            label: 'Assigned',
            color: 'bg-yellow-100 text-yellow-700',
            icon: Clock,
        },
        'in-transit': {
            label: 'In Transit',
            color: 'bg-blue-100 text-blue-700',
            icon: Truck,
        },
        completed: {
            label: 'Completed',
            color: 'bg-green-100 text-green-700',
            icon: CheckCircle2,
        },
    }

    const config = statusConfig[task.status] || statusConfig.assigned
    const StatusIcon = config.icon

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* Backdrop */}
            <div className="absolute inset-0 bg-black/50" onClick={onClose} />

            {/* Modal */}
            <div className="relative z-10 w-full max-w-3xl max-h-[90vh] overflow-y-auto rounded-lg border bg-card shadow-lg">
                {/* Header */}
                <div className="sticky top-0 flex items-center justify-between border-b bg-card p-6">
                    <div>
                        <h2 className="text-xl font-bold">Delivery Tracking</h2>
                        <p className="text-sm text-muted-foreground">Task ID: {task.id}</p>
                    </div>
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
                    {/* Status Badge */}
                    <div className="flex items-center justify-center">
                        <span className={`inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium ${config.color}`}>
                            <StatusIcon className="h-4 w-4" />
                            {config.label}
                        </span>
                    </div>

                    {/* Current Location (for in-transit) */}
                    {task.currentLocation && (
                        <div className="rounded-lg bg-blue-50 border border-blue-200 p-4">
                            <div className="flex items-center gap-2">
                                <Navigation className="h-5 w-5 text-blue-600" />
                                <div>
                                    <p className="font-medium text-blue-900">Current Location</p>
                                    <p className="text-sm text-blue-700">{task.currentLocation}</p>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Volunteer Info */}
                    <div>
                        <h3 className="mb-3 font-semibold">Volunteer Information</h3>
                        <div className="rounded-lg bg-muted p-4 space-y-2">
                            <div className="flex items-center gap-2">
                                <User2 className="h-4 w-4 text-muted-foreground" />
                                <span className="font-medium">{task.volunteer}</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <Phone className="h-4 w-4 text-muted-foreground" />
                                <a href={`tel:${task.phone}`} className="text-sm text-primary hover:underline">
                                    {task.phone}
                                </a>
                            </div>
                        </div>
                    </div>

                    {/* Route Information */}
                    <div>
                        <h3 className="mb-3 font-semibold">Route Information</h3>
                        <div className="space-y-4">
                            {/* Pickup */}
                            <div className="flex items-start gap-4">
                                <div className={`mt-1 rounded-full p-2 ${task.status !== 'assigned' ? 'bg-green-100' : 'bg-muted'}`}>
                                    <Package className={`h-5 w-5 ${task.status !== 'assigned' ? 'text-green-600' : 'text-muted-foreground'}`} />
                                </div>
                                <div className="flex-1">
                                    <p className="font-medium">Pickup Location</p>
                                    <p className="text-sm text-muted-foreground">{task.pickup.address}</p>
                                    <p className="text-sm text-muted-foreground">{task.pickup.time}</p>
                                    {task.status !== 'assigned' && (
                                        <div className="mt-1 flex items-center gap-1 text-green-600">
                                            <CheckCircle2 className="h-3 w-3" />
                                            <span className="text-xs">Completed</span>
                                        </div>
                                    )}
                                </div>
                            </div>

                            {/* Progress Line */}
                            <div className="ml-6 h-8 w-0.5 bg-border" />

                            {/* Delivery */}
                            <div className="flex items-start gap-4">
                                <div className={`mt-1 rounded-full p-2 ${task.status === 'completed' ? 'bg-green-100' : 'bg-muted'}`}>
                                    <MapPin className={`h-5 w-5 ${task.status === 'completed' ? 'text-green-600' : 'text-muted-foreground'}`} />
                                </div>
                                <div className="flex-1">
                                    <p className="font-medium">Delivery Location</p>
                                    <p className="text-sm text-muted-foreground">{task.delivery.address}</p>
                                    <p className="text-sm text-muted-foreground">{task.delivery.time}</p>
                                    {task.status === 'completed' && (
                                        <div className="mt-1 flex items-center gap-1 text-green-600">
                                            <CheckCircle2 className="h-3 w-3" />
                                            <span className="text-xs">Completed {task.completedAt}</span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Delivery Stats */}
                    <div>
                        <h3 className="mb-3 font-semibold">Delivery Statistics</h3>
                        <div className="grid gap-4 sm:grid-cols-2">
                            <div className="rounded-lg border p-4">
                                <p className="text-sm text-muted-foreground">Distance</p>
                                <p className="text-xl font-bold">{task.distance}</p>
                            </div>
                            <div className="rounded-lg border p-4">
                                <p className="text-sm text-muted-foreground">Estimated Duration</p>
                                <p className="text-xl font-bold">{task.estimatedDuration}</p>
                            </div>
                        </div>
                    </div>

                    {/* Donation Details */}
                    <div>
                        <h3 className="mb-3 font-semibold">Donation Details</h3>
                        <div className="rounded-lg bg-muted p-4">
                            <div className="grid gap-3 sm:grid-cols-2">
                                <div>
                                    <p className="text-sm text-muted-foreground">Vendor</p>
                                    <p className="font-medium">{task.donation.vendor}</p>
                                </div>
                                <div>
                                    <p className="text-sm text-muted-foreground">Recipient NGO</p>
                                    <p className="font-medium">{task.donation.ngo}</p>
                                </div>
                                <div>
                                    <p className="text-sm text-muted-foreground">Food Type</p>
                                    <p className="font-medium">{task.donation.foodType}</p>
                                </div>
                                <div>
                                    <p className="text-sm text-muted-foreground">Quantity</p>
                                    <p className="font-medium">{task.donation.quantity}</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Map Placeholder */}
                    <div>
                        <h3 className="mb-3 font-semibold">Route Map</h3>
                        <div className="rounded-lg border bg-muted p-12 text-center">
                            <MapPin className="mx-auto h-8 w-8 text-muted-foreground" />
                            <p className="mt-2 text-sm text-muted-foreground">Interactive route map coming soon</p>
                        </div>
                    </div>
                </div>

                {/* Footer Actions */}
                <div className="border-t p-6">
                    <div className="flex flex-col gap-2 sm:flex-row sm:justify-between">
                        <a
                            href={`tel:${task.phone}`}
                            className="inline-flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
                        >
                            <Phone className="h-4 w-4" />
                            Call Volunteer
                        </a>
                        <div className="flex gap-2">
                            <button className="flex-1 rounded-md border border-destructive px-4 py-2 text-sm font-medium text-destructive hover:bg-destructive/10 sm:flex-none">
                                Flag Issue
                            </button>
                            <button
                                onClick={onClose}
                                className="flex-1 rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted sm:flex-none"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
