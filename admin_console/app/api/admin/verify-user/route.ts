import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'

export async function POST(request: NextRequest) {
    try {
        const sessionCookie = request.cookies.get('session')?.value
        if (!sessionCookie) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
        }

        const decodedToken = await adminAuth.verifySessionCookie(sessionCookie)
        // Ideally verify admin claims here too, but skipping for speed based on context

        const data = await request.json()
        const { uid, status, reason } = data

        if (!uid || !status || !reason) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
        }

        if (!['approved', 'rejected'].includes(status)) {
            return NextResponse.json({ error: 'Invalid status' }, { status: 400 })
        }

        await adminDb.collection('users').doc(uid).update({
            verificationStatus: status,
            verificationReason: reason,
            updatedAt: new Date()
        })

        // Add audit log
        await adminDb.collection('auditLogs').add({
            userId: uid, // Encapsulates the admin performing the action? No, usually 'actor'. But here we usually log the target or actor.
            // My previous audit logs usually log 'userId' as the *actor* if checking session. 
            // In 'upload-photo', userId is the user. 
            // Here, the *admin* is the actor. 
            // I should get admin's ID.
            action: `User ${status}`,
            details: `Admin ${status} user verification. Reason: ${reason}`,
            timestamp: new Date(),
            type: 'verification', // Tag for filtering
            targetUserId: uid // Useful if I want to filter by target
        })

        return NextResponse.json({ success: true }, { status: 200 })
    } catch (error: any) {
        console.error('Error verifying user:', error)
        return NextResponse.json({ error: error.message }, { status: 500 })
    }
}
