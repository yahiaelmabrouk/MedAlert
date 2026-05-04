import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';

/// Handles all things related to local (on-device) notifications.
///
/// We schedule one daily reminder per medication.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Call once at app start (in main.dart) before scheduling anything.
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);

    // Ask the user for permission (Android 13+ and iOS).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedule a daily reminder at the medication's hour:minute.
  Future<void> scheduleDaily(Medication med) async {
    final id = med.id.hashCode; // Stable numeric id from the string id.
    final scheduled = _nextInstanceOf(med.hour, med.minute);

    await _plugin.zonedSchedule(
      id,
      'Time for ${med.name}',
      med.dosage.isEmpty ? 'Take your medication.' : 'Take ${med.dosage}.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medreminder_channel',
          'Medication reminders',
          channelDescription: 'Daily reminders to take your medication',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat every day
    );
  }

  /// Cancel a scheduled reminder.
  Future<void> cancel(Medication med) async {
    await _plugin.cancel(med.id.hashCode);
  }

  /// Compute the next moment when [hour]:[minute] occurs (today or tomorrow).
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
}
