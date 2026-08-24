import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/database_provider.dart';

/// مدل یکتای رویداد تایم‌لاین
///
/// تمام رویدادهای امروز (خواب، تغذیه، آب، تمرین، عادت)
/// به این مدل تبدیل و مرتب‌سازی می‌شوند
class TimelineEvent {
  /// شناسه ترکیبی: 'sleep_1' یا 'meal_5' و غیره
  final String id;

  /// زمان رویداد به میلی‌ثانیه Epoch
  final int timestampMs;

  /// عنوان رویداد
  final String title;

  /// زیرعنوان / توضیح کوتاه
  final String subtitle;

  /// دسته‌بندی: 'sleep', 'meal', 'water', 'workout', 'habit'
  final String category;

  /// آیکون دسته‌بندی
  final IconData icon;

  /// رنگ آیکون
  final Color iconColor;

  const TimelineEvent({
    required this.id,
    required this.timestampMs,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.iconColor,
  });
}

/// نام دسته‌بندی‌ها به فارسی
const kCategoryLabels = {
  'all': 'همه',
  'sleep': 'خواب',
  'meal': 'تغذیه',
  'water': 'آب',
  'workout': 'تمرین',
  'habit': 'عادت',
};

/// تمام دسته‌بندی‌های ممکن
const kAllCategories = ['sleep', 'meal', 'water', 'workout', 'habit'];

/// اطلاعات فیلتر (کدام دسته‌بندی‌ها فعال هستند)
class TimelineFilter {
  final Set<String> activeCategories;

  const TimelineFilter({
    this.activeCategories = const {
      'sleep',
      'meal',
      'water',
      'workout',
      'habit',
    },
  });

  TimelineFilter copyWith({Set<String>? activeCategories}) {
    return TimelineFilter(
      activeCategories: activeCategories ?? this.activeCategories,
    );
  }

  bool isActive(String category) => activeCategories.contains(category);

  /// آیا همه دسته‌بندی‌ها فعالند؟
  bool get isAll =>
      activeCategories.length == kAllCategories.length ||
      activeCategories.containsAll(kAllCategories);
}

/// وضعیت تایم‌لاین
class TimelineState {
  final List<TimelineEvent> events;
  final TimelineFilter filter;
  final bool isLoading;

  const TimelineState({
    this.events = const [],
    this.filter = const TimelineFilter(),
    this.isLoading = true,
  });

  TimelineState copyWith({
    List<TimelineEvent>? events,
    TimelineFilter? filter,
    bool? isLoading,
  }) {
    return TimelineState(
      events: events ?? this.events,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// رویدادهای فیلترشده
  List<TimelineEvent> get filteredEvents {
    if (filter.isAll) return events;
    return events.where((e) => filter.isActive(e.category)).toList();
  }
}

/// پروویدر فیلتر تایم‌لاین
final timelineFilterProvider =
    StateProvider<TimelineFilter>((ref) => const TimelineFilter());

/// پروویدر اصلی تایم‌لاین
///
/// تمام رویدادهای امروز را از تمام جداول خوانده،
/// یکدست کرده و مرتب می‌کند.
final timelineProvider =
    AsyncNotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);

class TimelineNotifier extends AsyncNotifier<TimelineState> {
  @override
  Future<TimelineState> build() async {
    final db = ref.read(bergamotDatabaseProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    final startMs = startOfDay.millisecondsSinceEpoch;
    final endMs = endOfDay.millisecondsSinceEpoch;

    final events = <TimelineEvent>[];

    // --- خواب ---
    final sleepRows = await (db.select(db.sleepEntries)
          ..where((t) => t.date.isBetweenValues(startMs, endMs)))
        .get();
    for (final row in sleepRows) {
      events.add(TimelineEvent(
        id: 'sleep_${row.id}',
        timestampMs: row.sleepTime,
        title: 'خواب',
        subtitle: _formatDuration(row.durationMinutes),
        category: 'sleep',
        icon: Icons.bedtime_outlined,
        iconColor: const Color(0xFF6366F1),
      ));
    }

    // --- تغذیه ---
    final mealRows = await (db.select(db.mealEntries)
          ..where((t) => t.date.isBetweenValues(startMs, endMs)))
        .get();
    const mealTypeNames = ['صبحانه', 'ناهار', 'شام', 'میان‌وعده'];
    for (final row in mealRows) {
      final typeName = row.mealType >= 0 && row.mealType < 4
          ? mealTypeNames[row.mealType]
          : 'وعده';
      events.add(TimelineEvent(
        id: 'meal_${row.id}',
        timestampMs: row.createdAt,
        title: typeName,
        subtitle: '${row.foodName} · ${row.calories.round()} کیلوکالری',
        category: 'meal',
        icon: Icons.local_fire_department_outlined,
        iconColor: const Color(0xFFF59E0B),
      ));
    }

    // --- آب ---
    final waterRows = await (db.select(db.waterEntries)
          ..where((t) => t.date.isBetweenValues(startMs, endMs)))
        .get();
    for (final row in waterRows) {
      events.add(TimelineEvent(
        id: 'water_${row.id}',
        timestampMs: row.time,
        title: 'نوشیدن آب',
        subtitle: '${row.amountMl} میلی‌لیتر',
        category: 'water',
        icon: Icons.water_drop_outlined,
        iconColor: const Color(0xFF3B82F6),
      ));
    }

    // --- تمرین ---
    final workoutRows = await (db.select(db.workouts)
          ..where((t) => t.date.isBetweenValues(startMs, endMs)))
        .get();
    for (final row in workoutRows) {
      final ts = row.startTime;
      final durText = row.durationMinutes != null
          ? '${row.durationMinutes} دقیقه'
          : '';
      final completedText = row.isCompleted ? '' : ' (ناتمام)';
      events.add(TimelineEvent(
        id: 'workout_${row.id}',
        timestampMs: ts,
        title: row.name,
        subtitle: '$durText$completedText'.trim(),
        category: 'workout',
        icon: Icons.fitness_center_outlined,
        iconColor: const Color(0xFF10B981),
      ));
    }

    // --- عادت ---
    final habitLogs = await (db.select(db.habitLogs)
          ..where((t) =>
              t.date.isBetweenValues(startMs, endMs) &
              t.isCompleted.equals(true)))
        .get();

    // Batch-fetch all referenced habits to avoid N+1 queries
    final habitIds = habitLogs.map((log) => log.habitId).toSet();
    final habitMap = <int, Habit>{};
    if (habitIds.isNotEmpty) {
      final allHabits = await (db.select(db.habits)
            ..where((t) => t.id.isIn(habitIds)))
          .get();
      for (final h in allHabits) {
        habitMap[h.id] = h;
      }
    }

    for (final log in habitLogs) {
      final habit = habitMap[log.habitId];
      if (habit == null) continue;

      final ts = log.completedAt ?? log.date;
      events.add(TimelineEvent(
        id: 'habit_${log.id}',
        timestampMs: ts,
        title: habit.name,
        subtitle: 'انجام شد',
        category: 'habit',
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF8B5CF6),
      ));
    }

    // مرتب‌سازی نزولی بر اساس زمان
    events.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));

    return TimelineState(events: events, isLoading: false);
  }

  /// فرمت مدت زمان
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m دقیقه';
    if (m == 0) return '$h ساعت';
    return '$h ساعت و $m دقیقه';
  }
}
