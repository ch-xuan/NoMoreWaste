import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'

export async function GET(request: NextRequest) {
    try {
        const sessionCookie = request.cookies.get('session')?.value
        if (!sessionCookie) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
        }

        const decodedToken = await adminAuth.verifySessionCookie(sessionCookie)
        const uid = decodedToken.uid

        const userDoc = await adminDb.collection('users').doc(uid).get()
        if (!userDoc.exists) {
            return NextResponse.json({ error: 'User not found' }, { status: 404 })
        }

        return NextResponse.json({ user: { id: userDoc.id, ...userDoc.data() } }, { status: 200 })
    } catch (error: any) {
        console.error('Error fetching user profile:', error)
        return NextResponse.json({ error: error.message }, { status: 500 })
    }
}
