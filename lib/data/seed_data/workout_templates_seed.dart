/// داده‌های الگوهای تمرین آماده Bergamot
///
/// شامل Quick Workouts و Templates هدفمند.
/// این الگوها به Exercises با nameFa مرتبط می‌شوند.
/// همه‌ی تمرین‌های استفاده‌شده باید در Exercise Library موجود باشند.
library;

/// یک تمرین داخل یک template
class WorkoutTemplateExerciseSeed {
  final String exerciseNameFa;  // باید در Exercise Library موجود باشد
  final int sets;
  final int? reps;
  final int? durationSeconds;
  final int restSeconds;
  final bool isTimed;
  final String? notesFa;

  const WorkoutTemplateExerciseSeed({
    required this.exerciseNameFa,
    this.sets = 3,
    this.reps,
    this.durationSeconds,
    this.restSeconds = 30,
    this.isTimed = false,
    this.notesFa,
  });
}

/// یک template تمرین کامل
class WorkoutTemplateSeed {
  final String code;
  final String nameFa;
  final String nameEn;
  final String? descriptionFa;
  final int difficulty;          // 1-3
  final String? goalCode;        // GoalRef.code
  final int? durationMinutes;
  final int? caloriesEstimate;
  final String equipment;        // CSV of equipment codes
  final String muscleGroups;     // CSV of muscle codes
  final bool isQuick;
  final List<WorkoutTemplateExerciseSeed> exercises;

  const WorkoutTemplateSeed({
    required this.code,
    required this.nameFa,
    required this.nameEn,
    this.descriptionFa,
    this.difficulty = 1,
    this.goalCode,
    this.durationMinutes,
    this.caloriesEstimate,
    this.equipment = 'no_equipment',
    this.muscleGroups = 'full_body',
    this.isQuick = false,
    required this.exercises,
  });

  /// externalId برای idempotent seed
  String get externalId => 'BERGAMOT_TEMPLATE:$code';
}

/// یک روز از یک program چندروزه
class WorkoutProgramDaySeed {
  final int dayNumber;
  final String nameFa;
  final bool isRestDay;
  final String? templateCode;  // NULL برای rest days
  final String? notesFa;

  const WorkoutProgramDaySeed({
    required this.dayNumber,
    required this.nameFa,
    this.isRestDay = false,
    this.templateCode,
    this.notesFa,
  });
}

/// یک program چندروزه
class WorkoutProgramSeed {
  final String code;
  final String nameFa;
  final String nameEn;
  final String? descriptionFa;
  final int difficulty;
  final String? goalCode;
  final List<WorkoutProgramDaySeed> days;

