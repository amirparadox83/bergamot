import '../rule_base.dart';

/// قانون پیشرفت هفتگی
///
/// همیشه سطح info برمی‌گرداند.
/// در آینده می‌تواند با داده‌های تاریخی تکمیل شود.
class ProgressRule extends Rule {
  @override
  String get ruleId => 'weekly_progress';

  @override
  String get titleFa => 'پیشرفت هفتگی';

  @override
  RuleEvaluation evaluate(RuleContext context) {
    return const RuleEvaluation(
      isSatisfied: true,
      ruleId: 'weekly_progress',
      titleFa: 'پیشرفت هفتگی',
      messageFa: 'ثبت مداوم داده‌ها به بررسی پیشرفت کمک می‌کند',
      severity: RuleSeverity.info,
      recommendation: 'هر روز اطلاعات خود را ثبت کنید تا روند پیشرفت قابل بررسی باشد',
    );
  }
}
