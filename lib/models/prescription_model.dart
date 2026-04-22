// models/prescription_model.dart
// Represents an uploaded prescription image

class Prescription {
  final String id;
  final String patientId;
  final String doctorId;        // Doctor who prescribed this
  final String imageUrl;        // Usually "" for zero-cost flow
  final bool imageCaptured;     // Verification flag
  final String uploadedAt;      // ISO date string
  final String? note;
  final List<String> medicines; // Array of medicine names/IDs

  Prescription({
    required this.id,
    required this.patientId,
    this.doctorId = '',
    required this.imageUrl,
    this.imageCaptured = false,
    required this.uploadedAt,
    this.note,
    this.medicines = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'imageUrl': imageUrl,
      'imageCaptured': imageCaptured,
      'uploadedAt': uploadedAt,
      'note': note,
      'medicines': medicines,
    };
  }

  factory Prescription.fromMap(String id, Map<String, dynamic> map) {
    return Prescription(
      id: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageCaptured: map['imageCaptured'] ?? false,
      uploadedAt: map['uploadedAt'] ?? '',
      note: map['note'],
      medicines: List<String>.from(map['medicines'] ?? []),
    );
  }
}