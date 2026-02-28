import { NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

// Force dynamic to prevent caching issues
export const dynamic = 'force-dynamic'

export async function GET() {
    console.log('[API] /api/tasks/list called')

    try {
        // 1. Check Cookies
        const cookieStore = await cookies()
        const sessionCookie = cookieStore.get('session')

        if (!sessionCookie) {
            console.warn('[API] No session cookie found')
            return NextResponse.json(
                { success: false, message: 'Unauthorized - No session cookie' },
                { status: 401 }
            )
        }

        // 2. Verify Session
        let userId = ''
        try {
            const decodedClaims = await adminAuth.verifySessionCookie(sessionCookie.value, true)
            userId = decodedClaims.uid
        } catch (authError: any) {
            console.error('[API] Session verification failed:', authError)
            return NextResponse.json(
                { success: false, message: 'Invalid session', error: authError.message },
                { status: 401 }
            )
        }

        // 3. Check DB Connection & Query
        let tasksSnapshot
        try {
            tasksSnapshot = await adminDb
                .collection('tasks')
                .orderBy('createdAt', 'desc')
                .limit(50)
                .get()
        } catch (dbError: any) {
            console.warn('[API] Firestore query failed (trying fallback):', dbError)
            // Fallback to unordered query
            try {
                tasksSnapshot = await adminDb
                    .collection('tasks')
                    .limit(50)
                    .get()
            } catch (fallbackError: any) {
                console.error('[API] Fallback query failed:', fallbackError)
                throw new Error(`Firestore query failed: ${dbError.message} | Fallback: ${fallbackError.message}`)
            }
        }

        // 4. Map Documents safely
        const tasks = tasksSnapshot.docs.map((doc) => {
            const data = doc.data()
            try {
                return {
                    id: doc.id,
                    ...data,
                    // Safe timestamp conversion
                    createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
                    acceptedAt: data.acceptedAt?.toDate?.()?.toISOString() || undefined,
                    pickedUpAt: data.pickedUpAt?.toDate?.()?.toISOString() || undefined,
                    deliveredAt: data.deliveredAt?.toDate?.()?.toISOString() || undefined,
                    completedAt: data.completedAt?.toDate?.()?.toISOString() || undefined,
                    updatedAt: data.updatedAt?.toDate?.()?.toISOString() || undefined,
                }
            } catch (mapErr: any) {
                console.error(`[API] Error mapping doc ${doc.id}:`, mapErr)
                // Return a safe fallback for this specific doc instead of crashing the whole request
                return {
                    id: doc.id,
                    ...data,
                    error: 'Mapping error',
                    createdAt: new Date().toISOString()
                }
            }
        })

        return NextResponse.json({
            success: true,
            tasks,
        })

    } catch (error: any) {
        console.error('[API] CRITICAL ERROR:', error)
        return NextResponse.json(
            {
                success: false,
                message: 'Internal Server Error',
                error: error.message,
                stack: error.stack
            },
            { status: 500 }
        )
    }
}
