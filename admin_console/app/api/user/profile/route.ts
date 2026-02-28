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

        // Fetch user data from Firestore
        const userDoc = await adminDb.collection('users').doc(decodedToken.uid).get()

        if (!userDoc.exists) {
            return NextResponse.json(
                { error: 'User not found' },
                { status: 404 }
            )
        }

        const userData = userDoc.data()

        return NextResponse.json(
            {
                success: true,
                user: {
                    uid: decodedToken.uid,
                    email: decodedToken.email,
                    displayName: userData?.displayName,
                    phone: userData?.phone,
                    role: userData?.role,
                    isSuperAdmin: userData?.isSuperAdmin || false,
                    photoURL: userData?.photoURL,
                    createdAt: userData?.createdAt,
                    updatedAt: userData?.updatedAt,
                },
            },
            { status: 200 }
        )
    } catch (error) {
        console.error('Fel to fetch profile:', error)
        return NextResponse.json(
            { error: 'Failed to fetch profile' },
            { status: 500 }
        )
    }
}
