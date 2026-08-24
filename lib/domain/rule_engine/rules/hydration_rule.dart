import '../rule_base.dart';

/// قانون ارزیابی مصرف آب
///
/// مقدار آب مصرفی را با هدف مقایسه می‌کند:
/// - ≥۱۰۰٪ هدف: موفقیت
/// - ≥۷۵٪ هدف: هشدار
/// - <۷۵٪ هدف: خطا
class HydrationRule extends Rule {
  @override
  String get ruleId => 'hydration';

  @override
  String get titleFa => 'مصرف آب';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    final water = context.totalWaterMl;
    final target = context.waterTargetMl;

    // عدم وجود داده
    if (water == null) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'hydration',
        titleFa: 'مصرف آب',
        messageFa: 'داده مصرف آب ثبت نشده است',
        severity: RuleSeverity.error,
        recommendation: 'مصرف آب خود را در طول روز ثبت کنید',
      );
    }

    // بدون هدف → حداقل ۲۰۰۰ میلی‌لیتر
    final effectiveTarget = target ?? 2000.0;
    final ratio = water / effectiveTarget;

    // ≥۱۰۰٪
    if (ratio >= 1.0) {
      return const RuleEvaluation(
        isSatisfied: true,
        ruleId: 'hydration',
        titleFa: 'مصرف آب',
        messageFa: 'آب کافی',
        severity: RuleSeverity.success,
        recommendation: 'به همین روال ادامه دهید',
      );
    }

    // ≥۷۵٪
    if (ratio >= 0.75) {
      return RuleEvaluation(
        isSatisfied: false,
        ruleId: 'hydration',
        titleFa: 'مصرف آب',
        messageFa: 'کمی آب بیشتری بنوشید',
        severity: RuleSeverity.warning,
        recommendation: 'حدود ${((effectiveTarget - water) / 250).ceil()} لیوان آب دیگر بنوشید',
      );
    }

    // <۷۵٪
    return RuleEvaluation(
      isSatisfied: false,
      ruleId: 'hydration',
      titleFa: 'مصرف آب',
      messageFa: 'آب بدن کم است',
      severity: RuleSeverity.error,
      recommendation: 'حداقل ${((effectiveTarget - water) / 250).ceil()} لیوان آب بنوشید',
    );
  }
}
