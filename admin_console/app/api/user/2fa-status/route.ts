import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function GET(request: NextRequest) {
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

        // Check if 2FA is enabled for this user
        const userDoc = await adminDb.collection('users').doc(decodedToken.uid).get()
        const userData = userDoc.data()

        return NextResponse.json(
            {
                success: true,
                enabled: userData?.twoFactorEnabled || false,
            },
            { status: 200 }
        )
    } catch (error) {
        console.error('2FA status check error:', error)
        return NextResponse.json(
            { error: 'Failed to check 2FA status' },
            { status: 500 }
        )
    }
}
