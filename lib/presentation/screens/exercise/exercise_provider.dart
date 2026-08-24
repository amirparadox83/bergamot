import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/exercise_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/entities/bergamot_streak_calculator.dart';

// ─── DAO ────────────────────────────────────────────────────────────────────

/// پرووایدر DAO تمرین
final exerciseDaoProvider = Provider<ExerciseDao>((ref) {
  return ExerciseDao(ref.watch(bergamotDatabaseProvider));
});

// ─── Exercises ──────────────────────────────────────────────────────────────

/// ناتیفایر لیست تمرینات
/// تمام تمرینات را از دیتابیس واچ می‌کند
class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async {
    final dao = ref.watch(exerciseDaoProvider);
    return dao.watchAllExercises().first;
  }

  /// بازخوانی لیست
  void refresh() {
    ref.invalidateSelf();
  }
}

/// پرووایدر لیست تمرینات
final exercisesProvider =
    AsyncNotifierProvider<ExercisesNotifier, List<Exercise>>(
  ExercisesNotifier.new,
);

// ─── Workouts (history) ────────────────────────────────────────────────────

/// ناتیفایر تاریخچه جلسات تمرین
class WorkoutsNotifier extends AsyncNotifier<List<Workout>> {
  @override
  Future<List<Workout>> build() async {
    final db = ref.watch(bergamotDatabaseProvider);
    final workouts = await (db.select(db.workouts)
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return workouts.take(5).toList();
  }

  /// بازخوانی
  void refresh() {
    ref.invalidateSelf();
  }
}

/// پرووایدر لیست جلسات تمرین (آخرین ۵)
final workoutsProvider =
    AsyncNotifierProvider<WorkoutsNotifier, List<Workout>>(
  WorkoutsNotifier.new,
);

// ─── Active Workout ────────────────────────────────────────────────────────

/// مدل یک ست تکمیل‌شده
class CompletedSet {
  final int setIndex;
  final double? weightKg;
  final int? reps;

  const CompletedSet({
    required this.setIndex,
    this.weightKg,
    this.reps,
  });
}

/// مدل تمرین داخل جلسه فعال
class ActiveExercise {
  final int exerciseId;
  final String name;
  final int sets;
  final int? reps;
  final double? weightKg;
  final int restSeconds;
  final List<CompletedSet> completedSets;
  final String category;

  const ActiveExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.reps,
    this.weightKg,
    required this.restSeconds,
    this.completedSets = const [],
    required this.category,
  });

  ActiveExercise copyWith({
    List<CompletedSet>? completedSets,
    double? weightKg,
    int? reps,
    int? restSeconds,
  }) {
    return ActiveExercise(
      exerciseId: exerciseId,
      name: name,
      sets: sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      completedSets: completedSets ?? this.completedSets,
      category: category,
    );
  }

  /// آیا تمام ست‌ها انجام شده؟
  bool get isAllSetsDone => completedSets.length >= sets;

  /// شماره ست بعدی (۱-base)
  int get nextSetNumber => completedSets.length + 1;
}

/// وضعیت جلسه تمرین فعال
class ActiveWorkoutState {
  /// شناسه جلسه تمرین (بعد از ذخیره در دیتابیس)
  final int? workoutId;

  /// نام جلسه
  final String name;

  /// لیست تمرینات جلسه
  final List<ActiveExercise> exercises;

  /// زمان شروع
  final DateTime startTime;

  /// آیا تمرین در حال اجراست؟
  final bool isRunning;

  /// آیا تمرین متوقف شده (استراحت)؟
  final bool isPaused;

  /// شاخص تمرین فعلی
  final int currentExerciseIndex;

  ActiveWorkoutState({
    this.workoutId,
    this.name = '',
    this.exercises = const [],
    DateTime? startTime,
    this.isRunning = false,
    this.isPaused = false,
    this.currentExerciseIndex = 0,
  }) : startTime = startTime ?? DateTime.now();

  factory ActiveWorkoutState.empty() {
    return ActiveWorkoutState(
      workoutId: null,
      name: '',
      exercises: const [],
      startTime: DateTime.fromMillisecondsSinceEpoch(0),
      isRunning: false,
      isPaused: false,
      currentExerciseIndex: 0,
    );
  }

  ActiveWorkoutState copyWith({
    int? workoutId,
    String? name,
    List<ActiveExercise>? exercises,
    DateTime? startTime,
    bool? isRunning,
    bool? isPaused,
    int? currentExerciseIndex,
  }) {
    return ActiveWorkoutState(
      workoutId: workoutId ?? this.workoutId,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      currentExerciseIndex:
          currentExerciseIndex ?? this.currentExerciseIndex,
    );
  }

