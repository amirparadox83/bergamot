// تست‌های BergamotStreakCalculator (PHASE 20)
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/data/database/bergamot_database.dart';
import 'package:bergamot/domain/entities/bergamot_streak_calculator.dart';

void main() {
  // Helper: ساخت Workout با تاریخ مشخص
  Workout makeWorkout({
    required DateTime date,
    bool completed = true,
    int? durationMinutes = 30,
    int? estimatedCalories = 100,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    return Workout(
      id: 1,
      name: 'test',
      date: dayStart,
      startTime: dayStart,
      endTime: null,
      durationMinutes: durationMinutes,
      notes: null,
      isCompleted: completed,
      templateId: null,
      totalReps: null,
      totalSets: null,
      estimatedCalories: estimatedCalories,
      isRestDay: false,
      createdAt: 0,
    );
  }

  // Helper: ساخت Program Day rest
  // (استفاده‌نشده — برای تست‌های بعدی نگه داشته شده)

  group('BergamotStreakCalculator', () {
    // ───────── calculateCurrentStreak ─────────
    group('calculateCurrentStreak', () {
      test('empty workout list → 0', () {
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: [],
          today: DateTime(2026, 8, 24),
        );
        expect(streak, 0);
      });

      test('workout today only → 1', () {
        final today = DateTime(2026, 8, 24);
        final workouts = [makeWorkout(date: today)];
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: workouts,
          today: today,
        );
        expect(streak, 1);
      });

      test('workout yesterday + today → 2', () {
        final today = DateTime(2026, 8, 24);
        final workouts = [
          makeWorkout(date: today),
          makeWorkout(date: today.subtract(const Duration(days: 1))),
        ];
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: workouts,
          today: today,
        );
        expect(streak, 2);
      });

      test('7 day consecutive workouts → 7', () {
        final today = DateTime(2026, 8, 24);
        final workouts = [
          for (int i = 0; i < 7; i++)
            makeWorkout(date: today.subtract(Duration(days: i))),
        ];
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: workouts,
          today: today,
        );
        expect(streak, 7);
      });

      test('gap of 2 days → rest day tolerated → streak continues', () {
        // today: workout
        // yesterday: no workout
        // 2 days ago: workout
        // به‌دلیل gap 1 روز (که برنامه‌ریزی‌شده است)، streak باید 2 باشد
        final today = DateTime(2026, 8, 24);
        final workouts = [
          makeWorkout(date: today),
          makeWorkout(date: today.subtract(const Duration(days: 2))),
        ];
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: workouts,
          today: today,
        );
        // امروز: workout → streak=1
        // دیروز: نه workout نه rest → break
        // پس streak = 1
        expect(streak, 1);
      });

      test('with rest day program — streak continues', () {
        final today = DateTime(2026, 8, 24);
        final workouts = [
          makeWorkout(date: today),
          makeWorkout(date: today.subtract(const Duration(days: 2))),
        ];
        // ۳ روز program: روز ۱ = workout، روز ۲ = rest، روز ۳ = workout
        // روز ۱ (۲ روز پیش) = workout → ✓
        // روز ۲ (دیروز) = rest day → streak++
        // روز ۳ (امروز) = workout → streak++
        // برنامه از ۲ روز پیش شروع شده
        final programStartDate = today.subtract(const Duration(days: 2));
        const programDays = <WorkoutProgramDay>[
          WorkoutProgramDay(
            id: 1, programId: 1, dayNumber: 1,
            nameFa: 'روز ۱', isRestDay: false, templateId: null, notesFa: null,
          ),
          WorkoutProgramDay(
            id: 2, programId: 1, dayNumber: 2,
            nameFa: 'روز ۲', isRestDay: true, templateId: null, notesFa: null,
          ),
          WorkoutProgramDay(
            id: 3, programId: 1, dayNumber: 3,
            nameFa: 'روز ۳', isRestDay: false, templateId: null, notesFa: null,
          ),
        ];
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: workouts,
          programDays: programDays,
          programStartDate: programStartDate,
          today: today,
        );
        // امروز: workout → streak=1
        // دیروز: rest day → streak=2
        // ۲ روز پیش: workout → streak=3
        expect(streak, 3);
      });

      test('workout yesterday but not today → 1 (yesterday)', () {
        final today = DateTime(2026, 8, 24);
        final workouts = [
          makeWorkout(date: today.subtract(const Duration(days: 1))),
        ];
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: workouts,
          today: today,
        );
        // امروز هنوز تمرین نکرده، از دیروز شروع می‌شود
        expect(streak, 1);
      });

      test('incomplete workout does NOT count', () {
        final today = DateTime(2026, 8, 24);
        final workouts = [
          makeWorkout(date: today, completed: false),
        ];
        final streak = BergamotStreakCalculator.calculateCurrentStreak(
          workouts: workouts,
          today: today,
        );
        expect(streak, 0);
      });
    });

    // ───────── calculateLongestStreak ─────────
    group('calculateLongestStreak', () {
      test('empty list → 0', () {
        final longest = BergamotStreakCalculator.calculateLongestStreak(workouts: []);
        expect(longest, 0);
      });

      test('single workout → 1', () {
        final workouts = [makeWorkout(date: DateTime(2026, 8, 24))];
        final longest = BergamotStreakCalculator.calculateLongestStreak(workouts: workouts);
        expect(longest, 1);
      });

      test('3 consecutive days → 3', () {
        final workouts = [
          makeWorkout(date: DateTime(2026, 8, 22)),
          makeWorkout(date: DateTime(2026, 8, 23)),
          makeWorkout(date: DateTime(2026, 8, 24)),
        ];
        final longest = BergamotStreakCalculator.calculateLongestStreak(workouts: workouts);
        expect(longest, 3);
      });

      test('break and resume → longest is 3', () {
        final workouts = [
          makeWorkout(date: DateTime(2026, 8, 20)),
          makeWorkout(date: DateTime(2026, 8, 21)),
          makeWorkout(date: DateTime(2026, 8, 22)),
          // gap 3 days
          makeWorkout(date: DateTime(2026, 8, 26)),
          makeWorkout(date: DateTime(2026, 8, 27)),
        ];
        final longest = BergamotStreakCalculator.calculateLongestStreak(workouts: workouts);
        expect(longest, 3);
      });

      test('1-day gap tolerated (rest day)', () {
        // 20, 21, [gap=22], 23, 24
        // Gap of 1 day = rest day tolerated → streak = 5
        final workouts = [
          makeWorkout(date: DateTime(2026, 8, 20)),
          makeWorkout(date: DateTime(2026, 8, 21)),
          makeWorkout(date: DateTime(2026, 8, 23)),
          makeWorkout(date: DateTime(2026, 8, 24)),
        ];
        final longest = BergamotStreakCalculator.calculateLongestStreak(workouts: workouts);
        // 20→21 (diff=1): streak=2
        // 21→23 (diff=2): rest day tolerated → streak=3
        // 23→24 (diff=1): streak=4
        expect(longest, 4);
      });
    });

    // ───────── last7DaysSeries ─────────
    group('last7DaysSeries', () {
      test('returns 7 entries', () {
        final series = BergamotStreakCalculator.last7DaysSeries([]);
        expect(series.length, 7);
      });

      test('all entries have zero workouts on empty list', () {
        final series = BergamotStreakCalculator.last7DaysSeries([]);
        for (final entry in series) {
          expect(entry.workouts, 0);
          expect(entry.calories, 0);
        }
      });

      test('today workout counted in last entry', () {
        final today = DateTime.now();
        final workouts = [makeWorkout(date: today)];
        final series = BergamotStreakCalculator.last7DaysSeries(workouts);
        expect(series.last.workouts, 1);
        expect(series.last.calories, 100);
      });
    });

    // ───────── calculateWeeklyStats ─────────
    group('calculateWeeklyStats', () {
      test('empty list → zeros', () {
        final stats = BergamotStreakCalculator.calculateWeeklyStats([]);
        expect(stats.workouts, 0);
        expect(stats.minutes, 0);
        expect(stats.calories, 0);
      });

      test('aggregates workouts in last 7 days', () {
        final today = DateTime.now();
        final workouts = [
          makeWorkout(date: today, durationMinutes: 30, estimatedCalories: 200),
          makeWorkout(date: today.subtract(const Duration(days: 2)), durationMinutes: 45, estimatedCalories: 300),
          // 8 days ago — should not count
          makeWorkout(date: today.subtract(const Duration(days: 8)), durationMinutes: 30, estimatedCalories: 100),
        ];
        final stats = BergamotStreakCalculator.calculateWeeklyStats(workouts);
        expect(stats.workouts, 2);
        expect(stats.minutes, 75);
        expect(stats.calories, 500);
      });
    });

    // ───────── calculateMonthlyStats ─────────
    group('calculateMonthlyStats', () {
      test('aggregates last 30 days', () {
        final today = DateTime.now();
        final workouts = [
          makeWorkout(date: today, durationMinutes: 30, estimatedCalories: 200),
          makeWorkout(date: today.subtract(const Duration(days: 29)), durationMinutes: 60, estimatedCalories: 400),
          // 31 days ago — excluded
          makeWorkout(date: today.subtract(const Duration(days: 31))),
        ];
        final stats = BergamotStreakCalculator.calculateMonthlyStats(workouts);
        expect(stats.workouts, 2);
        expect(stats.minutes, 90);
        expect(stats.calories, 600);
      });
    });
  });
}
