import { NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'
import * as speakeasy from 'speakeasy'
import * as QRCode from 'qrcode'

export async function POST() {
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

        // Generate secret for 2FA
        const secret = speakeasy.generateSecret({
            name: `NoMoreWaste (${decodedToken.email})`,
            length: 20,
        })

        // Store the temporary secret in Firestore (not enabled yet)
        await adminDb.collection('users').doc(decodedToken.uid).update({
            twoFactorSecret: secret.base32,
            twoFactorEnabled: false,
            updatedAt: new Date(),
        })

        // Generate QR code
        const qrCodeDataURL = await QRCode.toDataURL(secret.otpauth_url || '')

        return NextResponse.json(
            {
                success: true,
                qrCode: qrCodeDataURL,
                secret: secret.base32,
            },
            { status: 200 }
        )
    } catch (error) {
        console.error('2FA setup error:', error)
        return NextResponse.json(
            { error: 'Failed to setup 2FA' },
            { status: 500 }
        )
    }
}
