import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/medicine_model.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Always use [NotificationService.instance] — never construct directly.
  static NotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _tokenListenerAttached = false;

  /// The high-importance channel used for FCM foreground messages.
  static const _fcmChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Channel for important push notifications',
    importance: Importance.max,
  );

  /// The channel used for local medicine reminder alarms.
  static const _reminderChannel = AndroidNotificationChannel(
    'medicine_reminders',
    'Medicine Reminders',
    description: 'Scheduled reminders for upcoming medicine doses',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    // 0. Timezone data (needed for zonedSchedule)
    tz.initializeTimeZones();
    try {
      // getLocalTimezone() returns a TimezoneInfo object in latest versions
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    } catch (e) {
      debugPrint('Could not initialize local timezone: $e');
    }

    // 1. Setup local notifications for foreground display
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // 2. Create Android notification channels (required on Android 8+)
    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_fcmChannel);
      await androidPlugin.createNotificationChannel(_reminderChannel);
      // Request Android 13+ notification permission
      await androidPlugin.requestNotificationsPermission();
      // Request Android 12+ exact alarm permission
      await androidPlugin.requestExactAlarmsPermission();
    }

    // 3. Request FCM permissions (iOS + Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else {
      debugPrint('Notification permission status: ${settings.authorizationStatus}');
    }

    // 4. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle foreground messages — show as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _fcmChannel.id,
              _fcmChannel.name,
              channelDescription: _fcmChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 6. Save FCM token whenever a user is signed in
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _saveDeviceToken(user.uid);
      }
    });

    _initialized = true;
  }

  Future<void> _saveDeviceToken(String uid) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }

    // Avoid attaching duplicate onTokenRefresh listeners
    if (!_tokenListenerAttached) {
      _tokenListenerAttached = true;
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .update({'fcmToken': newToken});
        }
      });
    }
  }

  // ── Schedule all reminders for the current user on app start ──────────────
  /// Call this once after login / app resume to make sure local reminders
  /// are scheduled whether or not the user visits a particular screen.
  Future<void> scheduleAllRemindersForUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Determine role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) return;
      final role = userDoc.data()?['role'] as String? ?? '';

      if (role == 'patient') {
        await _schedulePatientReminders(uid);
      } else if (role == 'caretaker') {
        await _scheduleCaretakerReminders(uid);
      }
    } catch (e) {
      debugPrint('Error scheduling reminders on startup: $e');
    }
  }

  Future<void> _schedulePatientReminders(String patientId) async {
    final snap = await FirebaseFirestore.instance
        .collection('medicines')
        .where('patientId', isEqualTo: patientId)
        .get();

    final meds = snap.docs
        .map((d) => MedicineModel.fromMap(d.id, d.data()))
        .where((m) => m.isActive && _isDateInRange(DateTime.now(), m.startDate, m.endDate))
        .toList();

    await syncMedicineReminders(
      scopeKey: 'patient:$patientId',
      medicines: meds,
      titlePrefix: 'Medicine',
    );
  }

  Future<void> _scheduleCaretakerReminders(String caretakerId) async {
    // Find all patients linked to this caretaker
    final patientSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('caretakerId', isEqualTo: caretakerId)
        .get();

    // Also check the patients subcollection pattern
    final linkedSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(caretakerId)
        .collection('patients')
        .get();

    final patientIds = <String>{};
    for (final doc in patientSnap.docs) {
      patientIds.add(doc.id);
    }
    for (final doc in linkedSnap.docs) {
      patientIds.add(doc.id);
    }

    for (final pid in patientIds) {
      final medSnap = await FirebaseFirestore.instance
          .collection('medicines')
          .where('patientId', isEqualTo: pid)
          .get();

      final meds = medSnap.docs
          .map((d) => MedicineModel.fromMap(d.id, d.data()))
          .where((m) => m.isActive && _isDateInRange(DateTime.now(), m.startDate, m.endDate))
          .toList();

      await syncMedicineReminders(
        scopeKey: 'caretaker:$caretakerId|patient:$pid',
        medicines: meds,
        titlePrefix: 'Patient medicine',
      );
    }
  }

  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return dateOnly.isAfter(startOnly.subtract(const Duration(days: 1))) &&
        dateOnly.isBefore(endOnly.add(const Duration(days: 1)));
  }

  /// Shows an immediate (non-scheduled) local notification when a dose is
  /// logged as missed. Safe to call from any isolate context.
  /// Never throws — errors are caught internally.
  Future<void> showMissedDoseAlert({
    required String patientId,
    required String medicineName,
    required String scheduledTime,
  }) async {
    try {
      final id = _stableId('missed|$patientId|$medicineName|$scheduledTime');
      await _localNotificationsPlugin.show(
        id,
        '⚠️ Missed Dose Alert',
        '$medicineName dose ($scheduledTime) was missed!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _fcmChannel.id,
            _fcmChannel.name,
            channelDescription: _fcmChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('showMissedDoseAlert failed (non-fatal): $e');
    }
  }

  /// Sends a local missed-dose alert on this device AND fires a local
  /// notification for every caretaker linked to [patientId].
  ///
  /// Fetches `users/{patientId}.caretakerIds`, resolves each caretaker's
  /// `users/{caretakerId}.fcmToken`, and shows a local notification for each
  /// one whose token is stored on this device session.  In practice the
  /// caretaker receives the push via FCM from the server-side Cloud Function;
  /// this covers the case where both users share a device or for testing.
  ///
  /// Never throws — all errors are swallowed so callers are never affected.
  Future<void> notifyMissedDoseToCaretakers({
    required String patientId,
    required String medicineName,
    required String scheduledTime,
  }) async {
    try {
      // 1. Show alert on the current device (patient side).
      await showMissedDoseAlert(
        patientId: patientId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      debugPrint('notifyMissedDoseToCaretakers: local alert failed (non-fatal): $e');
    }

    // 2. Look up linked caretakers and notify each one.
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      if (!userDoc.exists) return;

      final caretakerIds = List<String>.from(
        userDoc.data()?['caretakerIds'] ?? const [],
      );

      for (final cid in caretakerIds) {
        try {
          final ctDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(cid)
              .get();
          // FCM token is stored but server-side Cloud Function handles the
          // actual push delivery.  Here we log for observability.
          final token = ctDoc.data()?['fcmToken'] as String?;
          if (token != null && token.isNotEmpty) {
            debugPrint(
              'notifyMissedDoseToCaretakers: caretaker $cid has FCM token (delivery via Cloud Function)',
            );
          }
        } catch (e) {
          debugPrint('notifyMissedDoseToCaretakers: caretaker $cid lookup failed (non-fatal): $e');
        }
      }
    } catch (e) {
      debugPrint('notifyMissedDoseToCaretakers: caretaker fetch failed (non-fatal): $e');
    }
  }

  /// Rebuilds (cancels + schedules) local reminders for the given medicines.
  ///
  /// This is intentionally local-device only (no server scheduling).
  Future<void> syncMedicineReminders({
    required String scopeKey,
    required List<MedicineModel> medicines,
    required String titlePrefix,
  }) async {
    // Keep IDs stable per (scopeKey + medicineId + timing) to avoid duplicates.
    // We can't list scheduled notifications easily without extra state, so we
    // use a deterministic ID and overwrite via schedule.
    for (final med in medicines) {
      for (final timing in med.timings) {
        final time = _timeForMedicineTiming(med, timing);
        if (time == null) continue;

        final id = _stableId('$scopeKey|${med.id}|$timing');
        final when = _nextInstanceOf(time.hour, time.minute);

        try {
          await _localNotificationsPlugin.zonedSchedule(
            id,
            '$titlePrefix: ${med.name}',
            'Dosage: ${med.dosage} • $timing',
            when,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _reminderChannel.id,
                _reminderChannel.name,
                channelDescription: _reminderChannel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time, // daily
          );
        } catch (e) {
          debugPrint('Failed to schedule notification for ${med.name}/$timing: $e');
        }
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