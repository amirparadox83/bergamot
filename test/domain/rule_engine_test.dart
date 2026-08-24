// تست‌های Rule Engine Bergamot (PHASE 22.2)
//
// برای هر Rule:
//   1. یک تست برای حالت trigger (قانون فعال می‌شود)
//   2. یک تست برای حالت no-trigger (قانون برآورده شده)
//
// همه ورودی‌ها و خروجی‌های مورد انتظار به‌صورت real (نه تخمین) کشف شده‌اند
// با خواندن کد واقعی هر rule در lib/domain/rule_engine/rules/.
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/domain/rule_engine/rule_base.dart';
import 'package:bergamot/domain/rule_engine/rules/sleep_rule.dart';
import 'package:bergamot/domain/rule_engine/rules/hydration_rule.dart';
import 'package:bergamot/domain/rule_engine/rules/nutrition_rule.dart';
import 'package:bergamot/domain/rule_engine/rules/workout_rule.dart';
import 'package:bergamot/domain/rule_engine/rules/recovery_rule.dart';
import 'package:bergamot/domain/rule_engine/rules/goal_rule.dart';
import 'package:bergamot/domain/rule_engine/rules/progress_rule.dart';
import 'package:bergamot/domain/rule_engine/rules/daily_plan_rule.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────
  // SleepRule
  // ────────────────────────────────────────────────────────────────────────
  group('SleepRule', () {
    final rule = SleepRule();

    test('trigger — sleep less than 6h (300 min) → error', () {
      // Code path: duration < 360 → error
      final r = rule.evaluate(const RuleContext(sleepDurationMinutes: 300));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
      expect(r.ruleId, 'sleep_duration');
    });

    test('trigger — no sleep data → error', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
    });

    test('no-trigger — 7-9h (420-540 min) → success', () {
      final r = rule.evaluate(const RuleContext(sleepDurationMinutes: 480));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('boundary — exactly 420 min (7h) → success', () {
      final r = rule.evaluate(const RuleContext(sleepDurationMinutes: 420));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('boundary — exactly 540 min (9h) → success', () {
      final r = rule.evaluate(const RuleContext(sleepDurationMinutes: 540));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('warning — 6-7h (360-420 min) → warning', () {
      final r = rule.evaluate(const RuleContext(sleepDurationMinutes: 400));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
    });

    test('warning — over 9h (550 min) → warning (oversleep)', () {
      final r = rule.evaluate(const RuleContext(sleepDurationMinutes: 550));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // HydrationRule
  // ────────────────────────────────────────────────────────────────────────
  group('HydrationRule', () {
    final rule = HydrationRule();

    test('trigger — no water data → error', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
    });

    test('trigger — water < 75% of target → error', () {
      // target 2000, water 1000 → ratio 0.5 < 0.75 → error
      final r = rule.evaluate(const RuleContext(
        totalWaterMl: 1000,
        waterTargetMl: 2000,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
    });

    test('no-trigger — water >= 100% of target → success', () {
      final r = rule.evaluate(const RuleContext(
        totalWaterMl: 2500,
        waterTargetMl: 2000,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('boundary — water exactly equals target → success', () {
      final r = rule.evaluate(const RuleContext(
        totalWaterMl: 2000,
        waterTargetMl: 2000,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('warning — water 75-99% of target → warning', () {
      // ratio 0.85 → warning
      final r = rule.evaluate(const RuleContext(
        totalWaterMl: 1700,
        waterTargetMl: 2000,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
    });

    test('default target when waterTargetMl is null → 2000 ml', () {
      // water 1500, no target → effectiveTarget 2000, ratio 0.75 → warning
      final r = rule.evaluate(const RuleContext(totalWaterMl: 1500));
      // 1500/2000 = 0.75 — boundary case (>= 0.75)
      expect(r.severity, RuleSeverity.warning);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // NutritionRule
  // ────────────────────────────────────────────────────────────────────────
  group('NutritionRule', () {
    final rule = NutritionRule();

    test('trigger — no calorie data → error', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
    });

    test('trigger — no target → info (not error)', () {
      final r = rule.evaluate(const RuleContext(totalCalories: 2000));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.info);
    });

    test('trigger — calories >20% over target → error', () {
      // target 2000, calories 2500 → 25% deviation → error
      final r = rule.evaluate(const RuleContext(
        totalCalories: 2500,
        calorieTarget: 2000,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
    });

    test('trigger — calories >20% under target → error', () {
      // target 2000, calories 1500 → 25% deviation → error
      final r = rule.evaluate(const RuleContext(
        totalCalories: 1500,
        calorieTarget: 2000,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
    });

    test('no-trigger — calories within 10% → success', () {
      // target 2000, calories 2050 → 2.5% deviation → success
      final r = rule.evaluate(const RuleContext(
        totalCalories: 2050,
        calorieTarget: 2000,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('boundary — exactly 10% deviation → success', () {
      // target 2000, calories 2200 → 10% deviation → success
      final r = rule.evaluate(const RuleContext(
        totalCalories: 2200,
        calorieTarget: 2000,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('warning — 10-20% deviation → warning', () {
      // target 2000, calories 2300 → 15% deviation → warning
      final r = rule.evaluate(const RuleContext(
        totalCalories: 2300,
        calorieTarget: 2000,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
    });

    test('zero target → info (not crash, not divide by zero)', () {
      final r = rule.evaluate(const RuleContext(
        totalCalories: 2000,
        calorieTarget: 0,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.info);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // WorkoutRule
  // ────────────────────────────────────────────────────────────────────────
  group('WorkoutRule', () {
    final rule = WorkoutRule();

    test('no-trigger — workout done → success', () {
      final r = rule.evaluate(const RuleContext(hasWorkout: true));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('trigger — no workout → warning', () {
      final r = rule.evaluate(const RuleContext(hasWorkout: false));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
    });

    test('trigger — unknown workout status → info', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.info);
    });

    test('trigger — 4+ consecutive days → warning (need rest)', () {
      final r = rule.evaluate(const RuleContext(
        hasWorkout: true,
        consecutiveWorkoutDays: 4,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
      expect(r.messageFa, contains('استراحت'));
    });

    test('boundary — exactly 4 consecutive days → warning', () {
      final r = rule.evaluate(const RuleContext(
        hasWorkout: true,
        consecutiveWorkoutDays: 4,
      ));
      expect(r.severity, RuleSeverity.warning);
    });

    test('no-trigger — 3 consecutive days → success', () {
      final r = rule.evaluate(const RuleContext(
        hasWorkout: true,
        consecutiveWorkoutDays: 3,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // RecoveryRule
  // ────────────────────────────────────────────────────────────────────────
  group('RecoveryRule', () {
    final rule = RecoveryRule();

    test('no-trigger — good sleep + no workout → excellent recovery (success)', () {
      final r = rule.evaluate(const RuleContext(
        sleepDurationMinutes: 480,
        hasWorkout: false,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('no-trigger — good sleep + workout → acceptable recovery (success)', () {
      final r = rule.evaluate(const RuleContext(
        sleepDurationMinutes: 480,
        hasWorkout: true,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });

    test('trigger — poor sleep + workout → error (insufficient recovery)', () {
      final r = rule.evaluate(const RuleContext(
        sleepDurationMinutes: 300,  // < 360
        hasWorkout: true,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.error);
    });

    test('trigger — poor sleep + no workout → warning', () {
      final r = rule.evaluate(const RuleContext(
        sleepDurationMinutes: 300,
        hasWorkout: false,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
    });

    test('trigger — medium sleep (360-420) → warning', () {
      // 400 min is between 360 and 420 → falls into the "medium sleep" branch
      final r = rule.evaluate(const RuleContext(
        sleepDurationMinutes: 400,
        hasWorkout: false,
      ));
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.warning);
    });

    test('trigger — no data at all → info', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.info);
    });

    test('boundary — exactly 420 min sleep + workout → success', () {
      // goodSleepThreshold = 420; sleep = 420 → goodSleep=true
      final r = rule.evaluate(const RuleContext(
        sleepDurationMinutes: 420,
        hasWorkout: true,
      ));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.success);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // GoalRule
  // ────────────────────────────────────────────────────────────────────────
  group('GoalRule', () {
    final rule = GoalRule();

    test('no-trigger — goal = lose → isSatisfied true', () {
      // Code: isSatisfied = goal != null → true
      // severity is always info
      final r = rule.evaluate(const RuleContext(goalType: 'lose'));
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.info);
      expect(r.messageFa, contains('کاهش وزن'));
    });

    test('no-trigger — goal = gain → isSatisfied true', () {
      final r = rule.evaluate(const RuleContext(goalType: 'gain'));
      expect(r.isSatisfied, true);
      expect(r.messageFa, contains('افزایش عضله'));
    });

    test('no-trigger — goal = maintain → isSatisfied true', () {
      final r = rule.evaluate(const RuleContext(goalType: 'maintain'));
      expect(r.isSatisfied, true);
      expect(r.messageFa, contains('حفظ وزن'));
    });

    test('trigger — no goal → isSatisfied false', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.info);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // ProgressRule
  // ────────────────────────────────────────────────────────────────────────
  group('ProgressRule', () {
    final rule = ProgressRule();

    test('always returns info, isSatisfied true', () {
      // Code always returns the same static evaluation
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, true);
      expect(r.severity, RuleSeverity.info);
    });

    test('ruleId is weekly_progress', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.ruleId, 'weekly_progress');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // DailyPlanRule
  // ────────────────────────────────────────────────────────────────────────
  group('DailyPlanRule', () {
    final rule = DailyPlanRule();

    test('always returns info, isSatisfied false (plan not generated)', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.isSatisfied, false);
      expect(r.severity, RuleSeverity.info);
    });

    test('ruleId is daily_plan', () {
      final r = rule.evaluate(const RuleContext());
      expect(r.ruleId, 'daily_plan');
    });
  });
}
