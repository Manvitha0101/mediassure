// models/app_notification_model.dart

enum NotificationType { reminder, missed, escalation }

class AppNotificationModel {
  final String notificationId;
  final String userId; // The primary user who gets the notification
  final String patientId; // The patient this relates to
  final NotificationType type;
  final String message;
  final DateTime timestamp;

  AppNotificationModel({
    required this.notificationId,
    required this.userId,
    required this.patientId,
    required this.type,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientId': patientId,
      'type': type.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      notificationId: id,
      userId: map['userId'] ?? '',
      patientId: map['patientId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.reminder,
      ),
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }
}
