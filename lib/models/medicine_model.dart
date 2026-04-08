// models/medicine_model.dart
// Represents a single medicine entry stored in Firestore

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> timeSchedule; // e.g. ["morning", "night"]
  final String? imageUrl;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timeSchedule,
    this.imageUrl,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timeSchedule': timeSchedule,
      'imageUrl': imageUrl,
    };
  }

  // Create from Firestore document
  factory Medicine.fromMap(String id, Map<String, dynamic> map) {
    return Medicine(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      timeSchedule: List<String>.from(map['timeSchedule'] ?? []),
      imageUrl: map['imageUrl'],
    );
  }
}