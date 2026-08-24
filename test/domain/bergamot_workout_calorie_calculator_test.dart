// تست‌های BergamotWorkoutCalorieCalculator (PHASE 20/29)
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/data/database/bergamot_database.dart';
import 'package:bergamot/domain/entities/bergamot_workout_calorie_calculator.dart';

void main() {
  group('BergamotWorkoutCalorieCalculator', () {
    // Helper: ساخت Exercise با مقادیر مشخص
    Exercise makeExercise({
      String category = 'chest',
      int difficulty = 1,
      double? caloriesEstimatePerRep,
      bool isTimed = false,
    }) {
      return Exercise(
        id: 1,
        nameFa: 'تست',
        nameEn: 'Test',
        normalizedNameFa: 'تست',
        normalizedNameEn: 'test',
        category: category,
        equipment: 'bodyweight',
        difficulty: difficulty,
        instructionsFa: null,
        muscleGroups: 'chest',
        primaryMuscle: 'chest',
        exerciseType: isTimed ? 'time_based' : 'rep_based',
        isBodyweight: true,
        isTimed: isTimed,
        defaultSets: 3,
        defaultReps: 12,
        defaultDurationSeconds: isTimed ? 30 : null,
        restSeconds: 60,
        caloriesEstimatePerRep: caloriesEstimatePerRep,
        tips: null,
        commonMistakes: null,
        source: 'BERGAMOT_CURATED',
        externalId: 'test',
        imageAsset: null,
        videoUrl: null,
        isCustom: false,
        createdAt: 0,
        updatedAt: null,
      );
    }

    // ───────── calculateExerciseCalories ─────────
    group('calculateExerciseCalories', () {
      test('rep-based with caloriesEstimatePerRep — exact calc', () {
        // Push-up: 0.5 kcal/rep, 3 sets × 12 reps = 18 kcal
        final ex = makeExercise(caloriesEstimatePerRep: 0.5);
        final cal = BergamotWorkoutCalorieCalculator.calculateExerciseCalories(
          exercise: ex, sets: 3, reps: 12,
        );
        expect(cal, closeTo(18, 0.001));  // 0.5 × 12 × 3
      });

      test('time-based with caloriesEstimatePerRep — uses 30s = 1 rep rule', () {
        // Plank: 0.15 kcal/rep, 3 sets × 60s = 6 effective reps
        final ex = makeExercise(
          caloriesEstimatePerRep: 0.15,
          isTimed: true,
          category: 'core',
        );
        final cal = BergamotWorkoutCalorieCalculator.calculateExerciseCalories(
          exercise: ex, sets: 3, durationSeconds: 60,
        );
        // effectiveReps = ceil(60/30) = 2, total = 0.15 × 2 × 3 = 0.9
        expect(cal, closeTo(0.9, 0.001));
      });

      test('time-based 45 seconds — uses ceil', () {
        final ex = makeExercise(caloriesEstimatePerRep: 0.2, isTimed: true);
        final cal = BergamotWorkoutCalorieCalculator.calculateExerciseCalories(
          exercise: ex, sets: 1, durationSeconds: 45,
        );
        // effectiveReps = ceil(45/30) = 2, total = 0.2 × 2 × 1 = 0.4
        expect(cal, closeTo(0.4, 0.001));
      });

      test('zero sets → zero calories', () {
        final ex = makeExercise(caloriesEstimatePerRep: 0.5);
        final cal = BergamotWorkoutCalorieCalculator.calculateExerciseCalories(
          exercise: ex, sets: 0, reps: 12,
        );
        expect(cal, 0);
      });

      test('NULL caloriesEstimatePerRep → fallback based on category', () {
        // Chest, difficulty 2 → 0.3 kcal/rep fallback
        final ex = makeExercise(
          caloriesEstimatePerRep: null,
          category: 'chest',
          difficulty: 2,
        );
        final cal = BergamotWorkoutCalorieCalculator.calculateExerciseCalories(
          exercise: ex, sets: 3, reps: 10,
        );
        expect(cal, closeTo(9, 0.001));  // 0.3 × 10 × 3
      });

      test('cardio fallback uses higher per-rep value', () {
        final ex = makeExercise(
          caloriesEstimatePerRep: null,
          category: 'cardio',
          difficulty: 3,
        );
        final cal = BergamotWorkoutCalorieCalculator.calculateExerciseCalories(
          exercise: ex, sets: 4, reps: 15,
        );
        // cardio diff 3 → 0.6 × 15 × 4 = 36
        expect(cal, closeTo(36, 0.001));
      });

      test('stretch fallback very low', () {
        final ex = makeExercise(
          caloriesEstimatePerRep: null,
          category: 'stretch',
        );
        final cal = BergamotWorkoutCalorieCalculator.calculateExerciseCalories(
          exercise: ex, sets: 2, reps: 1,
        );
        // stretch → 0.08 × 1 × 2 = 0.16
        expect(cal, closeTo(0.16, 0.001));
      });
    });

    // ───────── calculateWorkoutCalories ─────────
    group('calculateWorkoutCalories (sum)', () {
      test('sums multiple exercises', () {
        final items = [
          (
            exercise: makeExercise(caloriesEstimatePerRep: 0.5),
            sets: 3, reps: 12, durationSeconds: null, weightKg: null,
          ),
          (
            exercise: makeExercise(caloriesEstimatePerRep: 0.3),
            sets: 2, reps: 10, durationSeconds: null, weightKg: null,
          ),
        ];
        final cal = BergamotWorkoutCalorieCalculator.calculateWorkoutCalories(items);
        // 0.5×12×3 + 0.3×10×2 = 18 + 6 = 24
        expect(cal, closeTo(24, 0.001));
      });

      test('empty items → zero calories', () {
        final cal = BergamotWorkoutCalorieCalculator.calculateWorkoutCalories([]);
        expect(cal, 0);
      });
    });

    // ───────── calculateWorkoutStats ─────────
    group('calculateWorkoutStats', () {
      test('sums sets and reps correctly', () {
        final items = [
          (sets: 3, reps: 12),
          (sets: 4, reps: 10),
          (sets: 2, reps: 15),
        ];
        final stats = BergamotWorkoutCalorieCalculator.calculateWorkoutStats(items);
        expect(stats.totalSets, 9);  // 3+4+2
        expect(stats.totalReps, 36 + 40 + 30);  // 3*12 + 4*10 + 2*15 = 106
      });

      test('NULL reps only contributes sets', () {
        final items = [
          (sets: 3, reps: 12),
          (sets: 2, reps: null),  // Plank (time-based)
        ];
        final stats = BergamotWorkoutCalorieCalculator.calculateWorkoutStats(items);
        expect(stats.totalSets, 5);
        expect(stats.totalReps, 36);  // only from rep-based
      });
    });
  });
}
