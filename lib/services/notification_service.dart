// services/notification_service.dart
// Handles scheduling local notifications for medicine reminders.
// Uses: flutter_local_notifications + timezone packages

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  // Singleton pattern — only one instance throughout the app
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Call this once in main.dart before runApp()
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  // Schedule a daily reminder at a specific hour:minute
  // [id]   — unique int ID (use medicine name hash or index)
  // [hour] — 0-23
  // [minute] — 0-59
  Future<void> scheduleDailyReminder({
    required int id,
    required String medicineName,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Find next occurrence of this time
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '💊 Medicine Reminder',
      'Time to take $medicineName',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',       // channel id
          'Medicine Reminders',       // channel name
          channelDescription: 'Daily reminders to take your medicine',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  // Cancel a specific reminder
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  // Cancel all reminders
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}