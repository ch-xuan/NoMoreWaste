// firebase_backend/scripts/promoteAdmin.cjs
const admin = require('firebase-admin');

// ✅ Put your service account here:
const serviceAccount = require('../serviceAccount.json');

// ✅ The UID you want to promote:
const uid = 'sWdJe3tk13NiMjXkOwMzP8pgNTi1';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function promote() {
  // 1️⃣ Add custom claim (this is what middleware checks)
  await admin.auth().setCustomUserClaims(uid, { admin: true });

  // 2️⃣ Update Firestore profile (Role)
  await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .set(
      {
        role: 'admin',
        verificationStatus: 'approved',
        isSuperAdmin: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  console.log('✅ Promoted UID to admin:', uid);
  console.log('ℹ️  Admin claims require re-login (sign out/in) to take effect.');
}

promote().catch((e) => {
  console.error('❌ Promote failed:', e);
  process.exit(1);
});
