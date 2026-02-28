import { NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function GET() {
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

        // Fetch activity logs for this user from audit logs collection
        const logsSnapshot = await adminDb
            .collection('auditLogs')
            .where('userId', '==', decodedToken.uid)
            .get()

        const logs = logsSnapshot.docs.map(doc => {
            const data = doc.data()
            return {
                id: doc.id,
                userId: data.userId,
                action: data.action,
                details: data.details,
                timestamp: data.timestamp,
                ipAddress: data.ipAddress,
                userAgent: data.userAgent,
            }
        }).sort((a, b) => {
            // Handle various timestamp formats
            const getTime = (t: any) => {
                if (!t) return 0
                if (t._seconds) return t._seconds * 1000
                if (t.seconds) return t.seconds * 1000
                return new Date(t).getTime()
            }
            return getTime(b.timestamp) - getTime(a.timestamp)
        })

        return NextResponse.json(
            {
                success: true,
                logs,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Activity logs fetch error:', error)

        // If the error is about missing index, provide helpful message
        if (error.message && error.message.includes('index')) {
            return NextResponse.json(
                {
                    error: 'Database index required. Please create a composite index for auditLogs collection.',
                    logs: [],
                },
                { status: 200 }
            )
        }

        return NextResponse.json(
            { error: 'Failed to fetch activity logs', logs: [] },
            { status: 500 }
        )
    }
}
