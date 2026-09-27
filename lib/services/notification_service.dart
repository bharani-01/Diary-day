import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      print('Notification timezone mapping failed: $e');
    }
    
    if (Platform.isWindows) {
      await localNotifier.setup(
        appName: 'DiaryDay',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    }
    
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'main_channel',
        'Main Notifications',
        description: 'Generic farm alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel dailyShiftsChannel = AndroidNotificationChannel(
        'daily_shifts',
        'Daily Shifts',
        description: 'Daily shift reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(channel);
        await androidImpl.createNotificationChannel(dailyShiftsChannel);
      }
    }
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    }
  }

  static Future<void> autoScheduleFromPrefs() async {
    // Placeholder for loading saved settings
  }

  // --- NEW: Smart Todo Reminders ---
  static Future<void> scheduleTodoReminders({
    required String id,
    required String task,
    required DateTime? startTime,
    required DateTime? endTime,
  }) async {
    if (startTime != null) {
      final startReminderTime = startTime.subtract(const Duration(minutes: 10));
      if (startReminderTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: id.hashCode,
          title: 'Task Starting Soon',
          body: 'Starting at ${startTime.hour}:${startTime.minute}: $task',
          scheduledDate: startReminderTime,
        );
      }
    }

    if (endTime != null) {
      final endReminderTime = endTime.subtract(const Duration(minutes: 5));
      if (endReminderTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: id.hashCode + 1,
          title: '⏳ Task Ending Soon',
          body: 'Check status or extend time for: $task',
          scheduledDate: endReminderTime,
        );
      }
    }
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (Platform.isWindows) {
      try {
        final notification = LocalNotification(
          identifier: id.toString(),
          title: title,
          body: body,
        );
        await notification.show();
      } catch (e) {
        print('Error displaying Windows desktop notification: $e');
      }
      return;
    }

    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Notifications',
            channelDescription: 'Generic farm alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      print('Error displaying immediate notification on mobile: $e');
    }
  }

  // --- RESTORED: Generic Notification ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (Platform.isWindows) {
      try {
        final notification = LocalNotification(
          identifier: id.toString(),
          title: title,
          body: body,
        );
        await notification.show();
      } catch (e) {
        print('Error displaying Windows desktop notification: $e');
      }
      return;
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Notifications',
            channelDescription: 'Generic farm alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Fallback for Android 12+ if exact alarm permission is missing
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // --- RESTORED: Daily Shift Reminders ---
  static Future<void> scheduleDailyShiftReminders({
    required int morningHour,
    required int morningMin,
    required int eveningHour,
    required int eveningMin,
  }) async {
    await cancelDailyReminders();

    // Morning Shift
    await _notifications.zonedSchedule(
      1001,
      'Morning Milk Shift',
      'Time to enter morning milk production data!',
      _nextInstanceOfTime(morningHour, morningMin),
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_shifts', 'Daily Shifts', importance: Importance.high),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Evening Shift
    await _notifications.zonedSchedule(
      1002,
      'Evening Milk Shift',
      'Time to enter evening milk production data!',
      _nextInstanceOfTime(eveningHour, eveningMin),
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_shifts', 'Daily Shifts', importance: Importance.high),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> cancelDailyReminders() async {
    await _notifications.cancel(1001);
    await _notifications.cancel(1002);
  }

  // --- RESTORED: Test Notification ---
  static Future<void> showInstantTestNotification() async {
    if (Platform.isWindows) {
      await showImmediateNotification(
        id: 999,
        title: 'Test Alert',
        body: 'Your notifications are working perfectly!',
      );
      return;
    }
    const androidDetails = AndroidNotificationDetails('test_channel', 'Test Notifications', importance: Importance.max, priority: Priority.high);
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(999, 'Test Alert', 'Your notifications are working perfectly!', notificationDetails);
  }

  static Future<void> cancelTaskReminders(String id) async {
    await _notifications.cancel(id.hashCode);
    await _notifications.cancel(id.hashCode + 1);
  }
}
