import { NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase/admin'

export async function GET() {
    try {
        // Fetch all donations from Firestore
        const donationsSnapshot = await adminDb
            .collection('donations')
            .orderBy('createdAt', 'desc')
            .get()

        const donations = donationsSnapshot.docs.map(doc => {
            const data = doc.data()

            // Helper to convert Firestore timestamps to ISO strings
            const serializeTimestamp = (timestamp: any) => {
                if (!timestamp) return null
                if (timestamp._seconds) {
                    return new Date(timestamp._seconds * 1000).toISOString()
                }
                if (timestamp.seconds) {
                    return new Date(timestamp.seconds * 1000).toISOString()
                }
                return timestamp
            }

            // Helper to format Base64 photos with data URI
            const formatPhotos = (photos: any[]) => {
                if (!photos || !Array.isArray(photos)) return []
                return photos.map(photo => {
                    // If already a full URL or data URI, return as-is
                    if (photo.startsWith('http') || photo.startsWith('data:')) {
                        return photo
                    }
                    // Otherwise, assume it's Base64 and add data URI prefix
                    // Default to JPEG, could be improved with MIME detection
                    return `data:image/jpeg;base64,${photo}`
                })
            }

            return {
                id: doc.id,
                title: data.title,
                description: data.description,
                foodType: data.foodType,
                quantity: data.quantity,
                unit: data.unit,
                status: data.status, // 'available', 'pending', 'completed', etc.
                vendorId: data.vendorId,
                vendorName: data.vendorName,
                vendorPhone: null as string | null, // Will be populated below
                pickupAddress: data.pickupAddress,
                pickupWindowStart: serializeTimestamp(data.pickupWindowStart),
                pickupWindowEnd: serializeTimestamp(data.pickupWindowEnd),
                expiryTime: serializeTimestamp(data.expiryTime),
                photos: formatPhotos(data.photos),
                recipientNGO: data.recipientNGO || null,
                containsAllergens: data.containsAllergens || false,
                createdAt: serializeTimestamp(data.createdAt),
                updatedAt: serializeTimestamp(data.updatedAt),
            }
        })

        // Fetch vendor phone numbers
        const vendorIds = [...new Set(donations.map(d => d.vendorId).filter(Boolean))]
        const vendorPhones: Record<string, string | null> = {}

        for (const vendorId of vendorIds) {
            try {
                const userDoc = await adminDb.collection('users').doc(vendorId).get()
                if (userDoc.exists) {
                    const userData = userDoc.data()
                    // Try both 'phone' and 'phoneNumber' to be safe, defaulting to 'phone' based on profile API
                    vendorPhones[vendorId] = userData?.phone || userData?.phoneNumber || null
                }
            } catch (error) {
                console.error(`Failed to fetch vendor ${vendorId}:`, error)
            }
        }

        // Update donations with vendor phone numbers
        donations.forEach(donation => {
            if (donation.vendorId && vendorPhones[donation.vendorId]) {
                donation.vendorPhone = vendorPhones[donation.vendorId]
            }
        })

        return NextResponse.json(
            {
                success: true,
                donations,
            },
            { status: 200 }
        )
    } catch (error: any) {
        console.error('Donations fetch error:', error)

        // Handle missing index error
        if (error.message && error.message.includes('index')) {
            return NextResponse.json(
                {
                    error: 'Database index required. Please create an index for donations collection.',
                    donations: [],
                },
                { status: 200 }
            )
        }

        return NextResponse.json(
            { error: 'Failed to fetch donations', donations: [] },
            { status: 500 }
        )
    }
}
