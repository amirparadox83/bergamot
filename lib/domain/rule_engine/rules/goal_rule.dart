import '../rule_base.dart';

/// قانون پیشرفت هدف
///
/// همیشه سطح info برمی‌گرداند با توصیه درباره ثبات و پایداری.
/// این قانون اطلاعات‌محور است و نمره بالایی نمی‌دهد.
class GoalRule extends Rule {
  @override
  String get ruleId => 'goal_progress';

  @override
  String get titleFa => 'پیشرفت هدف';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    final goal = context.goalType;

    final goalMessageFa = switch (goal) {
      'lose' => 'هدف شما: کاهش وزن است. ثبات کلید موفقیت است',
      'gain' => 'هدف شما: افزایش عضله است. ثبات کلید موفقیت است',
      'maintain' => 'هدف شما: حفظ وزن است. ادامه دهید',
      _ => 'هدفی تنظیم نشده. برای پیشرفت، هدف مشخص کنید',
    };

    return RuleEvaluation(
      isSatisfied: goal != null,
      ruleId: 'goal_progress',
      titleFa: 'پیشرفت هدف',
      messageFa: goalMessageFa,
      severity: RuleSeverity.info,
      recommendation: 'پایبندی مداوم مهم‌تر از تلاش‌های مقطعی است',
    );
  }
}
