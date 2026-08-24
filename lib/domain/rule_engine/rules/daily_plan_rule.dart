import '../rule_base.dart';

/// قانون برنامه روزانه
///
/// این قانون برای تولید برنامه روزانه استفاده می‌شود، نه ارزیابی.
/// ارزیابی آن همیشه سطح اطلاعات برمی‌گرداند و روی امتیاز تأثیر نمی‌گذارد.
class DailyPlanRule extends Rule {
  @override
  String get ruleId => 'daily_plan';

  @override
  String get titleFa => 'برنامه روزانه';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    return const RuleEvaluation(
      isSatisfied: false,
      ruleId: 'daily_plan',
      titleFa: 'برنامه روزانه',
      messageFa: 'برنامه روزانه برای امروز ساخته نشده',
      severity: RuleSeverity.info,
      recommendation: 'ساخت برنامه روزانه به شما کمک می‌کند نظم بیشتری داشته باشید',
    );
  }
}
