import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/habit_dao.dart';
import '../../../data/database/database_provider.dart';

/// پرووایدر DAO عادت‌ها
final habitDaoProvider = Provider<HabitDao>((ref) {
  return HabitDao(ref.watch(bergamotDatabaseProvider));
});

/// حالت صفحه عادت‌ها
class HabitsState {
  final List<Habit> habits;
  final Map<int, bool> todayStatus;
  final Map<int, double> scores;
  final Map<int, int> streaks;

  const HabitsState({
    this.habits = const [],
    this.todayStatus = const {},
    this.scores = const {},
    this.streaks = const {},
  });

  HabitsState copyWith({
    List<Habit>? habits,
    Map<int, bool>? todayStatus,
    Map<int, double>? scores,
    Map<int, int>? streaks,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      todayStatus: todayStatus ?? this.todayStatus,
      scores: scores ?? this.scores,
      streaks: streaks ?? this.streaks,
    );
  }
}

/// ناتیفایر عادت‌ها
/// تمام عادت‌ها با وضعیت امروز، امتیاز و استریک بارگذاری می‌شوند
class HabitsNotifier extends AsyncNotifier<HabitsState> {
  @override
  Future<HabitsState> build() async {
    return _loadData();
  }

  /// بارگذاری تمام داده‌ها
  Future<HabitsState> _loadData() async {
    final dao = ref.read(habitDaoProvider);
    final habits = await dao.watchAllHabits().first;

    final todayStatus = <int, bool>{};
    final scores = <int, double>{};
    final streaks = <int, int>{};

    for (final habit in habits) {
      final todayLog = await dao.getTodayStatus(habit.id);
      todayStatus[habit.id] = todayLog?.isCompleted ?? false;
      scores[habit.id] = await dao.calculateHabitScore(habit.id);
      streaks[habit.id] = await dao.getCurrentStreak(habit.id);
    }

    return HabitsState(
      habits: habits,
      todayStatus: todayStatus,
      scores: scores,
      streaks: streaks,
    );
  }

  /// تاگل انجام عادت امروز
  Future<void> toggleToday(int habitId) async {
    final state = this.state.valueOrNull;
    if (state == null) return;

    final dao = ref.read(habitDaoProvider);
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final currentStatus = state.todayStatus[habitId] ?? false;

    await dao.toggleHabitLog(habitId, todayMs, !currentStatus);

    // بازخوانی کامل
    ref.invalidateSelf();
  }

  /// افزودن عادت جدید
  Future<void> addHabit(String name, String? icon) async {
    final dao = ref.read(habitDaoProvider);
    final entry = HabitsCompanion(
      name: Value(name),
      frequency: const Value(0), // روزانه
      icon: Value(icon),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await dao.addHabit(entry);
    ref.invalidateSelf();
  }

  /// حذف عادت
  Future<void> deleteHabit(int id) async {
    final dao = ref.read(habitDaoProvider);
    await dao.deleteHabit(id);
    ref.invalidateSelf();
  }
}

/// پرووایدر اصلی عادت‌ها
final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, HabitsState>(HabitsNotifier.new);
