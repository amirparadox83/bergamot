import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/sleep_dao.dart';
import '../../../data/database/database_provider.dart';

/// پرووایدر DAO خواب
final sleepDaoProvider = Provider<SleepDao>((ref) {
  return SleepDao(ref.watch(bergamotDatabaseProvider));
});

/// پرووایدر لیست خواب امروز
///
/// از [AsyncNotifier] برای مدیریت حالت ناهمگام استفاده می‌کند.
/// دیتابیس به‌صورت استریم واچ می‌شود و هر تغییر بلافاصله منعکس می‌شود.
class TodaySleepNotifier extends AsyncNotifier<List<SleepEntry>> {
  @override
  Future<List<SleepEntry>> build() async {
    final dao = ref.watch(sleepDaoProvider);
    final stream = dao.watchTodaySleep();
    return stream.first;
  }

  /// ثبت خواب جدید
  ///
  /// [sleepTime] زمان خواب رفتن به میلی‌ثانیه Epoch
  /// [wakeTime] زمان بیدار شدن به میلی‌ثانیه Epoch
  /// [quality] کیفیت خواب از ۱ تا ۵
  /// [notes] یادداشت اختیاری
  Future<void> addSleep({
    required int sleepTime,
    required int wakeTime,
    required int quality,
    String? notes,
  }) async {
    final dao = ref.read(sleepDaoProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;

    // محاسبه مدت خواب به دقیقه
    final durationMillis = wakeTime - sleepTime;
    // اگر بیداری قبل از خواب باشد (مثلاً شب قبل)، ۲۴ ساعت اضافه
    final adjustedDuration = durationMillis < 0
        ? durationMillis + 24 * 60 * 60 * 1000
        : durationMillis;
    final durationMinutes = (adjustedDuration / (1000 * 60)).round();

    final entry = SleepEntriesCompanion(
      date: Value(startOfDay),
      sleepTime: Value(sleepTime),
      wakeTime: Value(wakeTime),
      durationMinutes: Value(durationMinutes),
      quality: Value(quality),
      notes: Value(notes),
      createdAt: Value(now.millisecondsSinceEpoch),
    );

    await dao.insertSleep(entry);

    // بازخوانی داده‌ها
    ref.invalidateSelf();
  }

  /// حذف ورودی خواب
  Future<void> deleteSleep(int id) async {
    final dao = ref.read(sleepDaoProvider);
    await dao.deleteSleep(id);
    ref.invalidateSelf();
  }
}

/// Provider اصلی خواب امروز
final todaySleepProvider =
    AsyncNotifierProvider<TodaySleepNotifier, List<SleepEntry>>(
  TodaySleepNotifier.new,
);

/// پرووایدر خواب‌های تاریخچه برای نمودار
///
/// [days] تعداد روزهای اخیر
final sleepHistoryProvider =
    FutureProvider.family<List<SleepEntry>, int>((ref, days) async {
  final dao = ref.watch(sleepDaoProvider);
  final now = DateTime.now();
  final endOfDay = DateTime(now.year, now.month, now.day)
      .millisecondsSinceEpoch;
  final startRange = endOfDay - (days * 24 * 60 * 60 * 1000);
  return dao.getSleepByDateRange(startRange, endOfDay);
});