  /// تمرین فعلی
  ActiveExercise? get currentExercise {
    if (exercises.isEmpty || currentExerciseIndex >= exercises.length) {
      return null;
    }
    return exercises[currentExerciseIndex];
  }

  /// آیا جلسه فعال است؟
  bool get isActive => workoutId != null;
}

// ─── Workout Builder State ─────────────────────────────────────────────────

/// مدل آیتم تمرین در سازنده جلسه
class WorkoutBuilderItem {
  final int exerciseId;
  final String name;
  final String category;
  int sets;
  int? reps;
  double? weightKg;
  int restSeconds;

  WorkoutBuilderItem({
    required this.exerciseId,
    required this.name,
    required this.category,
    this.sets = 3,
    this.reps = 12,
    this.weightKg,
    this.restSeconds = 90,
  });

  WorkoutBuilderItem copyWith({
    int? sets,
    int? reps,
    double? weightKg,
    int? restSeconds,
  }) {
    return WorkoutBuilderItem(
      exerciseId: exerciseId,
      name: name,
      category: category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}

/// وضعیت سازنده جلسه تمرین
class WorkoutBuilderState {
  final String name;
  final List<WorkoutBuilderItem> items;

  const WorkoutBuilderState({
    this.name = '',
    this.items = const [],
  });

  WorkoutBuilderState copyWith({
    String? name,
    List<WorkoutBuilderItem>? items,
  }) {
    return WorkoutBuilderState(
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}

// ─── Active Workout Notifier ───────────────────────────────────────────────

/// ناتیفایر جلسه تمرین فعال
class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final Ref _ref;

  ActiveWorkoutNotifier(this._ref) : super(ActiveWorkoutState.empty());

  /// شروع جلسه تمرین جدید از آیتم‌های سازنده
  Future<void> startWorkout({
    required String name,
    required List<WorkoutBuilderItem> items,
  }) async {
    final dao = _ref.read(exerciseDaoProvider);
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    // ایجاد جلسه در دیتابیس
    final workoutId = await dao.insertWorkout(WorkoutsCompanion.insert(
      name: name,
      date: todayStart,
      startTime: now.millisecondsSinceEpoch,
      createdAt: now.millisecondsSinceEpoch,
    ));

    // تبدیل آیتم‌ها به ActiveExercise و ذخیره در دیتابیس
    final activeExercises = <ActiveExercise>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      await dao.insertWorkoutExercise(WorkoutExercisesCompanion.insert(
        workoutId: workoutId,
        exerciseId: Value(item.exerciseId),
        exerciseName: item.name,
        orderIndex: i,
        sets: item.sets,
        reps: Value(item.reps),
        weightKg: Value(item.weightKg),
        restSeconds: Value(item.restSeconds),
      ));

      activeExercises.add(ActiveExercise(
        exerciseId: item.exerciseId,
        name: item.name,
        sets: item.sets,
        reps: item.reps,
        weightKg: item.weightKg,
        restSeconds: item.restSeconds,
        category: item.category,
      ));
    }

    state = ActiveWorkoutState(
      workoutId: workoutId,
      name: name,
      exercises: activeExercises,
      startTime: now,
      isRunning: true,
      currentExerciseIndex: 0,
    );
  }

  /// شروع جلسه تمرین از یک WorkoutTemplate (PHASE 3.4)
  ///
  /// این متد به‌جای بازنویسی کامل صفحه Active Workout، یک لایه‌ی adapter
  /// است که `WorkoutTemplateExercise` (مدل v7) را به `WorkoutBuilderItem`
  /// (مدلی که Active Workout Screen از قبل انتظار دارد) تبدیل می‌کند.
  ///
  /// [templateId] شناسه‌ی template در دیتابیس.
  /// [templateName] نام template (به‌عنوان نام جلسه تمرین استفاده می‌شود).
  Future<void> startWorkoutFromTemplate({
    required int templateId,
    required String templateName,
  }) async {
    final dao = _ref.read(exerciseDaoProvider);
    final templateExercises = await dao.getTemplateExercises(templateId);

    // Convert WorkoutTemplateExercise (v7) → WorkoutBuilderItem (legacy UI model)
    final items = <WorkoutBuilderItem>[];
    for (final row in templateExercises) {
      final item = row.item;
      final ex = row.exercise;
      items.add(WorkoutBuilderItem(
        exerciseId: ex.id,
        name: ex.nameFa,
        category: ex.category,
        sets: item.sets,
        reps: item.reps,
        restSeconds: item.restSeconds,
      ));
    }

    if (items.isEmpty) {
      // Nothing to start
      return;
    }

    // Reuse the existing startWorkout path so the Active Workout screen
    // works as before — no UI rewrite needed.
    await startWorkout(name: templateName, items: items);
  }

  /// ثبت تکمیل ست فعلی
  void completeSet({double? weightKg, int? reps}) {
    final current = state.currentExercise;
    if (current == null) return;

    final newCompleted = [
      ...current.completedSets,
      CompletedSet(
        setIndex: current.nextSetNumber - 1,
        weightKg: weightKg,
        reps: reps,
      ),
    ];

    final updatedExercise = current.copyWith(
      completedSets: newCompleted,
      weightKg: weightKg,
      reps: reps,
    );

    final newExercises = List<ActiveExercise>.from(state.exercises);
    newExercises[state.currentExerciseIndex] = updatedExercise;

    state = state.copyWith(exercises: newExercises);
  }

  /// رفتن به تمرین بعدی
  void nextExercise() {
    if (state.currentExerciseIndex < state.exercises.length - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
      );
    }
  }

  /// رفتن به تمرین قبلی
  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex - 1,
      );
    }
  }

  /// رفتن به تمرین با شاخص مشخص
  void goToExercise(int index) {
    if (index >= 0 && index < state.exercises.length) {
      state = state.copyWith(currentExerciseIndex: index);
    }
  }

  /// مکث/ادامه تمرین
  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  /// اتمام جلسه تمرین
  Future<void> finishWorkout() async {
    final workoutId = state.workoutId;
    if (workoutId == null) return;

    final dao = _ref.read(exerciseDaoProvider);
    await dao.completeWorkout(workoutId);

    state = ActiveWorkoutState.empty();
  }

  /// لغو تمرین
  void cancelWorkout() {
    state = ActiveWorkoutState.empty();
  }
}

