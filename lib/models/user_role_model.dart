// models/user_role_model.dart

enum UserRole { patient, caretaker, doctor }

class UserRoleModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? gender;
  final bool isActive;
  final String? phone;
  final String? profileImageURL;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserRoleModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.gender,
    this.isActive = true,
    this.phone,
    this.profileImageURL,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'gender': gender,
      'isActive': isActive,
      'phone': phone,
      'profileImageURL': profileImageURL,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserRoleModel.fromMap(Map<String, dynamic> map, String id) {
    return UserRoleModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.patient,
      ),
      gender: map['gender'],
      isActive: map['isActive'] ?? true,
      phone: map['phone'],
      profileImageURL: map['profileImageURL'],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
    );
  }
}
