import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function POST(request: NextRequest) {
    try {
        // Verify authentication
        const cookieStore = await cookies()
        const sessionCookie = cookieStore.get('session')

        if (!sessionCookie) {
            return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
        }

        const decodedToken = await adminAuth.verifySessionCookie(sessionCookie.value)
        const moderatorId = decodedToken.uid

        // Parse request body
        const { action, donationId, reason } = await request.json()

        if (!action || !donationId) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
        }

        // Validate action type
        if (!['remove', 'warn', 'dismiss'].includes(action)) {
            return NextResponse.json({ error: 'Invalid action type' }, { status: 400 })
        }

        // Get donation details for logging
        const donationRef = adminDb.collection('donations').doc(donationId)
        const donationDoc = await donationRef.get()

        if (!donationDoc.exists) {
            return NextResponse.json({ error: 'Donation not found' }, { status: 404 })
        }

        const donationData = donationDoc.data()
        const vendorId = donationData?.vendorId

        let auditAction = ''
        let auditDetails = ''

        switch (action) {
            case 'remove':
                // Delete the donation
                await donationRef.delete()
                auditAction = 'Content removed'
                auditDetails = `Removed donation "${donationData?.title}" (ID: ${donationId}) from vendor ${donationData?.vendorName}`
                break

            case 'warn':
                // Create warning in user's warnings subcollection
                if (vendorId) {
                    await adminDb
                        .collection('users')
                        .doc(vendorId)
                        .collection('warnings')
                        .add({
                            donationId,
                            donationTitle: donationData?.title,
                            reason: reason || 'Content policy violation',
                            moderatorId,
                            timestamp: new Date(),
                        })
                }
                auditAction = 'User warned'
                auditDetails = `Warned vendor ${donationData?.vendorName} for donation "${donationData?.title}" (ID: ${donationId}). Reason: ${reason || 'Content policy violation'}`
                break

            case 'dismiss':
                // Mark donation as approved
                await donationRef.update({
                    moderationStatus: 'approved',
                    moderatedBy: moderatorId,
                    moderatedAt: new Date(),
                })
                auditAction = 'Moderation dismissed'
                auditDetails = `Dismissed moderation for donation "${donationData?.title}" (ID: ${donationId}) - marked as approved`
                break
        }

        // Create audit log
        await adminDb.collection('auditLogs').add({
            userId: moderatorId,
            action: auditAction,
            details: auditDetails,
            category: 'Moderation',
            timestamp: new Date(),
            ipAddress: request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown',
            userAgent: request.headers.get('user-agent') || 'unknown',
        })

        return NextResponse.json(
            {
                success: true,
                message: `${action} action completed successfully`,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Moderation action error:', error)
        return NextResponse.json({ error: 'Failed to perform moderation action' }, { status: 500 })
    }
}
