import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/lib/firebase/admin'
import { cookies } from 'next/headers'

export async function GET(request: NextRequest) {
    try {
        // Verify admin authentication
        const cookieStore = await cookies()
        const sessionCookie = cookieStore.get('session')

        if (!sessionCookie) {
            return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
        }

        await adminAuth.verifySessionCookie(sessionCookie.value)

        // Fetch recent audit logs (limit 20)
        // We want global logs for the dashboard
        const logsSnapshot = await adminDb
            .collection('auditLogs')
            .orderBy('timestamp', 'desc')
            .limit(20)
            .get()

        const logs = logsSnapshot.docs.map(doc => {
            const data = doc.data()

            // Helper to handle timestamps
            const getTimestamp = (t: any) => {
                if (!t) return new Date().toISOString()
                if (t._seconds) return new Date(t._seconds * 1000).toISOString()
                if (t.seconds) return new Date(t.seconds * 1000).toISOString()
                if (t.toDate) return t.toDate().toISOString()
                return new Date(t).toISOString()
            }

            return {
                id: doc.id,
                action: data.action,
                details: data.details,
                category: data.category || 'System',
                timestamp: getTimestamp(data.timestamp),
                userId: data.userId,
                userName: data.userName || 'Unknown', // Ideally we'd store this or fetch it
            }
        })

        return NextResponse.json(
            {
                success: true,
                logs,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Audit logs fetch error:', error)

        // Handle index errors gracefully
        if (error.message && error.message.includes('index')) {
            return NextResponse.json(
                {
                    error: 'Database index required',
                    logs: [],
                },
                { status: 200 }
            )
        }

        return NextResponse.json(
            { error: 'Failed to fetch audit logs' },
            { status: 500 }
        )
    }
}
