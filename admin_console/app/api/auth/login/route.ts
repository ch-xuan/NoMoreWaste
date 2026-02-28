import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function POST(request: NextRequest) {
    try {
        const { idToken } = await request.json()

        if (!idToken) {
            return NextResponse.json(
                { error: 'ID token is required' },
                { status: 400 }
            )
        }

        // Verify the ID token first
        const decodedToken = await adminAuth.verifyIdToken(idToken)

        // Fetch user data from Firestore to check role and verification status
        const userDoc = await adminDb.collection('users').doc(decodedToken.uid).get()

        if (!userDoc.exists) {
            return NextResponse.json(
                { error: 'User not found in database' },
                { status: 404 }
            )
        }

        const userData = userDoc.data()

        // Check if user has admin role and is verified
        if (userData?.role !== 'admin') {
            return NextResponse.json(
                { error: 'Unauthorized: Admin access required' },
                { status: 403 }
            )
        }

        // Check verification status
        if (userData?.verificationStatus !== 'approved') {
            return NextResponse.json(
                { error: 'Account pending verification. Please contact an administrator.' },
                { status: 403 }
            )
        }

        // Create session cookie (expires in 5 days)
        const expiresIn = 60 * 60 * 24 * 5 * 1000 // 5 days
        const sessionCookie = await adminAuth.createSessionCookie(idToken, {
            expiresIn,
        })

        // Set cookie
        const cookieStore = await cookies()
        cookieStore.set('session', sessionCookie, {
            maxAge: expiresIn,
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            path: '/',
            sameSite: 'lax',
        })

        return NextResponse.json(
            {
                success: true,
                user: {
                    uid: decodedToken.uid,
                    email: decodedToken.email,
                    displayName: userData?.displayName,
                    role: userData?.role,
                    isSuperAdmin: userData?.isSuperAdmin || false,
                },
            },
            { status: 200 }
        )
    } catch (error) {
        console.error('Login error:', error)
        return NextResponse.json(
            { error: 'Authentication failed' },
            { status: 401 }
        )
    }
}
