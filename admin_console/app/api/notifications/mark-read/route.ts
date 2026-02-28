import { NextRequest, NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'

export async function POST(request: NextRequest) {
    try {
        const { notificationIds } = await request.json()

        if (!notificationIds || !Array.isArray(notificationIds)) {
            return NextResponse.json(
                { error: 'Invalid notification IDs' },
                { status: 400 }
            )
        }

        // Update all specified notifications to isRead: true
        const batch = adminDb.batch()

        for (const id of notificationIds) {
            const notificationRef = adminDb.collection('notifications').doc(id)
            batch.update(notificationRef, { isRead: true })
        }

        await batch.commit()

        return NextResponse.json(
            {
                success: true,
                message: `${notificationIds.length} notification(s) marked as read`,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Mark as read error:', error)
        return NextResponse.json(
            { error: 'Failed to mark notifications as read' },
            { status: 500 }
        )
    }
}
