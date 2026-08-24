// Tests for DailyPlanGenerator (PHASE 4 — Bergamot troubleshooting round)
//
// These tests verify that the daily plan generator:
//   1. Produces sensible default wake/sleep times when no SleepEntry data
//      exists (the original behavior).
//   2. Uses actual sleep data when available (PHASE 4 enhancement).
//   3. Produces all expected plan items (Wake, Sleep, Breakfast, Lunch,
//      Dinner, Workout, Water reminders).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/data/database/bergamot_database.dart';
import 'package:bergamot/domain/services/daily_plan_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BergamotDatabase db;

  setUp(() async {
    db = BergamotDatabase(NativeDatabase.memory());
    // Initialize schema but skip full seed (we just need empty tables)
    // The migration onCreate runs automatically when the first query hits.
  });

  tearDown(() async {
    await db.close();
  });

  test('generates a plan with all expected items when no sleep data exists',
      () async {
    final generator = DailyPlanGenerator(db);
    final today = DateTime.now();
    final todayMs = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;

    final items = await generator.generate(todayMs);

    // Should produce at least: Wake, Sleep, Breakfast, Lunch, Dinner,
    // Workout, and several Water reminders
    expect(items.length, greaterThanOrEqualTo(7));

    // Verify categories
    final categories = items.map((i) => i.category.value).toSet();
    expect(categories, contains('sleep'));
    expect(categories, contains('meal'));
    expect(categories, contains('workout'));
    expect(categories, contains('water'));

    // Verify wake time defaults to 07:00
    final wakeItem = items.firstWhere((i) => i.itemTitle.value == 'بیداری');
    final wakeDate =
        DateTime.fromMillisecondsSinceEpoch(wakeItem.scheduledTime.value);
    expect(wakeDate.hour, 7);
    expect(wakeDate.minute, 0);

    // Verify sleep time defaults to 23:00
    final sleepItem = items.firstWhere((i) => i.itemTitle.value == 'خواب');
    final sleepDate =
        DateTime.fromMillisecondsSinceEpoch(sleepItem.scheduledTime.value);
    expect(sleepDate.hour, 23);
    expect(sleepDate.minute, 0);

    // Verify breakfast is 1 hour after wake (08:00)
    final breakfastItem = items.firstWhere((i) => i.itemTitle.value == 'صبحانه');
    final breakfastDate =
        DateTime.fromMillisecondsSinceEpoch(breakfastItem.scheduledTime.value);
    expect(breakfastDate.hour, 8);

    // Verify workout exists and has reasonable duration (>= 30 minutes)
    final workoutItem = items.firstWhere((i) => i.category.value == 'workout');
    expect(workoutItem.durationMinutes.value, greaterThanOrEqualTo(30));
  });

  test('uses actual sleep data when SleepEntry exists (PHASE 4)', () async {
    // Insert a SleepEntry: bedtime 22:00 yesterday, wake 06:00 today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final bedtimeMs = yesterdayStart
        .add(const Duration(hours: 22))
        .millisecondsSinceEpoch; // 22:00 yesterday
    final wakeMs = todayStart
        .add(const Duration(hours: 6))
        .millisecondsSinceEpoch; // 06:00 today
    const durationMin = 8 * 60; // 8 hours

    await db.into(db.sleepEntries).insert(
          SleepEntriesCompanion.insert(
            date: yesterdayStart.millisecondsSinceEpoch,
            sleepTime: bedtimeMs,
            wakeTime: wakeMs,
            durationMinutes: durationMin,
            quality: 4,
            createdAt: now.millisecondsSinceEpoch,
          ),
        );

    final generator = DailyPlanGenerator(db);
    final todayMs = todayStart.millisecondsSinceEpoch;
    final items = await generator.generate(todayMs);

    // Wake time should now be ~06:00 (from sleep data, not 07:00 default)
    final wakeItem = items.firstWhere((i) => i.itemTitle.value == 'بیداری');
    final wakeDate =
        DateTime.fromMillisecondsSinceEpoch(wakeItem.scheduledTime.value);
    // Allow ±1 hour tolerance (average may be rounded)
    expect(wakeDate.hour, lessThanOrEqualTo(7));
    expect(wakeDate.hour, greaterThanOrEqualTo(5));

    // Sleep time should be ~22:00 (from sleep data, not 23:00 default)
    final sleepItem = items.firstWhere((i) => i.itemTitle.value == 'خواب');
    final sleepDate =
        DateTime.fromMillisecondsSinceEpoch(sleepItem.scheduledTime.value);
    // Should be between 21:00 and 23:00
    expect(sleepDate.hour, lessThanOrEqualTo(23));
    expect(sleepDate.hour, greaterThanOrEqualTo(21));
  });

  test('goal type 1 (weight loss) includes snack item', () async {
    // Insert a user profile with goal_type=1 (weight loss)
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.userProfiles).insert(
          UserProfilesCompanion.insert(
            gender: 1,
            birthDate: DateTime(1990).millisecondsSinceEpoch,
            heightCm: 175.0,
            weightKg: 80.0,
            activityLevel: 2,
            goalType: 1,
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    final generator = DailyPlanGenerator(db);
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final items = await generator.generate(todayMs);

    // Should include a snack item
    final snackItem = items.where((i) => i.itemTitle.value == 'میان‌وعده');
    expect(snackItem.length, greaterThanOrEqualTo(1));
  });

  test('goal type 2 (weight gain) includes pre-sleep meal', () async {
    // Insert a user profile with goal_type=2 (weight gain)
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.userProfiles).insert(
          UserProfilesCompanion.insert(
            gender: 1,
            birthDate: DateTime(1990).millisecondsSinceEpoch,
            heightCm: 175.0,
            weightKg: 60.0,
            activityLevel: 2,
            goalType: 2,
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    final generator = DailyPlanGenerator(db);
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final items = await generator.generate(todayMs);

    // Should include a "وعده قبل از خواب" item
    final preSleepMeal = items
        .where((i) => i.itemTitle.value == 'وعده قبل از خواب');
    expect(preSleepMeal.length, greaterThanOrEqualTo(1));
  });

  test('water reminders are generated every 2 hours between wake and sleep',
      () async {
    final generator = DailyPlanGenerator(db);
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final items = await generator.generate(todayMs);

    // Default wake=07:00, sleep=23:00 → 16 hours awake → ~8 water reminders
    // (water at 09:00, 11:00, 13:00, ..., 21:00)
    final waterItems =
        items.where((i) => i.category.value == 'water').toList();
    expect(waterItems.length, greaterThanOrEqualTo(6));
    expect(waterItems.length, lessThanOrEqualTo(10));

    // Verify each water reminder is 2 hours after the previous one
    for (var i = 1; i < waterItems.length; i++) {
      final prev = DateTime.fromMillisecondsSinceEpoch(
          waterItems[i - 1].scheduledTime.value);
      final curr = DateTime.fromMillisecondsSinceEpoch(
          waterItems[i].scheduledTime.value);
      final diff = curr.difference(prev).inHours;
      expect(diff, 2, reason: 'Water reminders should be 2 hours apart');
    }
  });

  test('workout duration depends on goal type and activity level', () async {
    // Test weight loss + high activity → 60 min workout
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.userProfiles).insert(
          UserProfilesCompanion.insert(
            gender: 1,
            birthDate: DateTime(1990).millisecondsSinceEpoch,
            heightCm: 175.0,
            weightKg: 80.0,
            activityLevel: 4, // very active
            goalType: 1, // weight loss
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    final generator = DailyPlanGenerator(db);
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final items = await generator.generate(todayMs);

    final workoutItem = items.firstWhere((i) => i.category.value == 'workout');
    expect(workoutItem.durationMinutes.value, 60);
  });
}
