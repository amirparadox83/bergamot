// امتیاز سبک زندگی — see [LifestyleScore] class below.

import '../rule_engine/rule_base.dart';

/// نتیجه امتیاز سبک زندگی روزانه
class LifestyleScore {
  /// امتیاز کلی (۰ تا ۱۰۰)
  final double overall;

  /// امتیاز خواب (۰ تا ۱۰۰)
  final double sleep;

  /// امتیاز تغذیه (۰ تا ۱۰۰)
  final double nutrition;

  /// امتیاز تمرین (۰ تا ۱۰۰)
  final double workout;

  /// امتیاز آب (۰ تا ۱۰۰)
  final double hydration;

  /// امتیاز بازیابی (۰ تا ۱۰۰)
  final double recovery;

  /// تاریخ محاسبه
  final DateTime date;

  /// لیست ارزیابی‌های قانون
  final List<RuleEvaluation> evaluations;

  const LifestyleScore({
    required this.overall,
    required this.sleep,
    required this.nutrition,
    required this.workout,
    required this.hydration,
    required this.recovery,
    required this.date,
    required this.evaluations,
  });

  /// Create an empty (zeroed) score for a given date.
  factory LifestyleScore.empty({DateTime? date}) => LifestyleScore(
        overall: 0,
        sleep: 0,
        nutrition: 0,
        workout: 0,
        hydration: 0,
        recovery: 0,
        date: date ?? DateTime.now(),
        evaluations: const [],
      );

  /// Serialize to map (suitable for database persistence).
  Map<String, dynamic> toMap() => {
        'overall': overall,
        'sleep': sleep,
        'nutrition': nutrition,
        'workout': workout,
        'hydration': hydration,
        'recovery': recovery,
        'date': date.millisecondsSinceEpoch,
        'evaluations': evaluations.map((e) => e.toMap()).toList(),
      };

  /// Deserialize from map.
  factory LifestyleScore.fromMap(Map<String, dynamic> map) => LifestyleScore(
        overall: (map['overall'] as num).toDouble(),
        sleep: (map['sleep'] as num).toDouble(),
        nutrition: (map['nutrition'] as num).toDouble(),
        workout: (map['workout'] as num).toDouble(),
        hydration: (map['hydration'] as num).toDouble(),
        recovery: (map['recovery'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        evaluations: (map['evaluations'] as List<dynamic>)
            .map(
              (e) => RuleEvaluation.fromMap(e as Map<String, dynamic>),
            )
            .toList(),
      );

  @override
  String toString() =>
      'LifestyleScore(overall: ${overall.toStringAsFixed(1)}, date: $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifestyleScore &&
          overall == other.overall &&
          sleep == other.sleep &&
          nutrition == other.nutrition &&
          workout == other.workout &&
          hydration == other.hydration &&
          recovery == other.recovery &&
          date == other.date &&
          _listEquals(evaluations, other.evaluations);

  @override
  int get hashCode => Object.hash(
        overall,
        sleep,
        nutrition,
        workout,
        hydration,
        recovery,
        date,
        Object.hashAll(evaluations),
      );

  static bool _listEquals(List<RuleEvaluation> a, List<RuleEvaluation> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