/// پرووایدر جلسه تمرین فعال
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>(
  ActiveWorkoutNotifier.new,
);

// ─── Workout Builder Notifier ──────────────────────────────────────────────

/// ناتیفایر سازنده جلسه تمرین
class WorkoutBuilderNotifier extends StateNotifier<WorkoutBuilderState> {
  WorkoutBuilderNotifier(Ref ref)
      : super(const WorkoutBuilderState());

  /// تنظیم نام جلسه
  void setName(String name) {
    state = state.copyWith(name: name);
  }

  /// افزودن تمرین به لیست
  void addExercise(WorkoutBuilderItem item) {
    state = state.copyWith(
      items: [...state.items, item],
    );
  }

  /// حذف تمرین از لیست
  void removeExercise(int index) {
    if (index < 0 || index >= state.items.length) return;
    final newItems = List<WorkoutBuilderItem>.from(state.items)
      ..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  /// بروزرسانی آیتم تمرین
  void updateItem(int index, WorkoutBuilderItem item) {
    if (index < 0 || index >= state.items.length) return;
    final newItems = List<WorkoutBuilderItem>.from(state.items);
    newItems[index] = item;
    state = state.copyWith(items: newItems);
  }

  /// پاک‌سازی
  void clear() {
    state = const WorkoutBuilderState();
  }
}

/// پرووایدر سازنده جلسه تمرین
final workoutBuilderProvider =
    StateNotifierProvider<WorkoutBuilderNotifier, WorkoutBuilderState>(
  WorkoutBuilderNotifier.new,
);

// ─── Helpers ────────────────────────────────────────────────────────────────

// ─── Favorite Exercises (PHASE 3.2) ────────────────────────────────────────

/// پرووایدر لیست تمرین‌های مورد علاقه (واچ از دیتابیس)
final favoriteExercisesProvider =
    StreamProvider<List<Exercise>>((ref) async* {
  final dao = ref.watch(exerciseDaoProvider);
  yield* dao.watchFavoriteExercises();
});

/// پرووایدر مجموعه‌ی ID های تمرین‌های مورد علاقه
///
/// استفاده: در Exercise Library برای نمایش state دکمه قلب.
final favoriteExerciseIdsProvider =
    FutureProvider<Set<int>>((ref) async {
  // watch favoriteExercisesProvider تا وقتی تغییر می‌کند، دوباره محاسبه شود
  final favAsync = ref.watch(favoriteExercisesProvider);
  final favs = favAsync.maybeWhen(
    data: (list) => list,
    orElse: () => <Exercise>[],
  );
  return favs.map((e) => e.id).toSet();
});

/// Notifier برای toggle favorite
class FavoriteExerciseNotifier extends StateNotifier<Set<int>> {
  final Ref _ref;
  FavoriteExerciseNotifier(this._ref) : super({}) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final dao = _ref.read(exerciseDaoProvider);
    final favs = await dao.getFavoriteExercises();
    state = favs.map((e) => e.id).toSet();
  }