  const WorkoutProgramSeed({
    required this.code,
    required this.nameFa,
    required this.nameEn,
    this.descriptionFa,
    this.difficulty = 1,
    this.goalCode,
    required this.days,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// QUICK WORKOUTS (5/7/10/15/20/30 min)
// ════════════════════════════════════════════════════════════════════════════

const List<WorkoutTemplateSeed> kQuickWorkouts = [
  WorkoutTemplateSeed(
    code: 'quick_5min_beginner',
    nameFa: '۵ دقیقه مبتدی',
    nameEn: '5 min Beginner',
    descriptionFa: 'یک شروع سریع برای روزهای پرمشغله — ۵ دقیقه بدن کامل.',
    difficulty: 1,
    goalCode: 'general_fitness',
    durationMinutes: 5,
    caloriesEstimate: 35,
    equipment: 'no_equipment',
    muscleGroups: 'full_body',
    isQuick: true,
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا', sets: 1, reps: 10, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'اسکوات وزن بدن', sets: 1, reps: 15, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک', sets: 1, durationSeconds: 20, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'زانو بلند', sets: 1, durationSeconds: 30, isTimed: true, restSeconds: 0),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'quick_7min_fullbody',
    nameFa: '۷ دقیقه بدن کامل',
    nameEn: '7 min Full Body',
    descriptionFa: 'تمرین کلاسیک ۷ دقیقه‌ای — ۱۲ حرکت ۳۰ ثانیه‌ای با ۵ ثانیه استراحت.',
    difficulty: 2,
    goalCode: 'general_fitness',
    durationMinutes: 7,
    caloriesEstimate: 60,
    equipment: 'no_equipment',
    muscleGroups: 'full_body',
    isQuick: true,
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پرش ستاره', sets: 1, durationSeconds: 30, isTimed: true, restSeconds: 5),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'حالت روی دیوار', sets: 1, durationSeconds: 30, isTimed: true, restSeconds: 5),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا', sets: 1, reps: 10, restSeconds: 5),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کرانچ', sets: 1, durationSeconds: 30, isTimed: true, restSeconds: 5),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'استپ‌آپ', sets: 1, durationSeconds: 30, isTimed: true, restSeconds: 5),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا سوئدی', sets: 1, reps: 10, restSeconds: 5),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'اسکات وزن بدن', sets: 1, durationSeconds: 30, isTimed: true, restSeconds: 5),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک پهلو', sets: 1, durationSeconds: 30, isTimed: true, restSeconds: 5),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'quick_10min_cardio',
    nameFa: '۱۰ دقیقه کاردیو',
    nameEn: '10 min Cardio',
    descriptionFa: 'کاردیو با شدت متوسط — مناسب چربی‌سوزی.',
    difficulty: 2,
    goalCode: 'fat_burn',
    durationMinutes: 10,
    caloriesEstimate: 100,
    equipment: 'no_equipment',
    muscleGroups: 'cardio',
    isQuick: true,
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پرش ستاره', sets: 3, durationSeconds: 30, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'زانو بلند', sets: 3, durationSeconds: 30, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کوهنورد', sets: 3, durationSeconds: 30, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پرش اسکات', sets: 3, durationSeconds: 30, isTimed: true, restSeconds: 15),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'quick_15min_abs',
    nameFa: '۱۵ دقیقه شکم',
    nameEn: '15 min Abs',
    descriptionFa: 'تمرکز روی عضلات شکم و هسته.',
    difficulty: 2,
    goalCode: 'core',
    durationMinutes: 15,
    caloriesEstimate: 120,
    equipment: 'no_equipment',
    muscleGroups: 'abs',
    isQuick: true,
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کرانچ', sets: 3, reps: 15, restSeconds: 20),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'بالا بردن پا', sets: 3, reps: 12, restSeconds: 20),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک', sets: 3, durationSeconds: 30, isTimed: true, restSeconds: 20),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'چرخش روسی', sets: 3, reps: 20, restSeconds: 20),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک پهلو', sets: 3, durationSeconds: 20, isTimed: true, restSeconds: 20),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'quick_20min_strength',
    nameFa: '۲۰ دقیقه قدرت',
    nameEn: '20 min Strength',
    descriptionFa: 'تمرین قدرت بدن کامل بدون تجهیزات.',
    difficulty: 2,
    goalCode: 'strength',
    durationMinutes: 20,
    caloriesEstimate: 180,
    equipment: 'no_equipment',
    muscleGroups: 'full_body',
    isQuick: true,
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا', sets: 3, reps: 12, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'اسکات وزن بدن', sets: 3, reps: 15, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'لانگ', sets: 3, reps: 10, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک', sets: 3, durationSeconds: 30, isTimed: true, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پل سرینی', sets: 3, reps: 15, restSeconds: 30),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'quick_30min_fullbody',
    nameFa: '۳۰ دقیقه بدن کامل',
    nameEn: '30 min Full Body',
    descriptionFa: 'تمرین کامل بدن با شدت بالا.',
    difficulty: 3,
    goalCode: 'general_fitness',
    durationMinutes: 30,
    caloriesEstimate: 280,
    equipment: 'no_equipment',
    muscleGroups: 'full_body',
    isQuick: true,
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا', sets: 4, reps: 12, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'اسکات وزن بدن', sets: 4, reps: 15, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'لانگ', sets: 3, reps: 12, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'بورپی', sets: 3, reps: 8, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک', sets: 3, durationSeconds: 45, isTimed: true, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پل سرینی', sets: 3, reps: 15, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'ساق پا ایستاده', sets: 3, reps: 20, restSeconds: 30),
    ],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// WORKOUT TEMPLATES (by muscle group)
// ════════════════════════════════════════════════════════════════════════════

