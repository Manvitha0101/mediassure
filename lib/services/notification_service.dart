import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine_model.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _tzReady = false;

  Future<void> initialize() async {
    if (!_tzReady) {
      tz.initializeTimeZones();
      _tzReady = true;
    }

    // 1. Setup local notifications for foreground display
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _localNotificationsPlugin.initialize(initializationSettings);

    // 2. Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Explicitly request Android 13+ Local Notification and Android 12+ Exact Alarm permissions
    final androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
    }

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5. Trigger saving of FCM token on successful login
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _saveDeviceToken(user.uid);
      }
    });
  }

  Future<void> _saveDeviceToken(String uid) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': newToken,
      });
    });
  }

  /// Rebuilds (cancels + schedules) local reminders for the given medicines.
  ///
  /// This is intentionally local-device only (no server scheduling).
  Future<void> syncMedicineReminders({
    required String scopeKey,
    required List<MedicineModel> medicines,
    required String titlePrefix,
  }) async {
    if (!_tzReady) {
      tz.initializeTimeZones();
      _tzReady = true;
    }

    // Keep IDs stable per (scopeKey + medicineId + timing) to avoid duplicates.
    // We can't list scheduled notifications easily without extra state, so we
    // use a deterministic ID and overwrite via schedule.
    for (final med in medicines) {
      for (final timing in med.timings) {
        final time = _timeForMedicineTiming(med, timing);
        if (time == null) continue;

        final id = _stableId('$scopeKey|${med.id}|$timing');
        final when = _nextInstanceOf(time.hour, time.minute);

        await _localNotificationsPlugin.zonedSchedule(
          id,
          '$titlePrefix: ${med.name}',
          'Dosage: ${med.dosage} • $timing',
          when,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medicine_reminders',
              'Medicine Reminders',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // daily
        );
      }
    }
  }

  TimeOfDay? _timeForMedicineTiming(MedicineModel med, String timing) {
    // Prefer explicit slotTimes when available.
    final ts = med.slotTimes != null ? med.slotTimes![timing] : null;
    if (ts != null) {
      final dt = ts.toDate();
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    // Try parsing "09:00 AM" style.
    final parsed = _parseAmPmTime(timing);
    if (parsed != null) return parsed;

    // Fallback defaults for "Morning/Afternoon/Night" presets.
    switch (timing) {
      case 'Morning':
        return const TimeOfDay(hour: 9, minute: 0);
      case 'Afternoon':
        return const TimeOfDay(hour: 14, minute: 0);
      case 'Night':
        return const TimeOfDay(hour: 21, minute: 0);
    }
    return null;
  }

  TimeOfDay? _parseAmPmTime(String raw) {
    final s = raw.trim().toUpperCase();
    final re = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
    final m = re.firstMatch(s);
    if (m == null) return null;
    int hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ap = m.group(3)!;
    if (hour < 1 || hour > 12) return null;
    if (minute < 0 || minute > 59) return null;
    if (ap == 'PM' && hour != 12) hour += 12;
    if (ap == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _stableId(String key) {
    // Simple stable hash -> 31-bit positive int.
    var hash = 0;
    for (final c in key.codeUnits) {
      hash = 0x1fffffff & (hash + c);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash & 0x7fffffff;
  }
}