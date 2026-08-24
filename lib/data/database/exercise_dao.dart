import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// DAO تمرینات Bergamot — schema v7
///
/// شامل متدهای دسترسی به:
///   - Exercises (legacy + curated)
///   - MuscleGroups + ExerciseMuscleGroups (junction)
///   - WorkoutTemplates + WorkoutTemplateExercises
///   - WorkoutPrograms + WorkoutProgramDays
///   - Favorites (Exercise + Workout Template)
///   - Workouts (session history)
///   - WorkoutExercises (session items)
class ExerciseDao {
  final BergamotDatabase db;
  ExerciseDao(this.db);

  // ════════════════════════════════════════════════════════════════════
  // MuscleGroups
  // ════════════════════════════════════════════════════════════════════

  Future<List<MuscleGroup>> getAllMuscleGroups() {
    return (db.select(db.muscleGroups)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<MuscleGroup?> getMuscleGroupByCode(String code) {
    return (db.select(db.muscleGroups)
          ..where((t) => t.code.equals(code))
          ..limit(1))
        .getSingleOrNull();
  }

  /// گرفتن همه‌ی گروه‌های عضلانی یک exercise
  /// به‌همراه نقش هر کدام (primary / secondary)
  Future<List<({MuscleGroup muscle, String role, int orderIndex})>>
      getMuscleGroupsForExercise(int exerciseId) async {
    final query = db.select(db.exerciseMuscleGroups).join([
      innerJoin(db.muscleGroups,
          db.muscleGroups.code.equalsExp(db.exerciseMuscleGroups.muscleGroupCode)),
    ])
      ..where(db.exerciseMuscleGroups.exerciseId.equals(exerciseId))
      ..orderBy([OrderingTerm.asc(db.exerciseMuscleGroups.orderIndex)]);
    final rows = await query.get();
    return rows.map((row) {
      final emg = row.readTable(db.exerciseMuscleGroups);
      final mg = row.readTable(db.muscleGroups);
      return (
        muscle: mg,
        role: emg.role,
        orderIndex: emg.orderIndex,
      );
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════
  // Exercises — search and filter (v7 with normalized names)
  // ════════════════════════════════════════════════════════════════════

  /// واچ تمام تمرینات
  Stream<List<Exercise>> watchAllExercises() {
    return db.select(db.exercises).watch();
  }

  /// جستجوی تمرین بر اساس نام نرمالایز شده (فارسی یا انگلیسی)
  ///
  /// query باید قبلاً از BergamotTextNormalizer.normalize عبور کرده باشد.
  Future<List<Exercise>> searchExercises(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return (db.select(db.exercises)
            ..orderBy([(t) => OrderingTerm.asc(t.nameFa)])
            ..limit(20))
          .get();
    }
    final pattern = '%$q%';
    return (db.select(db.exercises)
          ..where((t) =>
              t.normalizedNameFa.like(pattern) |
              t.normalizedNameEn.like(pattern) |
              t.nameFa.like(pattern) |
              t.nameEn.like(pattern))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isBodyweight),
            (t) => OrderingTerm.asc(t.nameFa),
          ])
          ..limit(50))
        .get();
  }

  /// فیلتر تمرینات بر اساس دسته‌بندی قدیمی (chest/back/...)
  Future<List<Exercise>> getExercisesByCategory(String category) {
    return (db.select(db.exercises)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.asc(t.nameFa)]))
        .get();
  }

  /// فیلتر ترکیبی تمرینات (v7)
  ///
  /// هر پارامتر NULL = بدون فیلتر روی آن
  Future<List<Exercise>> filterExercises({
    String? primaryMuscle,
    int? difficulty,
    String? equipment,
    String? goalCode,
    String? exerciseType,
    int limit = 50,
  }) {
    final q = db.select(db.exercises);
    if (primaryMuscle != null) {
      q.where((t) => t.primaryMuscle.equals(primaryMuscle));
    }
    if (difficulty != null) {
      q.where((t) => t.difficulty.equals(difficulty));
    }
    if (equipment != null) {
      // equipment field in v7 is single code (legacy)
      // برای no_equipment هم bodyweight هم no_equipment شامل می‌شوند
      if (equipment == 'no_equipment') {
        q.where((t) => t.equipment.isIn(['no_equipment', 'bodyweight']) |
            t.isBodyweight.equals(true));
      } else {
        q.where((t) => t.equipment.equals(equipment));
      }
    }
    if (exerciseType != null) {
      q.where((t) => t.exerciseType.equals(exerciseType));
    }
    q
      ..orderBy([
        (t) => OrderingTerm.desc(t.isBodyweight),
        (t) => OrderingTerm.asc(t.nameFa),
      ])
      ..limit(limit);
    return q.get();
  }

  /// گرفتن یک Exercise با id
  Future<Exercise?> getExerciseById(int id) {
    return (db.select(db.exercises)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// افزودن تمرین سفارشی کاربر
  Future<int> insertExercise(ExercisesCompanion entry) {
    return db.into(db.exercises).insert(entry);
  }

  // ════════════════════════════════════════════════════════════════════
  // Workout Templates (preset workouts)
  // ════════════════════════════════════════════════════════════════════

  /// لیست تمام Templates
  Future<List<WorkoutTemplate>> getAllTemplates({
    int? difficulty,
    String? goalCode,
    bool? isQuick,
    int? durationMinutes,
  }) {
    final q = db.select(db.workoutTemplates);
    if (difficulty != null) {
      q.where((t) => t.difficulty.equals(difficulty));
    }
    if (goalCode != null) {
      q.where((t) => t.goalCode.equals(goalCode));
    }
    if (isQuick != null) {
      q.where((t) => t.isQuick.equals(isQuick));
    }
    if (durationMinutes != null) {
      q.where((t) => t.durationMinutes.equals(durationMinutes));
    }
    q.orderBy([
      (t) => OrderingTerm.asc(t.difficulty),
      (t) => OrderingTerm.asc(t.nameFa),
    ]);
    return q.get();
  }

  /// جستجوی Template بر اساس نام نرمالایز شده
  Future<List<WorkoutTemplate>> searchTemplates(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return (db.select(db.workoutTemplates)
            ..orderBy([(t) => OrderingTerm.asc(t.nameFa)])
            ..limit(20))
          .get();
    }
    final pattern = '%$q%';
    return (db.select(db.workoutTemplates)
          ..where((t) =>
              t.normalizedNameFa.like(pattern) |
              t.normalizedNameEn.like(pattern) |
              t.nameFa.like(pattern) |
              t.nameEn.like(pattern))
          ..orderBy([(t) => OrderingTerm.asc(t.nameFa)])
          ..limit(20))
        .get();
  }

  /// گرفتن یک Template با id
  Future<WorkoutTemplate?> getTemplateById(int id) {
    return (db.select(db.workoutTemplates)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// گرفتن آیتم‌های یک Template (به‌همراه Exercise داده‌ها)
  Future<List<({WorkoutTemplateExercise item, Exercise exercise})>>
      getTemplateExercises(int templateId) async {
    final query = db.select(db.workoutTemplateExercises).join([
      innerJoin(db.exercises,
          db.exercises.id.equalsExp(db.workoutTemplateExercises.exerciseId)),
    ])
      ..where(db.workoutTemplateExercises.templateId.equals(templateId))
      ..orderBy([OrderingTerm.asc(db.workoutTemplateExercises.orderIndex)]);
    final rows = await query.get();
    return rows.map((row) {
      final item = row.readTable(db.workoutTemplateExercises);
      final ex = row.readTable(db.exercises);
      return (item: item, exercise: ex);
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════
  // Workout Programs (multi-day)
  // ════════════════════════════════════════════════════════════════════

  Future<List<WorkoutProgram>> getAllPrograms({int? difficulty}) {
    final q = db.select(db.workoutPrograms);
    if (difficulty != null) {
      q.where((t) => t.difficulty.equals(difficulty));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.difficulty)]);
    return q.get();
  }

  Future<WorkoutProgram?> getProgramById(int id) {
    return (db.select(db.workoutPrograms)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<WorkoutProgramDay>> getProgramDays(int programId) {
    return (db.select(db.workoutProgramDays)
          ..where((t) => t.programId.equals(programId))
          ..orderBy([(t) => OrderingTerm.asc(t.dayNumber)]))
        .get();
  }

  // ════════════════════════════════════════════════════════════════════
  // Favorites
  // ════════════════════════════════════════════════════════════════════

  /// toggle favorite exercise
  Future<void> toggleFavoriteExercise(int exerciseId) async {
    final existing = await (db.select(db.favoriteExercises)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) {
      await db.into(db.favoriteExercises).insert(
            FavoriteExercisesCompanion.insert(
              exerciseId: exerciseId,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } else {
      await (db.delete(db.favoriteExercises)
            ..where((t) => t.id.equals(existing.id)))
          .go();
    }
  }

  Future<bool> isFavoriteExercise(int exerciseId) async {
    final existing = await (db.select(db.favoriteExercises)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..limit(1))
        .getSingleOrNull();
    return existing != null;
  }

  /// لیست تمرین‌های مورد علاقه (با join به Exercises)
  Future<List<Exercise>> getFavoriteExercises() async {
    final query = db.select(db.favoriteExercises).join([
      innerJoin(db.exercises,
          db.exercises.id.equalsExp(db.favoriteExercises.exerciseId)),
    ])
      ..orderBy([OrderingTerm.desc(db.favoriteExercises.createdAt)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.exercises)).toList();
  }

  /// واچ تمرین‌های مورد علاقه
  Stream<List<Exercise>> watchFavoriteExercises() {
    final query = db.select(db.favoriteExercises).join([
      innerJoin(db.exercises,
          db.exercises.id.equalsExp(db.favoriteExercises.exerciseId)),
    ])
      ..orderBy([OrderingTerm.desc(db.favoriteExercises.createdAt)]);
    return query.watch().map((rows) =>
        rows.map((row) => row.readTable(db.exercises)).toList());
  }

  /// toggle favorite workout template
  Future<void> toggleFavoriteWorkout(int templateId) async {
    final existing = await (db.select(db.favoriteWorkouts)
          ..where((t) => t.templateId.equals(templateId))
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) {
      await db.into(db.favoriteWorkouts).insert(
            FavoriteWorkoutsCompanion.insert(
              templateId: templateId,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } else {
      await (db.delete(db.favoriteWorkouts)
            ..where((t) => t.id.equals(existing.id)))
          .go();
    }
  }

  Future<bool> isFavoriteWorkout(int templateId) async {
    final existing = await (db.select(db.favoriteWorkouts)
          ..where((t) => t.templateId.equals(templateId))
          ..limit(1))
        .getSingleOrNull();
    return existing != null;
  }

  /// لیست Templates مورد علاقه
  Future<List<WorkoutTemplate>> getFavoriteWorkouts() async {
    final query = db.select(db.favoriteWorkouts).join([
      innerJoin(db.workoutTemplates,
          db.workoutTemplates.id.equalsExp(db.favoriteWorkouts.templateId)),
    ])
      ..orderBy([OrderingTerm.desc(db.favoriteWorkouts.createdAt)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.workoutTemplates)).toList();
  }

  // ════════════════════════════════════════════════════════════════════
  // Workouts (session history) — legacy methods
  // ════════════════════════════════════════════════════════════════════

  /// جلسات تمرین بر اساس محدوده تاریخ
  Future<List<Workout>> getWorkoutsByDateRange(int start, int end) {
    return (db.select(db.workouts)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// ایجاد جلسه تمرین جدید
  Future<int> insertWorkout(WorkoutsCompanion entry) {
    return db.into(db.workouts).insert(entry);
  }

  /// افزودن تمرین به جلسه
  Future<int> insertWorkoutExercise(WorkoutExercisesCompanion entry) {
    return db.into(db.workoutExercises).insert(entry);
  }

  /// بروزرسانی تمرین داخل جلسه
  Future<bool> updateWorkoutExercise(
      WorkoutExercisesCompanion entry, int id) {
    return (db.update(db.workoutExercises)..where((t) => t.id.equals(id)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// علامت‌گذاری جلسه تمرین به‌عنوان تکمیل‌شده
  Future<bool> completeWorkout(int id) async {
    final now = DateTime.now();
    final workout = await (db.select(db.workouts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (workout == null) return false;
    final duration =
        (now.millisecondsSinceEpoch - workout.startTime) ~/ 60000;
    final rows = await (db.update(db.workouts)..where((t) => t.id.equals(id)))
        .write(
      WorkoutsCompanion(
        isCompleted: const Value(true),
        endTime: Value(now.millisecondsSinceEpoch),
        durationMinutes: Value(duration),
      ),
    );
    return rows > 0;
  }

  /// آخرین جلسه تمرین برای یک تمرین خاص (Progressive Overload)
  Future<WorkoutExercise?> getLastWorkoutForExercise(int exerciseId) async {
    final query = db.select(db.workoutExercises)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..where((t) => t.isCompleted.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  // ════════════════════════════════════════════════════════════════════
  // History queries (v7 — برای progress / streak)
  // ════════════════════════════════════════════════════════════════════

  /// تعداد کل جلسات تمرین تکمیل‌شده
  Future<int> getTotalWorkoutsCount() async {
    final r = await (db.selectOnly(db.workouts)
          ..addColumns([db.workouts.id.count()])
          ..where(db.workouts.isCompleted.equals(true)))
        .getSingle();
    return r.read(db.workouts.id.count()) ?? 0;
  }

  /// مجموع دقیقه‌های تمرین
  Future<int> getTotalMinutes() async {
    final r = await (db.selectOnly(db.workouts)
          ..addColumns([db.workouts.durationMinutes.sum()])
          ..where(db.workouts.isCompleted.equals(true)))
        .getSingle();
    return r.read(db.workouts.durationMinutes.sum()) ?? 0;
  }

  /// مجموع کالری تخمینی
  Future<int> getTotalEstimatedCalories() async {
    final r = await (db.selectOnly(db.workouts)
          ..addColumns([db.workouts.estimatedCalories.sum()])
          ..where(db.workouts.isCompleted.equals(true)))
        .getSingle();
    return r.read(db.workouts.estimatedCalories.sum()) ?? 0;
  }

  /// جلسات تمرین در N روز اخیر (برای weekly/monthly stats)
  Future<List<Workout>> getWorkoutsInLastDays(int days) async {
    final now = DateTime.now();
    final startMs = now.subtract(Duration(days: days)).millisecondsSinceEpoch;
    return (db.select(db.workouts)
          ..where((t) => t.date.isBiggerOrEqualValue(startMs))
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// جلسات تمرین امروز
  Future<List<Workout>> getTodayWorkouts() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 24 * 60 * 60 * 1000;
    return (db.select(db.workouts)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  // ════════════════════════════════════════════════════════════════════
  // Custom Workout Template creation (PHASE 17)
  // ════════════════════════════════════════════════════════════════════

  /// ساخت یک Workout Template سفارشی با تمام آیتم‌های آن
  ///
  /// این متد در یک تراکنش انجام می‌شود تا اگر خطایی رخ داد،
  /// هیچ رکوردی ذخیره نشود.
  Future<int> createCustomTemplate({
    required String nameFa,
    String? nameEn,
    String? descriptionFa,
    int difficulty = 1,
    String? goalCode,
    int? durationMinutes,
    int? caloriesEstimate,
    String equipment = 'no_equipment',
    String muscleGroups = 'full_body',
    required List<({int exerciseId, int sets, int? reps, int? durationSeconds, int restSeconds, bool isTimed, String? notesFa})> items,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final code = 'custom_$now';
    final externalId = 'CUSTOM:$code';

    return db.transaction(() async {
      final templateId = await db.into(db.workoutTemplates).insert(
            WorkoutTemplatesCompanion.insert(
              code: code,
              nameFa: nameFa,
              nameEn: Value(nameEn ?? nameFa),
              normalizedNameFa: Value(nameFa.toLowerCase()),
              normalizedNameEn: Value((nameEn ?? nameFa).toLowerCase()),
              descriptionFa: Value(descriptionFa),
              difficulty: Value(difficulty),
              goalCode: Value(goalCode),
              durationMinutes: Value(durationMinutes),
              caloriesEstimate: Value(caloriesEstimate),
              equipment: Value(equipment),
              muscleGroups: Value(muscleGroups),
              isPreset: const Value(false),
              isQuick: const Value(false),
              source: const Value('CUSTOM'),
              externalId: Value(externalId),
              createdAt: now,
            ),
          );

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await db.into(db.workoutTemplateExercises).insert(
              WorkoutTemplateExercisesCompanion.insert(
                templateId: templateId,
                exerciseId: item.exerciseId,
                orderIndex: i,
                sets: Value(item.sets),
                reps: Value(item.reps),
                durationSeconds: Value(item.durationSeconds),
                restSeconds: Value(item.restSeconds),
                isTimed: Value(item.isTimed),
                notesFa: Value(item.notesFa),
              ),
            );
      }

      return templateId;
    });
  }

  /// حذف یک Custom Template (preset templates قابل حذف نیستند)
  Future<int> deleteCustomTemplate(int templateId) async {
    return (db.delete(db.workoutTemplates)
          ..where((t) => t.id.equals(templateId))
          ..where((t) => t.isPreset.equals(false)))
        .go();
  }
}
