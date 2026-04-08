// models/caretaker_model.dart
// Represents caretaker contact info

class Caretaker {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  Caretaker({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  factory Caretaker.fromMap(String id, Map<String, dynamic> map) {
    return Caretaker(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }
}