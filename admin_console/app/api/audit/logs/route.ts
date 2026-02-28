import { NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'

export async function GET() {
    try {
        // Fetch all audit logs
        const logsSnapshot = await adminDb
            .collection('auditLogs')
            .orderBy('timestamp', 'desc')
            .limit(50)
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
                category: data.category,
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

        // Handle missing index error
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
            { error: 'Failed to fetch audit logs', logs: [] },
            { status: 500 }
        )
    }
}
