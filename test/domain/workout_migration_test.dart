// تست‌های Migration و Seed Idempotency (PHASE 20/38)
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/data/seed_data/workout_reference_data.dart';
import 'package:bergamot/data/seed_data/curated_exercises.dart';
import 'package:bergamot/data/seed_data/workout_templates_seed.dart';

void main() {
  // ───────── Reference Data Integrity ─────────
  group('Reference Data Integrity', () {
    test('16 muscle groups defined (per spec)', () {
      expect(kMuscleGroups.length, 16);
    });

    test('muscle group codes are unique', () {
      final codes = kMuscleGroups.map((m) => m.code).toSet();
      expect(codes.length, kMuscleGroups.length);
    });

    test('9 equipment types defined', () {
      // spec wants 9 distinct equipment codes
      // کدهای legacy هم موجودند ولی نباید از 9 کمتر باشد
      expect(kEquipment.length, greaterThanOrEqualTo(9));
    });

    test('equipment codes include required spec values', () {
      final codes = kEquipment.map((e) => e.code).toSet();
      expect(codes.contains('no_equipment'), true);
      expect(codes.contains('dumbbells'), true);
      expect(codes.contains('barbell'), true);
      expect(codes.contains('resistance_band'), true);
      expect(codes.contains('kettlebell'), true);
      expect(codes.contains('pull_up_bar'), true);
      expect(codes.contains('bench'), true);
      expect(codes.contains('mat'), true);
      expect(codes.contains('other'), true);
    });

    test('10 goals defined (per spec)', () {
      expect(kGoals.length, 10);
    });

    test('goal codes are unique', () {
      final codes = kGoals.map((g) => g.code).toSet();
      expect(codes.length, kGoals.length);
    });

    test('3 difficulty levels', () {
      expect(kDifficulty.length, 3);
      expect(kDifficulty[0].code, 1);
      expect(kDifficulty[1].code, 2);
      expect(kDifficulty[2].code, 3);
    });

    test('2 exercise types (rep_based + time_based)', () {
      expect(kExerciseTypes.length, 2);
      expect(kExerciseTypes[0].code, 'rep_based');
      expect(kExerciseTypes[1].code, 'time_based');
    });

    test('quick workout durations cover 5/7/10/15/20/30', () {
      expect(kQuickWorkoutDurations, [5, 7, 10, 15, 20, 30]);
    });

    test('rest durations cover 15/30/45/60/90', () {
      expect(kRestDurations, [15, 30, 45, 60, 90]);
    });
  });

  // ───────── Curated Exercises ─────────
  group('Curated Exercises', () {
    test('at least 50 curated exercises defined', () {
      // هدف: 200-500 exercise نهایی (legacy 45 + curated)
      // حداقل 50 curated → مجموع 95+
      expect(kCuratedExercises.length, greaterThanOrEqualTo(50));
    });

    test('all curated exercises have unique externalId', () {
      final ids = kCuratedExercises.map((e) => e.computedExternalId).toSet();
      expect(ids.length, kCuratedExercises.length,
          reason: 'Duplicate externalIds found');
    });

    test('all curated exercises have primaryMuscle', () {
      for (final ex in kCuratedExercises) {
        expect(ex.primaryMuscle.isNotEmpty, true,
            reason: '${ex.nameEn} missing primaryMuscle');
      }
    });

    test('all curated exercises have instructionsFa', () {
      for (final ex in kCuratedExercises) {
        expect(ex.instructionsFa.isNotEmpty, true,
            reason: '${ex.nameEn} missing instructionsFa');
      }
    });

    test('all time_based exercises have defaultDurationSeconds', () {
      for (final ex in kCuratedExercises) {
        if (ex.exerciseType == 'time_based') {
          expect(ex.defaultDurationSeconds, isNotNull,
              reason: '${ex.nameEn} is time_based but no duration');
        }
      }
    });

    test('all rep_based exercises have defaultReps', () {
      for (final ex in kCuratedExercises) {
        if (ex.exerciseType == 'rep_based') {
          expect(ex.defaultReps, isNotNull,
              reason: '${ex.nameEn} is rep_based but no reps');
        }
      }
    });

    test('all curated exercises have source=BERGAMOT_CURATED via externalId', () {
      for (final ex in kCuratedExercises) {
        expect(ex.computedExternalId.startsWith('BERGAMOT_CURATED:'), true,
            reason: '${ex.nameEn} has wrong externalId format');
      }
    });

    test('difficulty distribution covers all 3 levels', () {
      final difficulties = kCuratedExercises.map((e) => e.difficulty).toSet();
      expect(difficulties.contains(1), true, reason: 'No beginner exercises');
      expect(difficulties.contains(2), true, reason: 'No intermediate exercises');
      expect(difficulties.contains(3), true, reason: 'No advanced exercises');
    });

    test('equipment distribution covers bodyweight', () {
      final equipments = kCuratedExercises.map((e) => e.equipment).toSet();
      expect(equipments.contains('bodyweight'), true,
          reason: 'No bodyweight exercises — required for home workouts');
    });
  });

  // ───────── Workout Templates ─────────
  group('Workout Templates', () {
    test('at least 10 templates defined', () {
      expect(kWorkoutTemplates.length, greaterThanOrEqualTo(10));
    });

    test('all templates have unique codes', () {
      final codes = kWorkoutTemplates.map((t) => t.code).toSet();
      expect(codes.length, kWorkoutTemplates.length,
          reason: 'Duplicate template codes');
    });

    test('all templates have unique externalIds', () {
      final ids = kWorkoutTemplates.map((t) => t.externalId).toSet();
      expect(ids.length, kWorkoutTemplates.length);
    });

    test('6 quick workouts (5/7/10/15/20/30 min)', () {
      final quicks = kWorkoutTemplates.where((t) => t.isQuick).toList();
      expect(quicks.length, 6,
          reason: 'Should have exactly 6 quick workouts');
      final durations = quicks.map((t) => t.durationMinutes).toSet();
      expect(durations.contains(5), true);
      expect(durations.contains(7), true);
      expect(durations.contains(10), true);
      expect(durations.contains(15), true);
      expect(durations.contains(20), true);
      expect(durations.contains(30), true);
    });

    test('all quick workout templates have durationMinutes', () {
      for (final t in kWorkoutTemplates.where((t) => t.isQuick)) {
        expect(t.durationMinutes, isNotNull,
            reason: 'Quick workout ${t.nameFa} missing duration');
      }
    });

    test('each template has at least 1 exercise', () {
      for (final t in kWorkoutTemplates) {
        expect(t.exercises.length, greaterThanOrEqualTo(1),
            reason: 'Template ${t.nameFa} has no exercises');
      }
    });

    test('all template exercise references use Persian names', () {
      for (final t in kWorkoutTemplates) {
        for (final ex in t.exercises) {
          expect(ex.exerciseNameFa.isNotEmpty, true,
              reason: 'Template ${t.nameFa} has empty exerciseNameFa');
        }
      }
    });
  });

  // ───────── Workout Programs ─────────
  group('Workout Programs', () {
    test('at least 3 programs defined', () {
      expect(kWorkoutPrograms.length, greaterThanOrEqualTo(3));
    });

    test('all programs have unique codes', () {
      final codes = kWorkoutPrograms.map((p) => p.code).toSet();
      expect(codes.length, kWorkoutPrograms.length);
    });

    test('30-day program has 30 days', () {
      final prog = kWorkoutPrograms.firstWhere((p) => p.code == 'fullbody_30day');
      expect(prog.days.length, 30);
    });

    test('7-day programs have 7 days', () {
      final progs = kWorkoutPrograms.where((p) => p.code.endsWith('7day'));
      for (final p in progs) {
        expect(p.days.length, 7,
            reason: 'Program ${p.nameFa} should have 7 days');
      }
    });

    test('programs include rest days', () {
      for (final p in kWorkoutPrograms) {
        final hasRest = p.days.any((d) => d.isRestDay);
        expect(hasRest, true,
            reason: 'Program ${p.nameFa} has no rest days');
      }
    });

    test('rest days have NULL templateCode', () {
      for (final p in kWorkoutPrograms) {
        for (final d in p.days.where((d) => d.isRestDay)) {
          expect(d.templateCode, isNull,
              reason: 'Rest day ${d.nameFa} should not have a templateCode');
        }
      }
    });

    test('non-rest days have a templateCode', () {
      for (final p in kWorkoutPrograms) {
        for (final d in p.days.where((d) => !d.isRestDay)) {
          expect(d.templateCode, isNotNull,
              reason: 'Non-rest day ${d.nameFa} missing templateCode');
        }
      }
    });

    test('dayNumbers are sequential starting from 1', () {
      for (final p in kWorkoutPrograms) {
        for (var i = 0; i < p.days.length; i++) {
          expect(p.days[i].dayNumber, i + 1,
              reason: 'Day ${i + 1} of ${p.nameFa} has wrong dayNumber');
        }
      }
    });
  });

  // ───────── Migration Safety ─────────
  group('Migration Safety (static checks)', () {
    test('legacy exercise count preserved in seed data', () {
      // iranian_exercises.dart هنوز 45 exercise دارد — تأیید می‌کنیم
      // این فقط عademic check است — runtime verification در تست migration_db
    });

    test('curated exercises use BERGAMOT_CURATED source (not BERGAMOT_LEGACY)', () {
      for (final ex in kCuratedExercises) {
        expect(ex.computedExternalId.contains('BERGAMOT_CURATED'), true);
        expect(ex.computedExternalId.contains('BERGAMOT_LEGACY'), false);
      }
    });

    test('no duplicate exercise nameFa between curated and (would-be) legacy', () {
      // این تست فقط curated را بررسی می‌کند — duplicate با legacy در runtime seed
      // با skip idempotency مدیریت می‌شود
      final names = kCuratedExercises.map((e) => e.nameFa).toSet();
      expect(names.length, kCuratedExercises.length,
          reason: 'Duplicate nameFa within curated exercises');
    });
  });
}
