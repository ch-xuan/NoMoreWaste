import { NextRequest, NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'

export async function POST(request: NextRequest) {
    try {
        const { uid, displayName, phone } = await request.json()

        if (!uid) {
            return NextResponse.json(
                { error: 'User ID is required' },
                { status: 400 }
            )
        }

        // Prepare update data
        const updateData: any = {
            updatedAt: new Date(),
        }

        if (displayName !== undefined) {
            updateData.displayName = displayName
        }

        if (phone !== undefined) {
            updateData.phone = phone
        }

        // Update user document in Firestore
        await adminDb.collection('users').doc(uid).update(updateData)

        return NextResponse.json(
            {
                success: true,
                message: 'Profile updated successfully',
            },
            { status: 200 }
        )
    } catch (error) {
        console.error('Profile update error:', error)
        return NextResponse.json(
            { error: 'Failed to update profile' },
            { status: 500 }
        )
    }
}
