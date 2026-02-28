/**
 * Script to set custom claims for admin users
 * Run this script once to set admin custom claims for Admin account (Victor)
 * 
 * Run this script*: node scripts/set-admin-claims.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (admin.apps.length === 0) {
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !privateKey) {
        console.error('❌ Missing Firebase Admin SDK environment variables');
        console.error('Please check your .env.local file');
        process.exit(1);
    }

    admin.initializeApp({
        credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey,
        }),
    });
}

/**
 * Set custom claims for a user
 */
async function setAdminClaims(uid, isSuperAdmin = false) {
    try {
        // Set custom claims
        await admin.auth().setCustomUserClaims(uid, {
            role: 'admin',
            isSuperAdmin: isSuperAdmin,
        });

        console.log(`✅ Successfully set admin claims for user: ${uid}`);
        console.log(`   - Role: admin`);
        console.log(`   - Super Admin: ${isSuperAdmin}`);

        // Verify the claims were set
        const user = await admin.auth().getUser(uid);
        console.log(`\n📋 Current custom claims:`, user.customClaims);

        return true;
    } catch (error) {
        console.error('❌ Error setting custom claims:', error);
        return false;
    }
}

// Victor's UID from your Firestore data
const VICTOR_UID = 'sWdJe3tk13NiMjXkOwMzP8pgNTi1';

// Run the script
(async () => {
    console.log('🔧 Setting admin custom claims for Victor...\n');

    const success = await setAdminClaims(VICTOR_UID, true);

    if (success) {
        console.log('\n✨ Done! Victor can now login to the admin dashboard.');
        console.log('⚠️  Note: Victor may need to logout and login again for changes to take effect.');
    }

    process.exit(success ? 0 : 1);
})();
