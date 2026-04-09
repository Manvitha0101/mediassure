// models/patient_model.dart

class PatientModel {
  final String patientId;
  final String name;
  final int age;
  final List<String> assignedDoctorIds;
  final List<String> assignedCaretakerIds;

  PatientModel({
    required this.patientId,
    required this.name,
    required this.age,
    this.assignedDoctorIds = const [],
    this.assignedCaretakerIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'assignedDoctorIds': assignedDoctorIds,
      'assignedCaretakerIds': assignedCaretakerIds,
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    return PatientModel(
      patientId: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      assignedDoctorIds: List<String>.from(map['assignedDoctorIds'] ?? []),
      assignedCaretakerIds: List<String>.from(map['assignedCaretakerIds'] ?? []),
    );
  }
}
