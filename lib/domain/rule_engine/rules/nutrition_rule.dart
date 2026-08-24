import '../rule_base.dart';

/// قانون ارزیابی کالری دریافتی
///
/// کالری مصرفی را با هدف مقایسه می‌کند:
/// - within 10% of target: موفقیت
/// - within 20% of target: هشدار
/// - >20% over or under: خطا
class NutritionRule extends Rule {
  @override
  String get ruleId => 'nutrition_calories';

  @override
  String get titleFa => 'تغذیه';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    final calories = context.totalCalories;
    final target = context.calorieTarget;

    // عدم وجود داده
    if (calories == null) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'nutrition_calories',
        titleFa: 'تغذیه',
        messageFa: 'داده تغذیه ثبت نشده است',
        severity: RuleSeverity.error,
        recommendation: 'غذاهای مصرفی خود را ثبت کنید',
      );
    }

    // بدون هدف → خطای اطلاعاتی
    if (target == null || target <= 0) {
      return const RuleEvaluation(
        isSatisfied: false,
        ruleId: 'nutrition_calories',
        titleFa: 'تغذیه',
        messageFa: 'هدف کالری تنظیم نشده است',
        severity: RuleSeverity.info,
        recommendation: 'ابتدا هدف کالری روزانه را تنظیم کنید',
      );
    }

    final deviation = (calories - target).abs() / target;

    // within 10%
    if (deviation <= 0.10) {
      return const RuleEvaluation(
        isSatisfied: true,
        ruleId: 'nutrition_calories',
        titleFa: 'تغذیه',
        messageFa: 'کالری مصرفی مناسب است',
        severity: RuleSeverity.success,
        recommendation: 'به همین روال ادامه دهید',
      );
    }

    // within 20%
    if (deviation <= 0.20) {
      final direction = calories > target ? 'بیشتر' : 'کمتر';
      return RuleEvaluation(
        isSatisfied: false,
        ruleId: 'nutrition_calories',
        titleFa: 'تغذیه',
        messageFa: 'کالری مصرفی $direction از حد مجاز است',
        severity: RuleSeverity.warning,
        recommendation: calories > target
            ? 'کالری دریافتی را کمی کاهش دهید'
            : 'کالری دریافتی را کمی افزایش دهید',
      );
    }

    // >20%
    final direction = calories > target ? 'بیشتر' : 'کمتر';
    return RuleEvaluation(
      isSatisfied: false,
      ruleId: 'nutrition_calories',
      titleFa: 'تغذیه',
      messageFa: 'انحراف شدید کالری: $direction از هدف',
      severity: RuleSeverity.error,
      recommendation: calories > target
          ? 'کالری دریافتی به‌شدت بالاتر از هدف است'
          : 'کالری دریافتی به‌شدت پایین‌تر از هدف است',
    );
  }
}
