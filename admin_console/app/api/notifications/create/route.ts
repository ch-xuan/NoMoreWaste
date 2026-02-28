import { NextRequest, NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'

export async function POST(request: NextRequest) {
    try {
        const { recipientId, senderId, type, title, message, entityId } = await request.json()

        if (!recipientId || !title || !message || !type) {
            return NextResponse.json(
                { error: 'Missing required fields' },
                { status: 400 }
            )
        }

        // Create notification in main collection
        const notificationRef = adminDb.collection('notifications').doc()
        await notificationRef.set({
            id: notificationRef.id,
            recipientId,
            senderId: senderId || 'system',
            title,
            message,
            type,
            entityId: entityId || null,
            isRead: false,
            createdAt: new Date(),
        })

        return NextResponse.json(
            {
                success: true,
                notificationId: notificationRef.id,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Create notification error:', error)
        return NextResponse.json(
            { error: 'Failed to create notification' },
            { status: 500 }
        )
    }
}
