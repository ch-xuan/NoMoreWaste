import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function POST(request: NextRequest) {
    try {
        // Verify admin authentication
        const cookieStore = await cookies()
        const sessionCookie = cookieStore.get('session')

        if (!sessionCookie) {
            return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
        }

        const decodedToken = await adminAuth.verifySessionCookie(sessionCookie.value)
        const adminId = decodedToken.uid

        // Parse request body
        const { userId, action, reason } = await request.json()

        if (!userId || !action) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
        }

        if (!['approve', 'reject'].includes(action)) {
            return NextResponse.json({ error: 'Invalid action' }, { status: 400 })
        }

        // Get user data
        const userRef = adminDb.collection('users').doc(userId)
        const userDoc = await userRef.get()

        if (!userDoc.exists) {
            return NextResponse.json({ error: 'User not found' }, { status: 404 })
        }

        const userData = userDoc.data()

        if (action === 'approve') {
            // Update user verification status
            await userRef.update({
                verificationStatus: 'approved',
                verifiedBy: adminId,
                verifiedAt: new Date(),
            })

            // Create notification in main notifications collection with ID and ID field
            const notificationRef = adminDb.collection('notifications').doc()
            await notificationRef.set({
                id: notificationRef.id,
                recipientId: userId,
                recipientEmail: userData?.email || '',
                senderId: 'admin',
                title: 'Account Verified',
                message: 'Your account has been successfully verified! You can now access all features.',
                type: 'accountVerified',
                entityId: userId,
                isRead: false,
                createdAt: new Date(),
            })

            // Create audit log
            await adminDb.collection('auditLogs').add({
                userId: adminId,
                action: 'User verification approved',
                details: `Approved verification for ${userData?.displayName || userData?.email} (UID: ${userId})`,
                category: 'Verification',
                timestamp: new Date(),
                ipAddress: request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown',
                userAgent: request.headers.get('user-agent') || 'unknown',
            })
        } else if (action === 'reject') {
            // Update user verification status
            await userRef.update({
                verificationStatus: 'rejected',
                rejectedBy: adminId,
                rejectedAt: new Date(),
                rejectionReason: reason || 'Verification documents do not meet requirements',
            })

            // Create notification in main notifications collection with ID and ID field
            const notificationRef = adminDb.collection('notifications').doc()
            await notificationRef.set({
                id: notificationRef.id,
                recipientId: userId,
                recipientEmail: userData?.email || '',
                senderId: 'admin',
                title: 'Verification Rejected, Update Required',
                message: 'We were unable to verify your account with the current documentation. Please review and update your submitted documents, then contact our support team for assistance with the verification process.',
                type: 'accountRejected',
                entityId: userId,
                isRead: false,
                createdAt: new Date(),
            })

            // Create audit log
            await adminDb.collection('auditLogs').add({
                userId: adminId,
                action: 'User verification rejected',
                details: `Rejected verification for ${userData?.displayName || userData?.email} (UID: ${userId}). Reason: ${reason || 'Documentation issues'}`,
                category: 'Verification',
                timestamp: new Date(),
                ipAddress: request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown',
                userAgent: request.headers.get('user-agent') || 'unknown',
            })
        }

        return NextResponse.json(
            {
                success: true,
                message: `User verification ${action === 'approve' ? 'approved' : 'rejected'} successfully`,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Verification action error:', error)
        return NextResponse.json({ error: 'Failed to process verification' }, { status: 500 })
    }
}
