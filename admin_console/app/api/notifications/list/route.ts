import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

// Force dynamic to ensure real-time checking
export const dynamic = 'force-dynamic'

export async function GET(request: NextRequest) {
    try {
        const cookieStore = await cookies()
        const sessionCookie = cookieStore.get('session')

        console.log('[API] /notifications/list called')

        if (!sessionCookie) {
            console.log('[API] No session cookie found')
            return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
        }

        const decodedToken = await adminAuth.verifySessionCookie(sessionCookie.value)
        const userId = decodedToken.uid
        console.log('[API] User ID:', userId)

        // Check if user is admin or superadmin
        const userDoc = await adminDb.collection('users').doc(userId).get()
        const userData = userDoc.data()
        console.log('[API] User Role:', userData?.role, 'IsSuperAdmin:', userData?.isSuperAdmin)
        const isAdmin = userData?.role === 'admin' || userData?.role === 'superadmin' || userData?.isSuperAdmin === true || userData?.role === 'SuperAdmin'

        // Fetch regular notifications
        // Note: Removed orderBy to avoid index requirements. Sorting is done in-memory below.
        let notificationsSnapshot
        if (isAdmin) {
            try {
                notificationsSnapshot = await adminDb
                    .collection('notifications')
                    .where('recipientId', 'in', ['admin', userId])
                    .limit(100)
                    .get()
            } catch (err) {
                console.error('[API] Admin notification fetch failed:', err)
                // Fallback to simpler query if 'in' operator fails
                notificationsSnapshot = await adminDb.collection('notifications').limit(50).get()
            }
        } else {
            notificationsSnapshot = await adminDb
                .collection('notifications')
                .where('recipientId', '==', userId)
                .limit(50)
                .get()
        }

        // Base notifications
        const notifications = notificationsSnapshot.docs.map(doc => {
            const data = doc.data()
            return {
                id: doc.id,
                recipientId: data.recipientId,
                senderId: data.senderId,
                title: data.title,
                message: data.message,
                type: data.type,
                entityId: data.entityId,
                isRead: data.isRead || false,
                createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
            }
        })

        // IF ADMIN: Inject "Pending Verification" items from users collection
        if (isAdmin) {
            try {
                // 1. Fetch Pending Users
                console.log('[API] Checking pending users...')
                const pendingUsersSnapshot = await adminDb
                    .collection('users')
                    .where('verificationStatus', '==', 'pending')
                    .get()

                const pendingNotifications = pendingUsersSnapshot.docs.map(doc => {
                    const data = doc.data()
                    return {
                        id: `pending_user_${doc.id}`,
                        recipientId: 'admin',
                        senderId: 'system',
                        title: 'Pending Verification',
                        message: `${data.displayName || data.email || 'New User'} has registered and is waiting for approval`,
                        type: 'accountPending',
                        entityId: doc.id,
                        isRead: false,
                        createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
                    }
                })

                // 2. Fetch Donations (Active/Completed/Expiring) to create synthetic status updates
                // This ensures admin sees status even if they missed the real-time event
                console.log('[API] Checking donation statuses...')
                const donationsSnapshot = await adminDb.collection('donations').limit(50).get()

                const donationNotifications = donationsSnapshot.docs.map(doc => {
                    const data = doc.data()
                    const now = new Date()
                    let notifications = []

                    // Helper to get date
                    const getDate = (ts: any) => {
                        if (!ts) return now
                        if (ts.toDate) return ts.toDate()
                        if (ts._seconds) return new Date(ts._seconds * 1000)
                        return new Date(ts)
                    }

                    const updatedAt = getDate(data.updatedAt || data.createdAt)

                    // A. Delivery Completed (for completed status)
                    if (data.status === 'completed') {
                        notifications.push({
                            id: `donation_completed_${doc.id}`,
                            recipientId: 'admin',
                            senderId: 'system',
                            title: 'Delivery Completed',
                            message: `Donation "${data.title || 'Unknown'}" has been delivered successfully`,
                            type: 'delivery_complete',
                            entityId: doc.id,
                            linkTo: '/dashboard/donations', // Make clickable
                            isRead: false, // Always show as fresh for visibility
                            createdAt: updatedAt.toISOString()
                        })
                    }

                    // B. Pickup Completed / In Transit
                    if (data.status === 'in-transit') {
                        notifications.push({
                            id: `donation_transit_${doc.id}`,
                            recipientId: 'admin',
                            senderId: 'system',
                            title: 'Pickup Completed',
                            message: `Driver has picked up "${data.title || 'Unknown'}" from ${data.vendorName || 'Vendor'}`,
                            type: 'pickup_complete',
                            entityId: doc.id,
                            linkTo: '/dashboard/donations',
                            isRead: false,
                            createdAt: updatedAt.toISOString()
                        })
                    }

                    // C. Expiring Soon (Available + within 24h)
                    if (data.status === 'available' && data.expiryTime) {
                        const expiryDate = getDate(data.expiryTime)
                        const hoursUntilExpiry = (expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60)

                        if (hoursUntilExpiry > 0 && hoursUntilExpiry <= 24) {
                            notifications.push({
                                id: `donation_expiring_${doc.id}`,
                                recipientId: 'admin',
                                senderId: 'system',
                                type: 'expiring_soon',
                                title: 'Donation Expiring Soon',
                                message: `"${data.title}" expires in ${Math.ceil(hoursUntilExpiry)} hours`,
                                entityId: doc.id,
                                linkTo: '/dashboard/donations',
                                isRead: false,
                                createdAt: now.toISOString() // Show as "Just now" relevance
                            })
                        }
                    }

                    return notifications
                }).flat()

                // Merge all synthetic sources
                const allSynthetic = [...pendingNotifications, ...donationNotifications]

                // Add to main list
                notifications.push(...allSynthetic)

                // Remove duplicates based on ID (if real notification exists vs synthetic)
                // We prioritize real notifications, but since synthetic IDs are special, we just dedup by ID string if any clashing occurs
                // Actually, synthetic IDs are unique prefixes, so no clash.

                console.log(`[API] Total notifications (real + synthetic): ${notifications.length}`)

            } catch (err) {
                console.error('[API] Failed to fetch synthetic data:', err)
            }
        } else {
            console.log('[API] User is NOT admin, skipping pending checks')
        }

        // Global Sort (since we removed orderBy from Firestore query)
        notifications.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

        return NextResponse.json(
            {
                success: true,
                notifications,
            },
            { status: 200 }
        )

    } catch (error: any) {
        console.error('Notifications fetch error:', error)
        return NextResponse.json(
            { error: 'Failed to fetch notifications', notifications: [] },
            { status: 500 }
        )
    }
}
