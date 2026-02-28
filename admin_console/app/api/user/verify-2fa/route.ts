import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'
import * as speakeasy from 'speakeasy'

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

        const { code } = await request.json()

        if (!code) {
            return NextResponse.json(
                { error: 'Verification code is required' },
                { status: 400 }
            )
        }

        // Get user's temporary secret
        const userDoc = await adminDb.collection('users').doc(decodedToken.uid).get()
        const userData = userDoc.data()

        if (!userData || !userData.twoFactorSecret) {
            return NextResponse.json(
                { error: '2FA setup not initiated' },
                { status: 400 }
            )
        }

        // Verify the code using speakeasy
        const verified = speakeasy.totp.verify({
            secret: userData.twoFactorSecret,
            encoding: 'base32',
            token: code,
            window: 2, // Allow 2 time steps before/after
        })

        if (!verified) {
            return NextResponse.json(
                { error: 'Invalid verification code' },
                { status: 400 }
            )
        }

        // Enable 2FA for the user
        await adminDb.collection('users').doc(decodedToken.uid).update({
            twoFactorEnabled: true,
            updatedAt: new Date(),
        })

        // Log activity
        await adminDb.collection('auditLogs').add({
            userId: decodedToken.uid,
            action: '2FA enabled',
            details: 'User enabled two-factor authentication',
            timestamp: new Date(),
        })

        return NextResponse.json(
            {
                success: true,
                message: '2FA enabled successfully',
            },
            { status: 200 }
        )
    } catch (error) {
        console.error('2FA verification error:', error)
        return NextResponse.json(
            { error: 'Failed to verify 2FA code' },
            { status: 500 }
        )
    }
}