  /// Toggle favorite status of an exercise
  Future<void> toggle(int exerciseId) async {
    final dao = _ref.read(exerciseDaoProvider);
    await dao.toggleFavoriteExercise(exerciseId);
    // Update local state immediately for responsive UI
    if (state.contains(exerciseId)) {
      state = Set.from(state)..remove(exerciseId);
    } else {
      state = Set.from(state)..add(exerciseId);
    }
  }

  bool isFavorite(int exerciseId) => state.contains(exerciseId);
}

final favoriteExerciseNotifierProvider =
    StateNotifierProvider<FavoriteExerciseNotifier, Set<int>>(
  FavoriteExerciseNotifier.new,
);

// ─── Workout Streak & Progress (PHASE 3.3) ──────────────────────────────────

/// اطلاعات پیشرفت تمرین برای نمایش در صفحه اصلی
class WorkoutProgressInfo {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final int totalMinutes;
  final int totalEstimatedCalories;
  final List<({DateTime date, int workouts, int calories})> last7Days;

  const WorkoutProgressInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.totalEstimatedCalories,
    required this.last7Days,
  });
}

/// پرووایدر اطلاعات پیشرفت تمرین
final workoutProgressProvider =
    FutureProvider<WorkoutProgressInfo>((ref) async {
  final dao = ref.watch(exerciseDaoProvider);
  final now = DateTime.now();

  // گرفتن تمام تمرینات ۹۰ روز اخیر برای streak calculation
  final recentWorkouts = await dao.getWorkoutsInLastDays(90);

  // محاسبه streak با BergamotStreakCalculator (static methods)
  final currentStreak = BergamotStreakCalculator.calculateCurrentStreak(
    workouts: recentWorkouts,
    today: now,
  );
  final longestStreak = BergamotStreakCalculator.calculateLongestStreak(
    workouts: recentWorkouts,
  );
  final last7Days = BergamotStreakCalculator.last7DaysSeries(recentWorkouts);

  // مجموع آمار
  final totalWorkouts = await dao.getTotalWorkoutsCount();
  final totalMinutes = await dao.getTotalMinutes();
  final totalCalories = await dao.getTotalEstimatedCalories();

  return WorkoutProgressInfo(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    totalWorkouts: totalWorkouts,
    totalMinutes: totalMinutes,
    totalEstimatedCalories: totalCalories,
    last7Days: last7Days,
  );
});

/// نام فارسی دسته‌بندی تمرین
String categoryFa(String category) {
  switch (category) {
    case 'chest':
      return 'سینه';
    case 'back':
      return 'پشت';
    case 'shoulder':
      return 'شانه';
    case 'bicep':
      return 'جلو بازو';
    case 'tricep':
      return 'پشت بازو';
    case 'leg':
      return 'پا';
    case 'glute':
      return 'سرینی';
    case 'core':
      return 'شکم';
    case 'cardio':
      return 'هوازی';
    case 'stretch':
      return 'کشش';
    default:
      return category;
  }
}

/// نام فارسی تجهیزات
String equipmentFa(String equipment) {
  switch (equipment) {
    case 'bodyweight':
      return 'وزن بدن';
    case 'dumbbell':
      return 'دمبل';
    case 'barbell':
      return 'هالتر';
    case 'machine':
      return 'دستگاه';
    case 'cable':
      return 'کابل';
    case 'band':
      return 'باند';
    default:
      return equipment;
  }
}

/// لیست تمام دسته‌بندی‌ها
const List<CategoryFilterItem> categoryFilters = [
  CategoryFilterItem(key: 'all', label: 'همه'),
  CategoryFilterItem(key: 'chest', label: 'سینه'),
  CategoryFilterItem(key: 'back', label: 'پشت'),
  CategoryFilterItem(key: 'shoulder', label: 'شانه'),
  CategoryFilterItem(key: 'bicep', label: 'جلو بازو'),
  CategoryFilterItem(key: 'tricep', label: 'پشت بازو'),
  CategoryFilterItem(key: 'leg', label: 'پا'),
  CategoryFilterItem(key: 'glute', label: 'سرینی'),
  CategoryFilterItem(key: 'core', label: 'شکم'),
  CategoryFilterItem(key: 'cardio', label: 'هوازی'),
  CategoryFilterItem(key: 'stretch', label: 'کشش'),
];

/// آیتم فیلتر دسته‌بندی
class CategoryFilterItem {
  final String key;
  final String label;
  const CategoryFilterItem({required this.key, required this.label});
}

/// فرمت تاریخ فارسی
String formatDateFa(int epochMs) {
  final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final months = [
    'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن',
    'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// فرمت مدت زمان
String formatDuration(int? minutes) {
  if (minutes == null) return '—';
  if (minutes < 60) return '$minutes دقیقه';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '$h ساعت و $m دقیقه' : '$h ساعت';
}
