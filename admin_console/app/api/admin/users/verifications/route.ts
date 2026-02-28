import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'

export async function GET(request: NextRequest) {
    try {
        const sessionCookie = request.cookies.get('session')?.value
        if (!sessionCookie) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
        }

        const decodedToken = await adminAuth.verifySessionCookie(sessionCookie)
        // Check admin logic if needed

        const { searchParams } = new URL(request.url)
        const status = searchParams.get('status') || 'pending'

        const snapshot = await adminDb.collection('users')
            .where('verificationStatus', '==', status)
            .get()

        const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))

        return NextResponse.json({ users }, { status: 200 })
    } catch (error: any) {
        console.error('Error fetching verifications:', error)
        return NextResponse.json({ error: error.message }, { status: 500 })
    }
}
