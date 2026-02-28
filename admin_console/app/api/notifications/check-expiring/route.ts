import { NextRequest, NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'
import { createNotification } from '@/lib/notifications'

export async function POST(request: NextRequest) {
    try {
        // Fetch all donations that expire within 24 hours
        const now = new Date()
        const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000)

        const donationsSnapshot = await adminDb
            .collection('donations')
            .where('status', '==', 'available')
            .get()

        let notificationsCreated = 0

        for (const doc of donationsSnapshot.docs) {
            const data = doc.data()

            if (data.expiryTime) {
                let expiryDate: Date

                // Handle Firestore timestamp
                if (data.expiryTime._seconds) {
                    expiryDate = new Date(data.expiryTime._seconds * 1000)
                } else if (data.expiryTime.seconds) {
                    expiryDate = new Date(data.expiryTime.seconds * 1000)
                } else {
                    expiryDate = new Date(data.expiryTime)
                }

                // Check if expiring within 24 hours
                if (expiryDate > now && expiryDate <= tomorrow) {
                    const hoursRemaining = Math.floor((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60))

                    await createNotification({
                        type: 'donation_expiring',
                        title: 'Donation Expiring Soon',
                        message: `"${data.title}" from ${data.vendorName} expires in ${hoursRemaining} hour${hoursRemaining > 1 ? 's' : ''}`,
                        linkTo: '/dashboard/donations',
                        metadata: {
                            donationId: doc.id,
                            expiryTime: expiryDate.toISOString(),
                            hoursRemaining,
                        },
                    })

                    notificationsCreated++
                }
            }
        }

        return NextResponse.json(
            {
                success: true,
                message: `Created ${notificationsCreated} expiring donation notifications`,
                count: notificationsCreated,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Check expiring donations error:', error)
        return NextResponse.json(
            { error: 'Failed to check expiring donations' },
            { status: 500 }
        )
    }
}
