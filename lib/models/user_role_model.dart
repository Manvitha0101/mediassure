// models/user_role_model.dart

enum UserRole { patient, caretaker, doctor }

UserRole _roleFromString(String value) {
  switch (value.toLowerCase().trim()) {
    case 'doctor':    return UserRole.doctor;
    case 'caretaker': return UserRole.caretaker;
    default:          return UserRole.patient;
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<String> patientIds;
  final List<String> caretakerIds;
  final bool profileCompleted;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.patientIds = const [],
    this.caretakerIds = const [],
    this.profileCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name, // stores "patient", "caretaker", "doctor"
      'patientIds': patientIds,
      'caretakerIds': caretakerIds,
      'profileCompleted': profileCompleted,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: _roleFromString(map['role'] ?? 'patient'),
      patientIds: List<String>.from(map['patientIds'] ?? []),
      caretakerIds: List<String>.from(map['caretakerIds'] ?? []),
      profileCompleted: map['profileCompleted'] ?? false,
    );
  }
}
