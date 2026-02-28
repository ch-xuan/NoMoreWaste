import { NextRequest, NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'
import { createNotification } from '@/lib/notifications'
import { cookies } from 'next/headers'
import { adminAuth } from '@/lib/firebase/admin'

export async function POST(request: NextRequest) {
    try {
        const { donationId, status } = await request.json()

        if (!donationId || !status) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
        }

        // Get admin ID for audit log if possible (though this might be called by system/driver?)
        // Assuming protected route called by authenticated user
        let actorId = 'system'
        try {
            const cookieStore = await cookies()
            const sessionCookie = cookieStore.get('session')
            if (sessionCookie) {
                const decodedToken = await adminAuth.verifySessionCookie(sessionCookie.value)
                actorId = decodedToken.uid
            }
        } catch (e) {
            // Ignore auth error for audit log actor fallback
        }

        // Update donation status
        const donationRef = adminDb.collection('donations').doc(donationId)
        const donationDoc = await donationRef.get()

        if (!donationDoc.exists) {
            return NextResponse.json({ error: 'Donation not found' }, { status: 404 })
        }

        await donationRef.update({
            status,
            updatedAt: new Date(),
        })

        const donationData = donationDoc.data()
        const vendorName = donationData?.vendorName || 'Vendor'
        const title = donationData?.title || 'Donation'

        // Create notifications for status changes
        if (status === 'in-transit') {
            await createNotification({
                type: 'pickup_complete',
                title: 'Pickup Completed',
                message: `${vendorName} donation "${title}" picked up`,
                recipientId: 'admin',
                linkTo: '/dashboard/donations',
                metadata: { donationId, vendorName },
            })

            // Audit Log for Dashboard Activity
            await adminDb.collection('auditLogs').add({
                userId: actorId,
                action: 'Donation Pickup',
                details: `Pickup completed for ${title} from ${vendorName}`,
                category: 'Logistics',
                timestamp: new Date(),
            })

        } else if (status === 'completed') {
            await createNotification({
                type: 'delivery_complete',
                title: 'Delivery Completed',
                message: `Donation "${title}" successfully delivered`,
                recipientId: 'admin',
                linkTo: '/dashboard/donations',
                metadata: { donationId, vendorName },
            })

            // Audit Log
            await adminDb.collection('auditLogs').add({
                userId: actorId,
                action: 'Donation Delivered',
                details: `Donation ${title} delivered successfully`,
                category: 'Logistics',
                timestamp: new Date(),
            })
        }

        return NextResponse.json(
            {
                success: true,
                message: 'Donation status updated',
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Status update error:', error)
        return NextResponse.json({ error: 'Failed to update status' }, { status: 500 })
    }
}
