import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ralph_cos_channel',
      'Ralph CoS Notifications',
      channelDescription: 'Discipline and accountability notifications',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleMorningPush() async {
    // Cancel any existing notifications
    await _notifications.cancelAll();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 5, 0);

    // If it's already past 5 AM today, schedule for tomorrow
    if (now.hour >= 5) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final messages = [
      'Aufstehen! Keine Ausreden!',
      'Ralph wartet nicht. Zeit zu checken.',
      'Deine Streak ist in Gefahr!',
      'Jetzt oder nie. Check-in läuft ab!',
    ];

    // Schedule escalating notifications from 05:00 to 08:55
    for (int i = 0; i < 4; i++) {
      final notificationTime = scheduledDate.add(Duration(hours: i));

      await _notifications.zonedSchedule(
        i,
        'RALPH-CoS',
        messages[i],
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ralph_cos_channel',
            'Ralph CoS Notifications',
            channelDescription: 'Discipline and accountability notifications',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // Final warning at 08:55
    final finalWarning = scheduledDate.add(const Duration(hours: 3, minutes: 55));
    await _notifications.zonedSchedule(
      99,
      'LETZTE WARNUNG!',
      'Noch 5 Minuten bis Streak-Break. JETZT EINCHECKEN!',
      tz.TZDateTime.from(finalWarning, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ralph_cos_channel',
          'Ralph CoS Notifications',
          channelDescription: 'Discipline and accountability notifications',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showStreakBreakNotification() async {
    await showImmediateNotification(
      id: 100,
      title: 'STREAK VERLOREN',
      body: 'Du hast den Check-in verpasst. Streak auf 0.',
    );
  }

  Future<void> showPassEarnedNotification() async {
    await showImmediateNotification(
      id: 101,
      title: 'PASS VERDIENT! 🛡️',
      body: '20 Tage Streak! Du hast einen Extender Pass erhalten.',
    );
  }

  Future<void> showPassUsedNotification() async {
    await showImmediateNotification(
      id: 102,
      title: 'PASS VERWENDET',
      body: 'Ein Pass wurde verwendet. Deine Streak bleibt bestehen.',
    );
  }

  Future<void> scheduleChallengeReminder() async {
    // Schedule reminder at 20:00 (8 PM) for challenge completion
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 20, 0);

    // If it's already past 8 PM today, schedule for tomorrow
    if (now.hour >= 20) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      200,
      '30-DAY CHALLENGE',
      'Did you complete today\'s task? Click to mark your emotion.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ralph_challenge_channel',
          'Challenge Reminders',
          channelDescription: '30-day challenge completion reminders',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Second reminder at 21:30 (9:30 PM) if not completed
    final secondReminder = scheduledDate.add(const Duration(hours: 1, minutes: 30));
    await _notifications.zonedSchedule(
      201,
      'CHALLENGE INCOMPLETE',
      'Day still incomplete. Your transformation won\'t happen without action.',
      tz.TZDateTime.from(secondReminder, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ralph_challenge_channel',
          'Challenge Reminders',
          channelDescription: '30-day challenge completion reminders',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showChallengeCompletedNotification(int day) async {
    await showImmediateNotification(
      id: 202,
      title: 'DAY $day COMPLETE ✅',
      body: 'Momentum builds with consistency. See you tomorrow.',
    );
  }

  Future<void> showDay25ReminderNotification() async {
    await showImmediateNotification(
      id: 203,
      title: 'DAY 25 MILESTONE! 🎯',
      body: '5 days left. Time to design your NEXT 30-day challenge. Don\'t lose momentum.',
    );
  }

  Future<void> scheduleSundayStrategicReminder() async {
    // Schedule for Sunday at 15:00 (3 PM)
    final now = DateTime.now();
    int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    if (daysUntilSunday == 0 && now.hour >= 15) {
      daysUntilSunday = 7; // Next Sunday
    }

    final nextSunday = now.add(Duration(days: daysUntilSunday));
    final scheduledDate = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      15,
      0,
    );

    await _notifications.zonedSchedule(
      300,
      'SUNDAY STRATEGIC RESET ⚡',
      'Time to plan your week. Review, reflect, and set your course.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ralph_sunday_channel',
          'Sunday Strategic',
          channelDescription: 'Weekly planning and reset reminders',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Second reminder at 20:00 if not completed
    final eveningReminder = scheduledDate.add(const Duration(hours: 5));
    await _notifications.zonedSchedule(
      301,
      'SUNDAY WINDOW CLOSING',
      'Strategic planning ends at 22:00. Finish your weekly review now.',
      tz.TZDateTime.from(eveningReminder, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ralph_sunday_channel',
          'Sunday Strategic',
          channelDescription: 'Weekly planning and reset reminders',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showEveningRitualReminder() async {
    await showImmediateNotification(
      id: 302,
      title: 'EVENING KON-FEEDBACK',
      body: 'Day\'s ending. Did you keep your vow? Time for accountability check.',
    );
  }

  Future<void> scheduleEveningRitualReminder() async {
    // Schedule for 20:00 (8 PM) daily
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 20, 0);

    if (now.hour >= 20) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      303,
      'EVENING KON-FEEDBACK',
      'Did you keep your vow today? Zero status check time.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ralph_evening_channel',
          'Evening Ritual',
          channelDescription: 'Evening reflection and accountability',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
