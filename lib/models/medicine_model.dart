// models/medicine_model.dart
// Represents a single medicine entry stored in Firestore under patients/{patientId}/medicines

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final List<String> timings; // e.g., ["08:00 AM", "08:00 PM"]
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timings,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'timings': timings,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory Medicine.fromMap(String id, Map<String, dynamic> map) {
    return Medicine(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      timings: List<String>.from(map['timings'] ?? []),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now().add(const Duration(days: 30)),
      imageUrl: map['imageUrl'],
    );
  }
}