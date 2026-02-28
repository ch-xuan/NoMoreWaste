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

        // Get JSON data
        const data = await request.json()
        const { photoBase64, uid } = data

        if (!photoBase64) {
            return NextResponse.json(
                { error: 'No photo provided' },
                { status: 400 }
            )
        }

        // Verify user is updating their own profile
        if (decodedToken.uid !== uid) {
            return NextResponse.json(
                { error: 'Unauthorized' },
                { status: 403 }
            )
        }

        // Basic validation for base64 string
        if (!photoBase64.startsWith('data:image/')) {
            return NextResponse.json(
                { error: 'Invalid image format' },
                { status: 400 }
            )
        }

        // Check approximate size (base64 is ~1.33x larger than binary)
        // Limit to ~750KB binary equivalent -> ~1MB base64
        if (photoBase64.length > 1024 * 1024) {
            return NextResponse.json(
                { error: 'Image too large. Please resize to under 750KB.' },
                { status: 400 }
            )
        }

        // Update user document in Firestore directly with Base64 string
        // Note: Firestore has a 1MB limit per document. 
        // Storing images in Firestore is not recommended for production but requested by user.
        await adminDb.collection('users').doc(uid).update({
            photoURL: photoBase64,
            updatedAt: new Date(),
        })

        // Log activity
        await adminDb.collection('auditLogs').add({
            userId: uid,
            action: 'Profile photo updated',
            category: 'User management',
            details: 'User uploaded a new profile picture',
            timestamp: new Date(),
            ipAddress: request.headers.get('x-forwarded-for') || 'unknown',
            userAgent: request.headers.get('user-agent') || 'unknown',
        })

        return NextResponse.json(
            {
                success: true,
                photoURL: photoBase64,
                message: 'Photo uploaded successfully',
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Photo upload error:', error)
        return NextResponse.json(
            { error: error.message || 'Failed to upload photo' },
            { status: 500 }
        )
    }
}
