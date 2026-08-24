import '../rule_base.dart';

/// قانون ارزیابی تمرین
///
/// - انجام تمرین: موفقیت
/// - عدم تمرین بدون علت خاص: هشدار
/// - ۴+ روز متوالی تمرین: هشدار نیاز به استراحت
class WorkoutRule extends Rule {
  @override
  String get ruleId => 'workout_done';

  @override
  String get titleFa => 'تمرین';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    final hasWorkout = context.hasWorkout;
    final consecutiveDays = context.consecutiveWorkoutDays;

    // بررسی استراحت — ۴+ روز متوالی تمرین
    if (hasWorkout == true && consecutiveDays != null && consecutiveDays >= 4) {
      return RuleEvaluation(
        isSatisfied: false,
        ruleId: 'workout_done',
        titleFa: 'تمرین',
        messageFa: 'نیاز به استراحت دارید',
        severity: RuleSeverity.warning,
        recommendation: '$consecutiveDays روز متوالی تمرین کرده‌اید. یک روز استراحت داشته باشید.',
      );
    }

    // تمرین انجام شده
    if (hasWorkout == true) {
      return const RuleEvaluation(
        isSatisfied: true,
        ruleId: 'workout_done',
        titleFa: 'تمرین',
        messageFa: 'تمرین انجام شد',
        severity: RuleSeverity.success,
        recommendation: 'آفرین! به همین روال ادامه دهید',
      );
    }

    // عدم وجود داده
    if (hasWorkout == null) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'workout_done',
        titleFa: 'تمرین',
        messageFa: 'وضعیت تمرین مشخص نیست',
        severity: RuleSeverity.info,
        recommendation: 'تمرین‌های خود را ثبت کنید',
      );
    }

    // عدم تمرین
    return const RuleEvaluation(
      isSatisfied: false,
      ruleId: 'workout_done',
      titleFa: 'تمرین',
      messageFa: 'امروز تمرینی انجام نشد',
      severity: RuleSeverity.warning,
      recommendation: 'حتی یک تمرین کوتاه هم بهتر از هیچ است',
    );
  }
}
