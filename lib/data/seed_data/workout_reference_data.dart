/// داده‌های مرجع سیستم تمرین Bergamot
///
/// شامل:
///   - 16 گروه عضلانی (MuscleGroup)
///   - 9 نوع تجهیزات (Equipment)
///   - 10 هدف تمرین (Goal)
///   - 3 سطح دشواری (Difficulty)
///   - 2 نوع تمرین (ExerciseType)
///
/// این داده‌ها در فایل‌های Dart بدون نیاز به دیتابیس موجودند.
/// در زمان seed، در جدول‌های مرجع (MuscleGroups) ذخیره می‌شوند.
library;

// ────────────────────────────────────────────────────────────────────────────
// Muscle Groups (16) — طبق spec کاربر
// ────────────────────────────────────────────────────────────────────────────

class MuscleGroupRef {
  final String code;
  final String nameEn;
  final String nameFa;
  final String icon;

  const MuscleGroupRef({
    required this.code,
    required this.nameEn,
    required this.nameFa,
    this.icon = 'fitness_center',
  });
}

const List<MuscleGroupRef> kMuscleGroups = [
  MuscleGroupRef(code: 'full_body', nameEn: 'Full Body', nameFa: 'بدن کامل', icon: 'accessibility_new'),
  MuscleGroupRef(code: 'chest', nameEn: 'Chest', nameFa: 'سینه', icon: 'fitness_center'),
  MuscleGroupRef(code: 'back', nameEn: 'Back', nameFa: 'پشت', icon: 'fitness_center'),
  MuscleGroupRef(code: 'shoulders', nameEn: 'Shoulders', nameFa: 'شانه', icon: 'fitness_center'),
  MuscleGroupRef(code: 'biceps', nameEn: 'Biceps', nameFa: 'جلو بازو', icon: 'fitness_center'),
  MuscleGroupRef(code: 'triceps', nameEn: 'Triceps', nameFa: 'پشت بازو', icon: 'fitness_center'),
  MuscleGroupRef(code: 'forearms', nameEn: 'Forearms', nameFa: 'ساعد', icon: 'fitness_center'),
  MuscleGroupRef(code: 'abs', nameEn: 'Abs', nameFa: 'شکم', icon: 'fitness_center'),
  MuscleGroupRef(code: 'core', nameEn: 'Core', nameFa: 'هسته', icon: 'fitness_center'),
  MuscleGroupRef(code: 'glutes', nameEn: 'Glutes', nameFa: 'سرینی', icon: 'fitness_center'),
  MuscleGroupRef(code: 'quadriceps', nameEn: 'Quadriceps', nameFa: 'چهارسر ران', icon: 'fitness_center'),
  MuscleGroupRef(code: 'hamstrings', nameEn: 'Hamstrings', nameFa: 'همسترینگ', icon: 'fitness_center'),
  MuscleGroupRef(code: 'calves', nameEn: 'Calves', nameFa: 'ساق پا', icon: 'fitness_center'),
  MuscleGroupRef(code: 'cardio', nameEn: 'Cardio', nameFa: 'هوازی', icon: 'favorite'),
  MuscleGroupRef(code: 'mobility', nameEn: 'Mobility', nameFa: 'موبیلیتی', icon: 'accessibility_new'),
  MuscleGroupRef(code: 'stretching', nameEn: 'Stretching', nameFa: 'کشش', icon: 'self_improvement'),
];

/// تبدیل نام فارسی عضلانی به کد
String? muscleFaToCode(String fa) {
  for (final m in kMuscleGroups) {
    if (m.nameFa == fa) return m.code;
  }
  return null;
}

/// تبدیل کد عضلانی به نام فارسی
String muscleCodeToFa(String code) {
  for (final m in kMuscleGroups) {
    if (m.code == code) return m.nameFa;
  }
  return code;
}

// ────────────────────────────────────────────────────────────────────────────
// Equipment (9) — طبق spec کاربر
// ────────────────────────────────────────────────────────────────────────────

class EquipmentRef {
  final String code;
  final String nameEn;
  final String nameFa;
  final String icon;

  const EquipmentRef({
    required this.code,
    required this.nameEn,
    required this.nameFa,
    this.icon = 'fitness_center',
  });
}

