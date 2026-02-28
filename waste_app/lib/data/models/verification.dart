class VerificationDoc {
  final String docType; // business_license | ngo_cert | volunteer_id
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String base64;
  final String? sha256;
  final DateTime uploadedAt;
  final String uploadedBy;

  VerificationDoc({
    required this.docType,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.base64,
    this.sha256,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toJson() => {
    'docType': docType,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'base64': base64,
    'sha256': sha256,
    'uploadedAt': uploadedAt.toIso8601String(),
    'uploadedBy': uploadedBy,
  };

  factory VerificationDoc.fromJson(Map<String, dynamic> json) {
    return VerificationDoc(
      docType: json['docType'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      base64: json['base64'] as String,
      sha256: json['sha256'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      uploadedBy: json['uploadedBy'] as String,
    );
  }
}

class Verification {
  final String uid;
  final String role;
  final String status; // pending | approved | rejected
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Verification({
    required this.uid,
    required this.role,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'role': role,
    'status': status,
    'reviewedBy': reviewedBy,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewNote': reviewNote,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(
      uid: json['uid'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
      reviewNote: json['reviewNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
