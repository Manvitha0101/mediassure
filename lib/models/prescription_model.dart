// models/prescription_model.dart
// Represents an uploaded prescription image

class Prescription {
  final String id;
  final String patientId;
  final String imageUrl;        // Usually "" for zero-cost flow
  final bool imageCaptured;     // Verification flag
  final String uploadedAt;      // ISO date string
  final String? note;

  Prescription({
    required this.id,
    required this.patientId,
    required this.imageUrl,
    this.imageCaptured = false,
    required this.uploadedAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'imageUrl': imageUrl,
      'imageCaptured': imageCaptured,
      'uploadedAt': uploadedAt,
      'note': note,
    };
  }

  factory Prescription.fromMap(String id, Map<String, dynamic> map) {
    return Prescription(
      id: id,
      patientId: map['patientId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageCaptured: map['imageCaptured'] ?? false,
      uploadedAt: map['uploadedAt'] ?? '',
      note: map['note'],
    );
  }
}