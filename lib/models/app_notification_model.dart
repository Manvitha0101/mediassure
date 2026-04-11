import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { reminder, missed, taken }

class AppNotificationModel {
  final String notificationId;
  final String userId;
  final String patientId;
  final String medicineId;
  final NotificationType type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.notificationId,
    required this.userId,
    required this.patientId,
    required this.medicineId,
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientId': patientId,
      'medicineId': medicineId,
      'type': type.name,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      notificationId: id,
      userId: map['userId'] ?? '',
      patientId: map['patientId'] ?? '',
      medicineId: map['medicineId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.reminder,
      ),
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] is Timestamp) 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}
