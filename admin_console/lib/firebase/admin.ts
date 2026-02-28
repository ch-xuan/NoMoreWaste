import * as admin from 'firebase-admin'

/**
 * Initialize Firebase Admin SDK
 * Uses singleton pattern to prevent multiple initializations
 */
function initializeFirebaseAdmin() {
    if (admin.apps.length > 0) {
        return admin.app()
    }

    // Try loading from serviceAccount.json if it exists (Development helper)
    try {
        const serviceAccount = require('../../serviceAccount.json')
        if (serviceAccount.project_id) {
            console.log('[Firebase Admin] Loaded credentials from serviceAccount.json')
            return admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            })
        }
    } catch (e) {
        // Ignore if file doesn't exist or is invalid, fall back to Env Vars
    }

    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')

    if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !privateKey) {
        throw new Error(
            'Missing Firebase Admin SDK environment variables. Please check .env.local'
        )
    }

    // DEBUG: Check key format
    if (privateKey) {
        console.log('[Firebase Admin] Private Key Length:', privateKey.length)
        console.log('[Firebase Admin] Using Env Vars')
    }

    return admin.initializeApp({
        credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey,
        }),
    })
}

// Initialize Firebase Admin
const app = initializeFirebaseAdmin()

// Export commonly used services
export const adminAuth = admin.auth(app)
export const adminDb = admin.firestore(app)
export const adminStorage = admin.storage(app)

// Export the app instance
export default app
