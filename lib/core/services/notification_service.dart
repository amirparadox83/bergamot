import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../data/database/bergamot_database.dart';

/// سرویس نوتیفیکیشن برگاموت
///
/// مدیریت زمان‌بندی و لغو یادآوری‌های محلی برای خواب، آب، تمرین و غذای کاربر
/// تمام تنظیمات در جدول AppSettings ذخیره می‌شوند
class BergamotNotificationService {
  final BergamotDatabase db;
  final FlutterLocalNotificationsPlugin _plugin;

  BergamotNotificationService({required this.db})
      : _plugin = FlutterLocalNotificationsPlugin();

  /// مقداردهی اولیه سرویس نوتیفیکیشن
  static Future<BergamotNotificationService> init(
      BergamotDatabase db) async {
    tz_data.initializeTimeZones();
    final service = BergamotNotificationService(db: db);
    await service._plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    return service;
  }

  // ── خواندن تنظیمات ──────────────────────────────────────────────────

  /// خواندن یک تنظیم بولی از دیتابیس
  Future<bool> _getBoolSetting(String key) async {
    final row = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  /// خواندن یک تنظیم رشته‌ای از دیتابیس
  Future<String?> _getStringSetting(String key) async {
    final row = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// ذخیره تنظیم در دیتابیس
  Future<void> _saveSetting(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (existing != null) {
      await (db.update(db.appSettings)..where((t) => t.key.equals(key)))
          .write(AppSettingsCompanion(
        value: Value(value),
        updatedAt: Value(now),
      ));
    } else {
      await db.into(db.appSettings).insert(AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(now),
      ));
    }
  }

  // ── تنظیم یادآوری خواب ──────────────────────────────────────────────

  /// فعال/غیرفعال کردن یادآوری خواب
  Future<void> setSleepReminder({
    required bool enabled,
    required String timeStr,
  }) async {
    await _saveSetting('notification_sleep_enabled', enabled.toString());
    await _saveSetting('notification_sleep_time', timeStr);
    await _rescheduleSleepReminder(enabled, timeStr);
  }

  Future<void> _rescheduleSleepReminder(bool enabled, String timeStr) async {
    await _plugin.cancel(1);
    if (!enabled) return;
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return; // malformed time string
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      1,
      'یادآوری خواب',
      'زمان خواب فرا رسیده! برای بازیابی بهتر به رختخواب بروید.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_reminder',
          'یادآوری خواب',
          channelDescription: 'یادآوری ساعت خواب',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── تنظیم یادآوری آب ────────────────────────────────────────────────

  /// فعال/غیرفعال کردن یادآوری آب
  Future<void> setWaterReminder({
    required bool enabled,
    required int intervalHours,
  }) async {
    await _saveSetting('notification_water_enabled', enabled.toString());
    await _saveSetting('notification_water_interval', intervalHours.toString());
    await _rescheduleWaterReminder(enabled, intervalHours);
  }

  Future<void> _rescheduleWaterReminder(bool enabled, int intervalHours) async {
    await _plugin.cancel(2);
    if (!enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = now.add(Duration(hours: intervalHours));
    await _plugin.zonedSchedule(
      2,
      'یادآوری نوشیدن آب',
      'نوشیدن آب را فراموش نکنید! هیدراتاسیون برای سلامتی ضروری است.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder',
          'یادآوری آب',
          channelDescription: 'یادآوری نوشیدن آب',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── تنظیم یادآوری تمرین ─────────────────────────────────────────────

  /// فعال/غیرفعال کردن یادآوری تمرین
  Future<void> setWorkoutReminder({
    required bool enabled,
    required String timeStr,
  }) async {
    await _saveSetting('notification_workout_enabled', enabled.toString());
    await _saveSetting('notification_workout_time', timeStr);
    await _rescheduleWorkoutReminder(enabled, timeStr);
  }

  Future<void> _rescheduleWorkoutReminder(bool enabled, String timeStr) async {
    await _plugin.cancel(3);
    if (!enabled) return;
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return; // malformed time string
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      3,
      'یادآوری تمرین',
      'زمان تمرین فرا رسیده! برای حفظ سلامتی خود تمرین کنید.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminder',
          'یادآوری تمرین',
          channelDescription: 'یادآوری جلسه تمرین',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── تنظیم یادآوری وعده غذایی ───────────────────────────────────────

  /// فعال/غیرفعال کردن یادآوری وعده غذایی
  Future<void> setMealReminder({
    required bool enabled,
    required List<String> mealTypes,
  }) async {
    await _saveSetting('notification_meal_enabled', enabled.toString());
    await _saveSetting('notification_meal_types', mealTypes.join(','));
    await _rescheduleMealReminders(enabled, mealTypes);
  }

  Future<void> _rescheduleMealReminders(
      bool enabled, List<String> mealTypes) async {
    // شناسه‌های ۱۰ تا ۱۳ برای وعده‌های غذایی
    for (var i = 0; i < 4; i++) {
      await _plugin.cancel(10 + i);
    }
    if (!enabled) return;

    final mealTimes = <String, (int, int)>{
      'breakfast': (8, 0),
      'lunch': (13, 0),
      'dinner': (20, 0),
      'snack': (16, 0),
    };
    final mealNames = <String, String>{
      'breakfast': 'صبحانه',
      'lunch': 'ناهار',
      'dinner': 'شام',
      'snack': 'میان‌وعده',
    };

    var idx = 0;
    for (final type in mealTypes) {
      final time = mealTimes[type];
      final name = mealNames[type];
      if (time == null || name == null) continue;
      final (hour, minute) = time;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        10 + idx,
        'یادآوری $name',
        'زمان $name فرا رسیده! تغذیه منظم داشته باشید.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meal_reminder',
            'یادآوری وعده غذایی',
            channelDescription: 'یادآوری وعده‌های غذایی',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      idx++;
    }
  }

  // ── خواندن وضعیت فعلی ──────────────────────────────────────────────

  /// دریافت وضعیت یادآوری خواب
  Future<({bool enabled, String time})> getSleepReminderStatus() async {
    final enabled = await _getBoolSetting('notification_sleep_enabled');
    final time = await _getStringSetting('notification_sleep_time');
    return (enabled: enabled, time: time ?? '22:30');
  }

  /// دریافت وضعیت یادآوری آب
  Future<({bool enabled, int intervalHours})> getWaterReminderStatus() async {
    final enabled = await _getBoolSetting('notification_water_enabled');
    final intervalStr = await _getStringSetting('notification_water_interval');
    return (
      enabled: enabled,
      intervalHours: int.tryParse(intervalStr ?? '') ?? 2,
    );
  }

  /// دریافت وضعیت یادآوری تمرین
  Future<({bool enabled, String time})> getWorkoutReminderStatus() async {
    final enabled = await _getBoolSetting('notification_workout_enabled');
    final time = await _getStringSetting('notification_workout_time');
    return (enabled: enabled, time: time ?? '18:00');
  }

  /// دریافت وضعیت یادآوری وعده غذایی
  Future<({bool enabled, List<String> mealTypes})> getMealReminderStatus() async {
    final enabled = await _getBoolSetting('notification_meal_enabled');
    final typesStr = await _getStringSetting('notification_meal_types');
    final types = typesStr?.split(',') ?? ['breakfast', 'lunch', 'dinner'];
    return (enabled: enabled, mealTypes: types);
  }
}
