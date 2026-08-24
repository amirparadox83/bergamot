import '../rule_base.dart';

/// قانون ارزیابی مدت خواب
///
/// بررسی می‌کند آیا مدت خواب در بازه مطلوب (۷ تا ۹ ساعت) قرار دارد.
/// - ۴۲۰–۵۴۰ دقیقه (۷–۹ ساعت): موفقیت
/// - ۳۶۰–۴۲۰ دقیقه (۶–۷ ساعت): هشدار
/// - کمتر از ۳۶۰ دقیقه (۶ ساعت): خطا
/// - بیش از ۵۴۰ دقیقه (۹ ساعت): هشدار (خواب بیش‌ازحد)
class SleepRule extends Rule {
  @override
  String get ruleId => 'sleep_duration';

  @override
  String get titleFa => 'کیفیت خواب';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    final duration = context.sleepDurationMinutes;

    // عدم وجود داده → خطا
    if (duration == null) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'sleep_duration',
        titleFa: 'کیفیت خواب',
        messageFa: 'داده خواب ثبت نشده است',
        severity: RuleSeverity.error,
        recommendation: 'مدت خواب خود را هر شب ثبت کنید',
      );
    }

    // خواب مطلوب: ۷ تا ۹ ساعت
    if (duration >= 420 && duration <= 540) {
      return const RuleEvaluation(
        isSatisfied: true,
        ruleId: 'sleep_duration',
        titleFa: 'کیفیت خواب',
        messageFa: 'خواب کافی',
        severity: RuleSeverity.success,
        recommendation: 'به همین روال ادامه دهید',
      );
    }

    // خواب بیش‌ازحد: بیشتر از ۹ ساعت
    if (duration > 540) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'sleep_duration',
        titleFa: 'کیفیت خواب',
        messageFa: 'خواب بیش از حد مطلوب',
        severity: RuleSeverity.warning,
        recommendation: 'خواب بیش از ۹ ساعت ممکن است نشانه خستگی باشد',
      );
    }

    // خواب کم: ۶ تا ۷ ساعت
    if (duration >= 360) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'sleep_duration',
        titleFa: 'کیفیت خواب',
        messageFa: 'خواب کمتر از حد مطلوب',
        severity: RuleSeverity.warning,
        recommendation: 'سعی کنید حداقل ۷ ساعت بخوابید',
      );
    }

    // خواب ناکافی: کمتر از ۶ ساعت
    return const RuleEvaluation(
      isSatisfied: false,
      ruleId: 'sleep_duration',
      titleFa: 'کیفیت خواب',
      messageFa: 'خواب ناکافی',
      severity: RuleSeverity.error,
      recommendation: 'خواب کمتر از ۶ ساعت به سلامتی آسیب می‌زند',
    );
  }
}
