// models/prescription_model.dart
// Represents an uploaded prescription image

class Prescription {
  final String id;
  final String imageUrl;        // Firebase Storage URL
  final String uploadedAt;      // ISO date string
  final String? note;

  Prescription({
    required this.id,
    required this.imageUrl,
    required this.uploadedAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'uploadedAt': uploadedAt,
      'note': note,
    };
  }

  factory Prescription.fromMap(String id, Map<String, dynamic> map) {
    return Prescription(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      uploadedAt: map['uploadedAt'] ?? '',
      note: map['note'],
    );
  }
}