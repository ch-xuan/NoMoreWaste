import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification.dart';

class VerificationRepository {
  VerificationRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Upload a verification document to subcollection `users/{uid}/verification_docs`
  Future<void> uploadDocument({
    required String uid,
    required String docType,
    required String fileName,
    required String base64,
    required int sizeBytes,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final now = DateTime.now();
      
      print('📤 Uploading document: $docType for user $uid (${sizeBytes} bytes)');
      
      // Changed to use users subcollection as requested
      await _db
          .collection('users')
          .doc(uid)
          .collection('verification_docs')
          .doc(docType)
          .set({
        'docType': docType,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'base64': base64,
        'sha256': null,
        'uploadedAt': now.toIso8601String(),
        'uploadedBy': uid,
      });
      
      print('✅ Subcollection write success');

      /* 
      // TEMPORARILY DISABLED TO DEBUG PERMISSIONS
      // This is redundant for initial signup anyway as status is already pending
      await _db.collection('users').doc(uid).update({
        'verificationStatus': 'pending', 
        'updatedAt': now.toIso8601String(),
      });
      */
      
      print('✅ Document uploaded successfully: users/$uid/verification_docs/$docType');
    } catch (e) {
      print('❌ Error uploading document: $e');
      rethrow;
    }
  }

  /// Get verification status from User profile (simplified)
  Future<Verification?> getVerification(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    
    // meaningful fields from user doc
    return Verification(
      uid: uid,
      role: data['role'] ?? 'unknown',
      status: data['verificationStatus'] ?? 'pending',
      reviewedBy: null, // would need to store this in user doc if needed
      reviewedAt: null,
      reviewNote: data['verificationReason'],
      createdAt: DateTime.parse(data['createdAt']?.toDate().toString() ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(data['updatedAt']?.toDate().toString() ?? DateTime.now().toString()),
    );
  }

  /// Get all verification documents for a user
  Future<List<VerificationDoc>> getDocuments(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('verification_docs')
        .get();

    return snapshot.docs.map((doc) => VerificationDoc.fromJson(doc.data())).toList();
  }

  /// Admin: Update verification status (updates User doc directly)
  Future<void> updateVerificationStatus({
    required String uid,
    required String status,
    required String adminUid,
    String? reviewNote,
  }) async {
    // Update user's verification status
    await _db.collection('users').doc(uid).update({
      'verificationStatus': status,
      'verificationReason': reviewNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