const List<EquipmentRef> kEquipment = [
  EquipmentRef(code: 'no_equipment', nameEn: 'No Equipment', nameFa: 'بدون تجهیزات', icon: 'accessibility_new'),
  EquipmentRef(code: 'bodyweight', nameEn: 'Bodyweight', nameFa: 'وزن بدن', icon: 'accessibility_new'),
  EquipmentRef(code: 'dumbbells', nameEn: 'Dumbbells', nameFa: 'دمبل', icon: 'fitness_center'),
  EquipmentRef(code: 'dumbbell', nameEn: 'Dumbbell (legacy)', nameFa: 'دمبل', icon: 'fitness_center'),
  EquipmentRef(code: 'barbell', nameEn: 'Barbell', nameFa: 'هالتر', icon: 'fitness_center'),
  EquipmentRef(code: 'resistance_band', nameEn: 'Resistance Band', nameFa: 'باند مقاومتی', icon: 'fitness_center'),
  EquipmentRef(code: 'band', nameEn: 'Band (legacy)', nameFa: 'باند', icon: 'fitness_center'),
  EquipmentRef(code: 'kettlebell', nameEn: 'Kettlebell', nameFa: 'کتل‌بل', icon: 'fitness_center'),
  EquipmentRef(code: 'pull_up_bar', nameEn: 'Pull-up Bar', nameFa: 'بارفیکس', icon: 'fitness_center'),
  EquipmentRef(code: 'bench', nameEn: 'Bench', nameFa: 'نیمکت', icon: 'chair'),
  EquipmentRef(code: 'mat', nameEn: 'Mat', nameFa: 'تشک', icon: 'spa'),
  EquipmentRef(code: 'machine', nameEn: 'Machine', nameFa: 'دستگاه', icon: 'fitness_center'),
  EquipmentRef(code: 'cable', nameEn: 'Cable', nameFa: 'کابل', icon: 'fitness_center'),
  EquipmentRef(code: 'other', nameEn: 'Other', nameFa: 'سایر', icon: 'more_horiz'),
];

/// تبدیل کد تجهیز به نام فارسی
String equipmentCodeToFa(String code) {
  for (final e in kEquipment) {
    if (e.code == code) return e.nameFa;
  }
  return code;
}

/// آیا تجهیز "بدون تجهیزات" است؟
bool isNoEquipment(String code) {
  return code == 'no_equipment' || code == 'bodyweight';
}

// ────────────────────────────────────────────────────────────────────────────
// Goals (10) — طبق spec کاربر
// ────────────────────────────────────────────────────────────────────────────

class GoalRef {
  final String code;
  final String nameEn;
  final String nameFa;
  final String icon;
  /// عضلات مرتبط با هدف (برای rule-based recommendation، نه AI)
  final List<String> recommendedMuscleGroups;
  /// مدت استراحت پیشنهادی (ثانیه)
  final int recommendedRestSeconds;
  /// تعداد تکرار پیشنهادی
  final int recommendedReps;

  const GoalRef({
    required this.code,
    required this.nameEn,
    required this.nameFa,
    this.icon = 'flag',
    this.recommendedMuscleGroups = const [],
    this.recommendedRestSeconds = 60,
    this.recommendedReps = 12,
  });
}