const List<WorkoutTemplateSeed> kMuscleGroupTemplates = [
  WorkoutTemplateSeed(
    code: 'full_body_beginner',
    nameFa: 'بدن کامل مبتدی',
    nameEn: 'Full Body Beginner',
    descriptionFa: 'تمرین بدن کامل برای شروع‌کنندگان.',
    difficulty: 1,
    goalCode: 'general_fitness',
    durationMinutes: 25,
    caloriesEstimate: 150,
    equipment: 'no_equipment',
    muscleGroups: 'full_body',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا زانو', sets: 3, reps: 10, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'اسکات وزن بدن', sets: 3, reps: 12, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'لانگ', sets: 3, reps: 8, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک', sets: 3, durationSeconds: 20, isTimed: true, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پل سرینی', sets: 3, reps: 12, restSeconds: 45),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'full_body_intermediate',
    nameFa: 'بدن کامل متوسط',
    nameEn: 'Full Body Intermediate',
    descriptionFa: 'تمرین بدن کامل با شدت متوسط.',
    difficulty: 2,
    goalCode: 'muscle_building',
    durationMinutes: 35,
    caloriesEstimate: 250,
    equipment: 'no_equipment',
    muscleGroups: 'full_body',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا', sets: 4, reps: 12, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'اسکات وزن بدن', sets: 4, reps: 15, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'لانگ راه‌رفتن', sets: 3, reps: 10, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'بورپی', sets: 3, reps: 8, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک', sets: 3, durationSeconds: 45, isTimed: true, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'چرخش روسی', sets: 3, reps: 15, restSeconds: 30),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'chest_beginner',
    nameFa: 'سینه مبتدی',
    nameEn: 'Chest Beginner',
    descriptionFa: 'تمرکز روی عضلات سینه و پشت بازو.',
    difficulty: 1,
    goalCode: 'muscle_building',
    durationMinutes: 20,
    caloriesEstimate: 120,
    equipment: 'no_equipment',
    muscleGroups: 'chest',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا زانو', sets: 4, reps: 10, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا دیواری', sets: 3, reps: 15, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پارالل با نیمکت', sets: 3, reps: 10, restSeconds: 45),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'chest_intermediate',
    nameFa: 'سینه متوسط',
    nameEn: 'Chest Intermediate',
    descriptionFa: 'تمرکز روی سینه با وارییشن‌های شنا.',
    difficulty: 2,
    goalCode: 'muscle_building',
    durationMinutes: 30,
    caloriesEstimate: 200,
    equipment: 'no_equipment',
    muscleGroups: 'chest',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا', sets: 4, reps: 12, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا باز', sets: 3, reps: 10, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'شنا الماسی', sets: 3, reps: 8, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پارالل با نیمکت', sets: 3, reps: 12, restSeconds: 45),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'legs_beginner',
    nameFa: 'پا مبتدی',
    nameEn: 'Legs Beginner',
    descriptionFa: 'تمرکز روی عضلات پایین‌تنه.',
    difficulty: 1,
    goalCode: 'muscle_building',
    durationMinutes: 20,
    caloriesEstimate: 130,
    equipment: 'no_equipment',
    muscleGroups: 'quadriceps',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'اسکات وزن بدن', sets: 4, reps: 12, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'لانگ', sets: 3, reps: 10, restSeconds: 60),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پل سرینی', sets: 3, reps: 15, restSeconds: 45),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'ساق پا ایستاده', sets: 3, reps: 20, restSeconds: 30),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'abs_intermediate',
    nameFa: 'شکم متوسط',
    nameEn: 'Abs Intermediate',
    descriptionFa: 'تمرکز روی عضلات شکم و هسته.',
    difficulty: 2,
    goalCode: 'core',
    durationMinutes: 25,
    caloriesEstimate: 180,
    equipment: 'no_equipment',
    muscleGroups: 'abs',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کرانچ', sets: 3, reps: 15, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کرانچ دوچرخه', sets: 3, reps: 20, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'بالا بردن پا', sets: 3, reps: 12, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک', sets: 3, durationSeconds: 45, isTimed: true, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پلانک پهلو', sets: 3, durationSeconds: 30, isTimed: true, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'چرخش روسی', sets: 3, reps: 20, restSeconds: 30),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'cardio_hiit',
    nameFa: 'هییت کاردیو',
    nameEn: 'HIIT Cardio',
    descriptionFa: 'تمرین اینتروال با شدت بالا برای چربی‌سوزی.',
    difficulty: 3,
    goalCode: 'fat_burn',
    durationMinutes: 25,
    caloriesEstimate: 280,
    equipment: 'no_equipment',
    muscleGroups: 'cardio',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پرش ستاره', sets: 4, durationSeconds: 40, isTimed: true, restSeconds: 20),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'زانو بلند', sets: 4, durationSeconds: 40, isTimed: true, restSeconds: 20),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'بورپی', sets: 4, reps: 10, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'پرش اسکات', sets: 4, reps: 12, restSeconds: 30),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کوهنورد', sets: 4, durationSeconds: 40, isTimed: true, restSeconds: 20),
    ],
  ),
  WorkoutTemplateSeed(
    code: 'mobility_stretch',
    nameFa: 'موبیلیتی و کشش',
    nameEn: 'Mobility & Stretch',
    descriptionFa: 'تمرین سبک برای بهبود انعطاف‌پذیری.',
    difficulty: 1,
    goalCode: 'mobility',
    durationMinutes: 20,
    caloriesEstimate: 60,
    equipment: 'no_equipment',
    muscleGroups: 'stretching',
    exercises: [
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کشش گاو-گربه', sets: 2, durationSeconds: 30, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'حالت کودک', sets: 2, durationSeconds: 30, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'سگ رو به پایین', sets: 2, durationSeconds: 30, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'کشش همسترینگ', sets: 2, durationSeconds: 30, isTimed: true, restSeconds: 15),
      WorkoutTemplateExerciseSeed(exerciseNameFa: 'چرخش ستون فقرات', sets: 2, durationSeconds: 30, isTimed: true, restSeconds: 15),
    ],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// WORKOUT PROGRAMS (7/14/30 day)
// ════════════════════════════════════════════════════════════════════════════

const List<WorkoutProgramSeed> kWorkoutPrograms = [
  WorkoutProgramSeed(
    code: 'beginner_7day',
    nameFa: '۷ روز مبتدی',
    nameEn: '7 Day Beginner',
    descriptionFa: 'یک هفته تمرین سبک برای شروع — هر روز بدن یا استراحت.',
    difficulty: 1,
    goalCode: 'beginner',
    days: [
      WorkoutProgramDaySeed(dayNumber: 1, nameFa: 'روز ۱ - بدن کامل', templateCode: 'full_body_beginner'),
      WorkoutProgramDaySeed(dayNumber: 2, nameFa: 'روز ۲ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 3, nameFa: 'روز ۳ - سینه', templateCode: 'chest_beginner'),
      WorkoutProgramDaySeed(dayNumber: 4, nameFa: 'روز ۴ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 5, nameFa: 'روز ۵ - پا', templateCode: 'legs_beginner'),
      WorkoutProgramDaySeed(dayNumber: 6, nameFa: 'روز ۶ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 7, nameFa: 'روز ۷ - بدن کامل', templateCode: 'full_body_beginner'),
    ],
  ),
  WorkoutProgramSeed(
    code: 'home_14day',
    nameFa: '۱۴ روز در خانه',
    nameEn: '14 Day Home Workout',
    descriptionFa: 'دو هفته تمرین در خانه — مناسب برای عضله‌سازی.',
    difficulty: 2,
    goalCode: 'muscle_building',
    days: [
      WorkoutProgramDaySeed(dayNumber: 1, nameFa: 'روز ۱ - بدن کامل', templateCode: 'full_body_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 2, nameFa: 'روز ۲ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 3, nameFa: 'روز ۳ - سینه', templateCode: 'chest_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 4, nameFa: 'روز ۴ - پا', templateCode: 'legs_beginner'),
      WorkoutProgramDaySeed(dayNumber: 5, nameFa: 'روز ۵ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 6, nameFa: 'روز ۶ - شکم', templateCode: 'abs_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 7, nameFa: 'روز ۷ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 8, nameFa: 'روز ۸ - بدن کامل', templateCode: 'full_body_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 9, nameFa: 'روز ۹ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 10, nameFa: 'روز ۱۰ - کاردیو', templateCode: 'cardio_hiit'),
      WorkoutProgramDaySeed(dayNumber: 11, nameFa: 'روز ۱۱ - سینه', templateCode: 'chest_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 12, nameFa: 'روز ۱۲ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 13, nameFa: 'روز ۱۳ - پا', templateCode: 'legs_beginner'),
      WorkoutProgramDaySeed(dayNumber: 14, nameFa: 'روز ۱۴ - استراحت', isRestDay: true),
    ],
  ),
  WorkoutProgramSeed(
    code: 'fat_burn_7day',
    nameFa: '۷ روز چربی‌سوزی',
    nameEn: '7 Day Fat Burn',
    descriptionFa: 'هفته‌ای HIIT برای چربی‌سوزی — کاردیو و حرکات پرشی.',
    difficulty: 3,
    goalCode: 'fat_burn',
    days: [
      WorkoutProgramDaySeed(dayNumber: 1, nameFa: 'روز ۱ - HIIT', templateCode: 'cardio_hiit'),
      WorkoutProgramDaySeed(dayNumber: 2, nameFa: 'روز ۲ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 3, nameFa: 'روز ۳ - بدن کامل', templateCode: 'full_body_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 4, nameFa: 'روز ۴ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 5, nameFa: 'روز ۵ - HIIT', templateCode: 'cardio_hiit'),
      WorkoutProgramDaySeed(dayNumber: 6, nameFa: 'روز ۶ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 7, nameFa: 'روز ۷ - کاردیو', templateCode: 'quick_15min_abs'),
    ],
  ),
  WorkoutProgramSeed(
    code: 'fullbody_30day',
    nameFa: '۳۰ روز بدن کامل',
    nameEn: '30 Day Full Body',
    descriptionFa: 'یک ماه تمرین کامل بدن با افزایش تدریجی شدت.',
    difficulty: 2,
    goalCode: 'general_fitness',
    days: [
      WorkoutProgramDaySeed(dayNumber: 1, nameFa: 'روز ۱ - بدن کامل', templateCode: 'full_body_beginner'),
      WorkoutProgramDaySeed(dayNumber: 2, nameFa: 'روز ۲ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 3, nameFa: 'روز ۳ - سینه', templateCode: 'chest_beginner'),
      WorkoutProgramDaySeed(dayNumber: 4, nameFa: 'روز ۴ - پا', templateCode: 'legs_beginner'),
      WorkoutProgramDaySeed(dayNumber: 5, nameFa: 'روز ۵ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 6, nameFa: 'روز ۶ - شکم', templateCode: 'abs_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 7, nameFa: 'روز ۷ - استراحت', isRestDay: true),
      // هفته ۲
      WorkoutProgramDaySeed(dayNumber: 8, nameFa: 'روز ۸ - بدن کامل', templateCode: 'full_body_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 9, nameFa: 'روز ۹ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 10, nameFa: 'روز ۱۰ - سینه', templateCode: 'chest_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 11, nameFa: 'روز ۱۱ - پا', templateCode: 'legs_beginner'),
      WorkoutProgramDaySeed(dayNumber: 12, nameFa: 'روز ۱۲ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 13, nameFa: 'روز ۱۳ - شکم', templateCode: 'abs_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 14, nameFa: 'روز ۱۴ - استراحت', isRestDay: true),
      // هفته ۳
      WorkoutProgramDaySeed(dayNumber: 15, nameFa: 'روز ۱۵ - HIIT', templateCode: 'cardio_hiit'),
      WorkoutProgramDaySeed(dayNumber: 16, nameFa: 'روز ۱۶ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 17, nameFa: 'روز ۱۷ - بدن کامل', templateCode: 'full_body_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 18, nameFa: 'روز ۱۸ - پا', templateCode: 'legs_beginner'),
      WorkoutProgramDaySeed(dayNumber: 19, nameFa: 'روز ۱۹ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 20, nameFa: 'روز ۲۰ - سینه', templateCode: 'chest_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 21, nameFa: 'روز ۲۱ - استراحت', isRestDay: true),
      // هفته ۴
      WorkoutProgramDaySeed(dayNumber: 22, nameFa: 'روز ۲۲ - شکم', templateCode: 'abs_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 23, nameFa: 'روز ۲۳ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 24, nameFa: 'روز ۲۴ - HIIT', templateCode: 'cardio_hiit'),
      WorkoutProgramDaySeed(dayNumber: 25, nameFa: 'روز ۲۵ - بدن کامل', templateCode: 'full_body_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 26, nameFa: 'روز ۲۶ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 27, nameFa: 'روز ۲۷ - پا', templateCode: 'legs_beginner'),
      WorkoutProgramDaySeed(dayNumber: 28, nameFa: 'روز ۲۸ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 29, nameFa: 'روز ۲۹ - بدن کامل', templateCode: 'full_body_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 30, nameFa: 'روز ۳۰ - استراحت', isRestDay: true),
    ],
  ),
  WorkoutProgramSeed(
    code: 'abs_7day',
    nameFa: '۷ روز شکم',
    nameEn: '7 Day Abs',
    descriptionFa: 'هفته‌ای تمرکز روی عضلات شکم.',
    difficulty: 2,
    goalCode: 'core',
    days: [
      WorkoutProgramDaySeed(dayNumber: 1, nameFa: 'روز ۱ - شکم', templateCode: 'abs_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 2, nameFa: 'روز ۲ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 3, nameFa: 'روز ۳ - ۱۵ دقیقه شکم', templateCode: 'quick_15min_abs'),
      WorkoutProgramDaySeed(dayNumber: 4, nameFa: 'روز ۴ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 5, nameFa: 'روز ۵ - شکم', templateCode: 'abs_intermediate'),
      WorkoutProgramDaySeed(dayNumber: 6, nameFa: 'روز ۶ - استراحت', isRestDay: true),
      WorkoutProgramDaySeed(dayNumber: 7, nameFa: 'روز ۷ - ۱۵ دقیقه شکم', templateCode: 'quick_15min_abs'),
    ],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// ترکیب همه‌ی templates
// ════════════════════════════════════════════════════════════════════════════

const List<WorkoutTemplateSeed> kWorkoutTemplates = [
  ...kQuickWorkouts,
  ...kMuscleGroupTemplates,
];
