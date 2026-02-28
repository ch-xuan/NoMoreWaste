import { adminDb } from '@/lib/firebase/admin'

/**
 * Helper function to create notifications in the main notifications collection
 * Can be called from any server-side code
 */
export async function createNotification({
    recipientId,
    senderId = 'system',
    type,
    title,
    message,
    entityId,
    linkTo,
    metadata,
}: {
    recipientId: string
    senderId?: string
    type: string
    title: string
    message: string
    entityId?: string
    linkTo?: string
    metadata?: Record<string, any>
}) {
    try {
        const notificationRef = adminDb.collection('notifications').doc()
        await notificationRef.set({
            id: notificationRef.id,
            recipientId,
            senderId,
            title,
            message,
            type,
            entityId: entityId || null,
            linkTo: linkTo || null,
            metadata: metadata || null,
            isRead: false,
            createdAt: new Date(),
        })
        console.log(`Notification created for user ${recipientId}: ${title}`)
    } catch (error) {
        console.error('Failed to create notification:', error)
        // Don't throw - notifications should never break the main flow
    }
}
