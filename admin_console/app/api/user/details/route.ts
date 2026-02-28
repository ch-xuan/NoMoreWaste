import { NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function GET(request: Request) {
    try {
        // Get session cookie
        const cookieStore = await cookies()
        const sessionCookie = cookieStore.get('session')

        if (!sessionCookie) {
            return NextResponse.json(
                { success: false, message: 'Unauthorized' },
                { status: 401 }
            )
        }

        // Verify session
        await adminAuth.verifySessionCookie(sessionCookie.value, true)

        // Get user ID from query params
        const { searchParams } = new URL(request.url)
        const userId = searchParams.get('userId')

        if (!userId) {
            return NextResponse.json(
                { success: false, message: 'User ID is required' },
                { status: 400 }
            )
        }

        // Fetch user details from Firestore
        const userDoc = await adminDb.collection('users').doc(userId).get()

        if (!userDoc.exists) {
            return NextResponse.json(
                { success: false, message: 'User not found' },
                { status: 404 }
            )
        }

        const userData = userDoc.data()

        return NextResponse.json({
            success: true,
            user: {
                uid: userId,
                displayName: userData?.displayName || userData?.name || 'Unknown User',
                email: userData?.email || '',
                phoneNumber: userData?.phoneNumber || userData?.phone || '',
                photoURL: userData?.photoURL || '',
                role: userData?.role || 'user',
            },
        })
    } catch (error: any) {
        console.error('Failed to fetch user details:', error)
        return NextResponse.json(
            {
                success: false,
                message: 'Failed to fetch user details',
                error: error.message,
            },
            { status: 500 }
        )
    }
}
