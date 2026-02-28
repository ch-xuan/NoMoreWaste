import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function POST(request: NextRequest) {
    try {
        // Get session cookie
        const cookieStore = await cookies()
        const sessionCookie = cookieStore.get('session')

        if (!sessionCookie) {
            return NextResponse.json(
                { error: 'Not authenticated' },
                { status: 401 }
            )
        }

        // Verify session cookie
        const decodedToken = await adminAuth.verifySessionCookie(sessionCookie.value)

        const { currentPassword, newPassword } = await request.json()

        if (!currentPassword || !newPassword) {
            return NextResponse.json(
                { error: 'Current password and new password are required' },
                { status: 400 }
            )
        }

        if (newPassword.length < 6) {
            return NextResponse.json(
                { error: 'New password must be at least 6 characters' },
                { status: 400 }
            )
        }

        // Get user email from Firestore
        const userDoc = await adminDb.collection('users').doc(decodedToken.uid).get()
        const userData = userDoc.data()

        if (!userData || !userData.email) {
            return NextResponse.json(
                { error: 'User not found' },
                { status: 404 }
            )
        }

        // This is a server-side operation, so we need to use Admin SDK
        // Update the password using Admin SDK
        await adminAuth.updateUser(decodedToken.uid, {
            password: newPassword,
        })

        // Log activity
        await adminDb.collection('auditLogs').add({
            userId: decodedToken.uid,
            action: 'Password changed',
            category: 'User management',
            details: 'User changed their password',
            timestamp: new Date(),
        })

        return NextResponse.json(
            {
                success: true,
                message: 'Password changed successfully',
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Password change error:', error)
        return NextResponse.json(
            { error: error.message || 'Failed to change password' },
            { status: 500 }
        )
    }
}
