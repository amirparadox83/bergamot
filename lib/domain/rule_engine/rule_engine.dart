import 'rule_base.dart';
import 'rules/sleep_rule.dart';
import 'rules/hydration_rule.dart';
import 'rules/nutrition_rule.dart';
import 'rules/workout_rule.dart';
import 'rules/recovery_rule.dart';
import 'rules/goal_rule.dart';
import 'rules/progress_rule.dart';

/// موتور قوانین برگاموت
///
/// Receives a [RuleContext] and returns a list of [RuleEvaluation]s.
/// Also calculates a weighted [LifestyleScore] (0–100).
///
/// Weights:
/// - خواب (sleep): ۲۵٪
/// - تغذیه (nutrition): ۲۵٪
/// - تمرین (workout): ۲۰٪
/// - آب (hydration): ۱۵٪
/// - بازیابی (recovery): ۱۵٪
///
/// Score mapping per severity:
/// - success = ۱۰۰٪
/// - warning = ۶۰٪
/// - error = ۰٪
/// - info = ۸۰٪
///
/// TODO: Make weights configurable per-user (stored in profile or goals).
/// TODO: Add composite rules that depend on multiple data points (e.g.
///   "if you worked out, protein target should be higher").
/// TODO: Consider making `info` severity contribute a partial score
///   (currently 80% which is high for informational messages).
class BergamotRuleEngine {
  final List<Rule> _rules;

  BergamotRuleEngine({List<Rule>? rules})
      : _rules = rules ?? const [];

  /// All registered rules.
  List<Rule> get rules => List.unmodifiable(_rules);

  /// Factory with all 8 default rules.
  factory BergamotRuleEngine.defaultRules() => BergamotRuleEngine(
          rules: [
            SleepRule(),
            HydrationRule(),
            NutritionRule(),
            WorkoutRule(),
            RecoveryRule(),
            GoalRule(),
            ProgressRule(),
          ],
        );

  /// Evaluate all rules against the given [context].
  List<RuleEvaluation> evaluateAll(RuleContext context) =>
      _rules.map((rule) => rule.evaluate(context)).toList();

  // ── Scoring ──────────────────────────────────────────────────────────

  /// Map from [ruleId] to category weight.
  static const Map<String, double> _categoryWeights = {
    'sleep_duration': 0.25,
    'nutrition_calories': 0.25,
    'workout_done': 0.20,
    'hydration': 0.15,
    'recovery': 0.15,
    // info-only rules don't contribute to score
    'goal_progress': 0.0,
    'weekly_progress': 0.0,
  };

  /// Score value for each severity (0.0 – 1.0).
  static double _severityScore(RuleSeverity severity) => switch (severity) {
        RuleSeverity.success => 1.0,
        RuleSeverity.warning => 0.6,
        RuleSeverity.info => 0.8,
        RuleSeverity.error => 0.0,
      };

  /// Map from [ruleId] to category name.
  static const Map<String, String> _categoryNames = {
    'sleep_duration': 'sleep',
    'nutrition_calories': 'nutrition',
    'workout_done': 'workout',
    'hydration': 'hydration',
    'recovery': 'recovery',
  };

  /// Calculate the overall lifestyle score (0–100) from evaluations.
  double calculateLifestyleScore(List<RuleEvaluation> evaluations) {
    double total = 0.0;

    for (final eval in evaluations) {
      final weight = _categoryWeights[eval.ruleId] ?? 0.0;
      if (weight > 0) {
        total += _severityScore(eval.severity) * weight;
      }
    }

    return (total * 100).clamp(0.0, 100.0);
  }

  /// Calculate per-category scores (0–100).
  ///
  /// Returns a map of category name → score.
  /// Categories: sleep, nutrition, workout, hydration, recovery.
  Map<String, double> calculateCategoryScores(
    List<RuleEvaluation> evaluations,
  ) {
    final scores = <String, double>{};

    for (final eval in evaluations) {
      final category = _categoryNames[eval.ruleId];
      if (category == null) continue;

      // Each category has exactly one rule in the default set.
      scores[category] = _severityScore(eval.severity) * 100;
    }

    return scores;
  }
}