const List<GoalRef> kGoals = [
  GoalRef(
    code: 'weight_loss',
    nameEn: 'Weight Loss',
    nameFa: 'کاهش وزن',
    icon: 'monitor_weight_outlined',
    recommendedMuscleGroups: ['full_body', 'cardio', 'legs'],
    recommendedRestSeconds: 30,
    recommendedReps: 15,
  ),
  GoalRef(
    code: 'fat_burn',
    nameEn: 'Fat Burn',
    nameFa: 'چربی‌سوزی',
    icon: 'local_fire_department_outlined',
    recommendedMuscleGroups: ['full_body', 'cardio'],
    recommendedRestSeconds: 15,
    recommendedReps: 20,
  ),
  GoalRef(
    code: 'muscle_building',
    nameEn: 'Muscle Building',
    nameFa: 'عضله‌سازی',
    icon: 'fitness_center',
    recommendedMuscleGroups: ['chest', 'back', 'shoulders', 'legs', 'arms'],
    recommendedRestSeconds: 90,
    recommendedReps: 10,
  ),
  GoalRef(
    code: 'strength',
    nameEn: 'Strength',
    nameFa: 'قدرت',
    icon: 'fitness_center',
    recommendedMuscleGroups: ['full_body'],
    recommendedRestSeconds: 120,
    recommendedReps: 5,
  ),
  GoalRef(
    code: 'endurance',
    nameEn: 'Endurance',
    nameFa: 'استقامت',
    icon: 'timer_outlined',
    recommendedMuscleGroups: ['cardio'],
    recommendedRestSeconds: 30,
    recommendedReps: 20,
  ),
  GoalRef(
    code: 'general_fitness',
    nameEn: 'General Fitness',
    nameFa: 'تناسب اندام عمومی',
    icon: 'fitness_center',
    recommendedMuscleGroups: ['full_body'],
    recommendedRestSeconds: 60,
    recommendedReps: 12,
  ),
  GoalRef(
    code: 'mobility',
    nameEn: 'Mobility',
    nameFa: 'موبیلیتی',
    icon: 'accessibility_new',
    recommendedMuscleGroups: ['mobility', 'stretching'],
    recommendedRestSeconds: 30,
    recommendedReps: 10,
  ),
  GoalRef(
    code: 'flexibility',
    nameEn: 'Flexibility',
    nameFa: 'انعطاف‌پذیری',
    icon: 'self_improvement',
    recommendedMuscleGroups: ['stretching'],
    recommendedRestSeconds: 30,
    recommendedReps: 1,
  ),
  GoalRef(
    code: 'core',
    nameEn: 'Core',
    nameFa: 'هسته و شکم',
    icon: 'fitness_center',
    recommendedMuscleGroups: ['abs', 'core'],
    recommendedRestSeconds: 30,
    recommendedReps: 15,
  ),
  GoalRef(
    code: 'beginner',
    nameEn: 'Beginner',
    nameFa: 'مبتدی',
    icon: 'school_outlined',
    recommendedMuscleGroups: ['full_body'],
    recommendedRestSeconds: 90,
    recommendedReps: 10,
  ),
];

/// تبدیل کد هدف به نام فارسی
String goalCodeToFa(String code) {
  for (final g in kGoals) {
    if (g.code == code) return g.nameFa;
  }
  return code;
}

// ────────────────────────────────────────────────────────────────────────────
// Difficulty (3 levels)
// ────────────────────────────────────────────────────────────────────────────

class DifficultyRef {
  final int code;
  final String nameEn;
  final String nameFa;
  final String color;

  const DifficultyRef({
    required this.code,
    required this.nameEn,
    required this.nameFa,
    required this.color,
  });
}

const List<DifficultyRef> kDifficulty = [
  DifficultyRef(code: 1, nameEn: 'Beginner', nameFa: 'مبتدی', color: 'green'),
  DifficultyRef(code: 2, nameEn: 'Intermediate', nameFa: 'متوسط', color: 'orange'),
  DifficultyRef(code: 3, nameEn: 'Advanced', nameFa: 'پیشرفته', color: 'red'),
];

String difficultyCodeToFa(int code) {
  for (final d in kDifficulty) {
    if (d.code == code) return d.nameFa;
  }
  return code.toString();
}

// ────────────────────────────────────────────────────────────────────────────
// Exercise Type (2)
// ────────────────────────────────────────────────────────────────────────────

class ExerciseTypeRef {
  final String code;
  final String nameEn;
  final String nameFa;

  const ExerciseTypeRef({
    required this.code,
    required this.nameEn,
    required this.nameFa,
  });
}

const List<ExerciseTypeRef> kExerciseTypes = [
  ExerciseTypeRef(code: 'rep_based', nameEn: 'Rep-based', nameFa: 'تکرارمحور'),
  ExerciseTypeRef(code: 'time_based', nameEn: 'Time-based', nameFa: 'زمان‌محور'),
];

String exerciseTypeCodeToFa(String code) {
  for (final t in kExerciseTypes) {
    if (t.code == code) return t.nameFa;
  }
  return code;
}

// ────────────────────────────────────────────────────────────────────────────
// Workout Durations (Quick Workouts)
// ────────────────────────────────────────────────────────────────────────────

const List<int> kQuickWorkoutDurations = [5, 7, 10, 15, 20, 30];

// ────────────────────────────────────────────────────────────────────────────
// Rest Durations
// ────────────────────────────────────────────────────────────────────────────

const List<int> kRestDurations = [15, 30, 45, 60, 90];
