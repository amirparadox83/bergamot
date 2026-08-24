/**
 * Base abstractions for the Bergamot Rule Engine.
 *
 * Pure Dart module — no Flutter dependencies.
 * All rules are deterministic and explainable.
 */

// ── Severity ─────────────────────────────────────────────────────────────

/// سطوح شدت ارزیابی قوانین
///
/// Determines how a rule result should be displayed and weighted in scoring.
enum RuleSeverity {
  /// اطلاعات عمومی — neutral informational feedback
  info,

  /// موفقیت — target met
  success,

  /// هشدار — partially met, needs attention
  warning,

  /// خطا — target not met
  error,
}

// ── RuleEvaluation ───────────────────────────────────────────────────────

/// نتیجه ارزیابی یک قانون
///
/// Immutable value object produced by [Rule.evaluate].
class RuleEvaluation {
  /// آیا قانون برآورده شده است
  final bool isSatisfied;

  /// شناسه یکتای قانون
  final String ruleId;

  /// عنوان فارسی قانون
  final String titleFa;

  /// پیام فارسی نتیجه ارزیابی
  final String messageFa;

  /// سطح شدت نتیجه
  final RuleSeverity severity;

  /// پیشنهاد فارسی برای بهبود (اختیاری)
  final String? recommendation;

  const RuleEvaluation({
    required this.isSatisfied,
    required this.ruleId,
    required this.titleFa,
    required this.messageFa,
    required this.severity,
    this.recommendation,
  });

  @override
  String toString() =>
      'RuleEvaluation($ruleId: $severity — $messageFa)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleEvaluation &&
          runtimeType == other.runtimeType &&
          ruleId == other.ruleId &&
          isSatisfied == other.isSatisfied &&
          severity == other.severity &&
          titleFa == other.titleFa &&
          messageFa == other.messageFa &&
          recommendation == other.recommendation;

  @override
  int get hashCode => Object.hash(
        ruleId,
        isSatisfied,
        severity,
        titleFa,
        messageFa,
        recommendation,
      );

  /// Serialization to map (useful for persistence layer).
  Map<String, dynamic> toMap() => {
        'ruleId': ruleId,
        'isSatisfied': isSatisfied,
        'titleFa': titleFa,
        'messageFa': messageFa,
        'severity': severity.name,
        'recommendation': recommendation,
      };

  /// Deserialization from map.
  factory RuleEvaluation.fromMap(Map<String, dynamic> map) =>
      RuleEvaluation(
        ruleId: map['ruleId'] as String,
        isSatisfied: map['isSatisfied'] as bool,
        titleFa: map['titleFa'] as String,
        messageFa: map['messageFa'] as String,
        severity: RuleSeverity.values.byName(map['severity'] as String),
        recommendation: map['recommendation'] as String?,
      );
}

// ── RuleContext ───────────────────────────────────────────────────────────

/// زمینه داده‌ای برای ارزیابی قوانین
///
/// Holds all data a rule might need. All fields are nullable because
/// not every rule requires every piece of data.
class RuleContext {
  /// مدت خواب به دقیقه
  final int? sleepDurationMinutes;

  /// کیفیت خواب (۱ تا ۵)
  final int? sleepQuality;

  /// مجموع آب مصرفی به میلی‌لیتر
  final double? totalWaterMl;

  /// مجموع کالری مصرفی
  final double? totalCalories;

  /// مجموع پروتئین به گرم
  final double? totalProtein;

  /// مجموع چربی به گرم
  final double? totalFat;

  /// مجموع کربوهیدرات به گرم
  final double? totalCarb;

  /// آیا تمرین انجام شده
  final bool? hasWorkout;

  /// حجم تمرین به کیلوگرم
  final double? workoutVolumeKg;

  /// روزهای متوالی تمرین
  final int? consecutiveWorkoutDays;

  /// وزن به کیلوگرم
  final double? weightKg;

  /// قد به سانتی‌متر
  final double? heightCm;

  /// سن
  final int? age;

  /// جنسیت ('male' یا 'female')
  final String? gender;

  /// سطح فعالیت ('sedentary', 'light', 'moderate', 'active', 'very_active')
  final String? activityLevel;

  /// نوع هدف ('lose', 'maintain', 'gain')
  final String? goalType;

  /// هدف آب به میلی‌لیتر
  final double? waterTargetMl;

  /// هدف کالری
  final double? calorieTarget;

  /// هدف پروتئین به گرم
  final double? proteinTargetG;

  const RuleContext({
    this.sleepDurationMinutes,
    this.sleepQuality,
    this.totalWaterMl,
    this.totalCalories,
    this.totalProtein,
    this.totalFat,
    this.totalCarb,
    this.hasWorkout,
    this.workoutVolumeKg,
    this.consecutiveWorkoutDays,
    this.weightKg,
    this.heightCm,
    this.age,
    this.gender,
    this.activityLevel,
    this.goalType,
    this.waterTargetMl,
    this.calorieTarget,
    this.proteinTargetG,
  });

  /// Creates a copy with some fields replaced.
  ///
  /// Note: uses `??` so you cannot set a field back to null once it has
  /// a value. This is acceptable for the current use cases.
  /// TODO: If null-reset is needed, switch to a builder or optional wrapper
  /// pattern.
  RuleContext copyWith({
    int? sleepDurationMinutes,
    int? sleepQuality,
    double? totalWaterMl,
    double? totalCalories,
    double? totalProtein,
    double? totalFat,
    double? totalCarb,
    bool? hasWorkout,
    double? workoutVolumeKg,
    int? consecutiveWorkoutDays,
    double? weightKg,
    double? heightCm,
    int? age,
    String? gender,
    String? activityLevel,
    String? goalType,
    double? waterTargetMl,
    double? calorieTarget,
    double? proteinTargetG,
  }) =>
      RuleContext(
        sleepDurationMinutes:
            sleepDurationMinutes ?? this.sleepDurationMinutes,
        sleepQuality: sleepQuality ?? this.sleepQuality,
        totalWaterMl: totalWaterMl ?? this.totalWaterMl,
        totalCalories: totalCalories ?? this.totalCalories,
        totalProtein: totalProtein ?? this.totalProtein,
        totalFat: totalFat ?? this.totalFat,
        totalCarb: totalCarb ?? this.totalCarb,
        hasWorkout: hasWorkout ?? this.hasWorkout,
        workoutVolumeKg: workoutVolumeKg ?? this.workoutVolumeKg,
        consecutiveWorkoutDays:
            consecutiveWorkoutDays ?? this.consecutiveWorkoutDays,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        activityLevel: activityLevel ?? this.activityLevel,
        goalType: goalType ?? this.goalType,
        waterTargetMl: waterTargetMl ?? this.waterTargetMl,
        calorieTarget: calorieTarget ?? this.calorieTarget,
        proteinTargetG: proteinTargetG ?? this.proteinTargetG,
      );
}

// ── Rule (abstract) ──────────────────────────────────────────────────────

/// قانون ارزیابی
///
/// Each concrete rule extends this class and implements [evaluate] with
/// deterministic logic. Rules must not use randomness, AI, or ML.
abstract class Rule {
  /// شناسه یکتای قانون (مثلاً 'sleep_duration')
  String get ruleId;

  /// عنوان فارسی قانون
  String get titleFa;

  /// ارزیابی قانون بر اساس زمینه داده‌ای
  ///
  /// Returns a [RuleEvaluation] with Persian messages.
  /// Must be pure and deterministic.
  RuleEvaluation evaluate(RuleContext context);
}
