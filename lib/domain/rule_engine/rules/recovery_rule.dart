import '../rule_base.dart';

/// قانون ارزیابی بازیابی بدن
///
/// ترکیب خواب و تمرین:
/// - خواب خوب + بدون تمرین: بازیابی عالی (موفقیت)
/// - خواب ضعیف + تمرین: هشدار بازیابی
/// - خواب خوب + تمرین: بازیابی متوسط
/// - خواب ضعیف + بدون تمرین: هشدار
/// - بدون داده: اطلاعات
class RecoveryRule extends Rule {
  @override
  String get ruleId => 'recovery';

  @override
  String get titleFa => 'بازیابی';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    final sleep = context.sleepDurationMinutes;
    final hasWorkout = context.hasWorkout;

    const goodSleepThreshold = 420; // ۷ ساعت

    // بدون داده
    if (sleep == null && hasWorkout == null) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'recovery',
        titleFa: 'بازیابی',
        messageFa: 'داده بازیابی کافی نیست',
        severity: RuleSeverity.info,
        recommendation: 'خواب و تمرین خود را ثبت کنید تا وضعیت بازیابی مشخص شود',
      );
    }

    final goodSleep = sleep != null && sleep >= goodSleepThreshold;
    final poorSleep = sleep != null && sleep < 360;
    final didWorkout = hasWorkout == true;

    // خواب خوب + بدون تمرین = بازیابی عالی
    if (goodSleep && !didWorkout) {
      return const RuleEvaluation(
        isSatisfied: true,
        ruleId: 'recovery',
        titleFa: 'بازیابی',
        messageFa: 'بازیابی عالی',
        severity: RuleSeverity.success,
        recommendation: 'بدن شما به خوبی استراحت کرده است',
      );
    }

    // خواب ضعیف + تمرین = هشدار
    if (poorSleep && didWorkout) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'recovery',
        titleFa: 'بازیابی',
        messageFa: 'بازیابی ناکافی پس از تمرین',
        severity: RuleSeverity.error,
        recommendation: 'خواب ناکافی بعد از تمرین مانع ریکاوری عضلات می‌شود',
      );
    }

    // خواب خوب + تمرین = بازیابی قابل‌قبول
    if (goodSleep && didWorkout) {
      return const RuleEvaluation(
        isSatisfied: true,
        ruleId: 'recovery',
        titleFa: 'بازیابی',
        messageFa: 'بازیابی قابل‌قبول',
        severity: RuleSeverity.success,
        recommendation: 'خواب کافی بعد از تمرین کمک به ریکاوری می‌کند',
      );
    }

    // خواب ضعیف + بدون تمرین
    if (poorSleep && !didWorkout) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'recovery',
        titleFa: 'بازیابی',
        messageFa: 'خواب ناکافی',
        severity: RuleSeverity.warning,
        recommendation: 'حتی بدون تمرین هم به خواب کافی نیاز دارید',
      );
    }

    // خواب متوسط (۳۶۰–۴۲۰) — هر دو حالت تمرین
    return RuleEvaluation(
      isSatisfied: false,
      ruleId: 'recovery',
      titleFa: 'بازیابی',
      messageFa: didWorkout
          ? 'بازیابی متوسط پس از تمرین'
          : 'بازیابی متوسط',
      severity: RuleSeverity.warning,
      recommendation: didWorkout
          ? 'خواب بیشتری برای ریکاوری بهتر لازم است'
          : 'سعی کنید خواب خود را به ۷ ساعت برسانید',
    );
  }
}
