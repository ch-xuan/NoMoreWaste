import { NextRequest, NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'

export async function POST(request: NextRequest) {
    try {
        const notifications = [
            {
                recipientId: 'admin',
                senderId: 'system',
                type: 'delivery_complete',
                title: 'Delivery Completed',
                message: 'Donation "Fresh Breads" successfully delivered to Hope Foundation',
                isRead: false,
                createdAt: new Date(),
                metadata: { mock: true }
            },
            {
                recipientId: 'admin',
                senderId: 'system',
                type: 'pickup_complete',
                title: 'Pickup Completed',
                message: 'Driver collected "Vegetable Box" from Mega Mart',
                isRead: false,
                createdAt: new Date(Date.now() - 1000 * 60 * 30), // 30 mins ago
                metadata: { mock: true }
            },
            {
                recipientId: 'admin',
                senderId: 'system',
                type: 'expiring_soon',
                title: 'Donation Expiring Soon',
                message: '"Milk & Dairy" from City Grocer expires in 2 hours',
                isRead: false,
                createdAt: new Date(Date.now() - 1000 * 60 * 60), // 1 hour ago
                metadata: { mock: true }
            },
            {
                recipientId: 'admin',
                senderId: 'system',
                type: 'new_report',
                title: 'New Report Available',
                message: 'Monthly Impact Report (PDF) is ready for download',
                isRead: false,
                createdAt: new Date(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
                metadata: { mock: true }
            }
        ]

        const batch = adminDb.batch()

        for (const notif of notifications) {
            const ref = adminDb.collection('notifications').doc()
            batch.set(ref, { id: ref.id, ...notif })
        }

        await batch.commit()

        return NextResponse.json({ success: true, message: 'Seeded test notifications' })
    } catch (error) {
        return NextResponse.json({ error: 'Failed to seed' }, { status: 500 })
    }
}
