import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/entities/bergamot_text_normalizer.dart';

// ────────────────────────────────────────────────────────────────────────────
// مدل نتایج جستجو
// ────────────────────────────────────────────────────────────────────────────

/// نتیجه جستجوی غذا
class FoodSearchResult {
  const FoodSearchResult({
    required this.id,
    required this.nameFa,
    required this.categoryId,
    required this.caloriesPerServing,
    required this.needsVerification,
  });

  final int id;
  final String nameFa;
  final String categoryId;
  final double caloriesPerServing;
  final bool needsVerification;
}

/// نتیجه جستجوی تمرین
class ExerciseSearchResult {
  const ExerciseSearchResult({
    required this.id,
    required this.nameFa,
    required this.category,
    required this.muscleGroups,
  });

  final int id;
  final String nameFa;
  final String category;
  final String muscleGroups;
}

/// نتیجه جستجوی برنامه تمرینی
class WorkoutSearchResult {
  const WorkoutSearchResult({
    required this.id,
    required this.nameFa,
    required this.difficulty,
    required this.dayCount,
  });

  final String id;
  final String nameFa;
  final int difficulty;
  final int dayCount;
}

/// نتیجه جستجوی عادت
class HabitSearchResult {
  const HabitSearchResult({
    required this.id,
    required this.name,
    required this.frequency,
  });

  final int id;
  final String name;
  final int frequency;
}

/// تمام نتایج جستجو
///
/// نتایج بر اساس دسته‌بندی گروه‌بندی شده‌اند.
class SearchResults {
  const SearchResults({
    this.foods = const [],
    this.exercises = const [],
    this.workouts = const [],
    this.habits = const [],
  });

  final List<FoodSearchResult> foods;
  final List<ExerciseSearchResult> exercises;
  final List<WorkoutSearchResult> workouts;
  final List<HabitSearchResult> habits;

  bool get isEmpty =>
      foods.isEmpty && exercises.isEmpty && workouts.isEmpty && habits.isEmpty;

  int get totalCount =>
      foods.length + exercises.length + workouts.length + habits.length;
}

// ────────────────────────────────────────────────────────────────────────────
// پرووایدرها
// ────────────────────────────────────────────────────────────────────────────

// NOTE: exerciseDaoProvider and nutritionDaoProvider are defined in
// exercise_provider.dart and nutrition_provider.dart respectively.
// Do NOT re-define them here to avoid ProviderAlreadyExistsException.

/// پرووایدر جستجوی عمومی — family بر اساس عبارت جستجو
///
/// جستجو با ۳۰۰ میلی‌ثانیه دیبونس انجام می‌شود.
final searchProvider =
    FutureProvider.family<SearchResults, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return const SearchResults();
  }

  final db = ref.read(bergamotDatabaseProvider);
  final trimmed = query.trim();

  // جستجوی موازی در تمام دسته‌بندی‌ها
  final results = await Future.wait([
    _searchFoods(ref, trimmed),
    _searchExercises(ref, trimmed),
    _searchWorkouts(ref, trimmed),
    _searchHabits(db, trimmed),
  ]);

  return SearchResults(
    foods: results[0] as List<FoodSearchResult>,
    exercises: results[1] as List<ExerciseSearchResult>,
    workouts: results[2] as List<WorkoutSearchResult>,
    habits: results[3] as List<HabitSearchResult>,
  );
});

/// پرووایدر عبارت جستجو با دیبونس
///
/// خروجی رشته جاری پس از ۳۰۰ میلی‌ثانیه بدون تایپ.
final debouncedQueryProvider =
    StateNotifierProvider<DebouncedQueryNotifier, String>((ref) {
  return DebouncedQueryNotifier();
});

/// نوتیفایر دیبونس — بعد از ۳۰۰ میلی‌ثانیه بدون تغییر، مقدار جدید اعلام می‌شود
class DebouncedQueryNotifier extends StateNotifier<String> {
  DebouncedQueryNotifier() : super('');
  Timer? _timer;

  /// بروزرسانی عبارت جستجو با دیبونس
  void update(String query) {
    _timer?.cancel();
    if (query.isEmpty) {
      _timer = null;
      state = '';
      return;
    }
    _timer = Timer(const Duration(milliseconds: 300), () {
      state = query;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// توابع جستجوی داخلی
// ────────────────────────────────────────────────────────────────────────────

Future<List<FoodSearchResult>> _searchFoods(Ref ref, String query) async {
  final normalized = BergamotTextNormalizer.normalize(query);
  final foods = await ref.read(nutritionDaoProvider).searchFoods(normalized);
  return foods
      .map((f) {
        final calPer100 = f.caloriesPer100g ?? 0.0;
        final serving = f.servingSize ?? 100.0;
        return FoodSearchResult(
          id: f.id,
          nameFa: f.nameFa?.isNotEmpty == true ? f.nameFa! : f.nameEn,
          categoryId: f.categoryId,
          caloriesPerServing: calPer100 * serving / 100.0,
          needsVerification: f.verificationStatus == 'NEEDS_VERIFICATION',
        );
      })
      .toList();
}

Future<List<ExerciseSearchResult>> _searchExercises(
    Ref ref, String query) async {
  final normalized = BergamotTextNormalizer.normalize(query);
  final exercises = await ref.read(exerciseDaoProvider).searchExercises(normalized);
  return exercises
      .map((e) => ExerciseSearchResult(
            id: e.id,
            nameFa: e.nameFa,
            category: e.category,
            muscleGroups: e.muscleGroups,
          ))
      .toList();
}

Future<List<WorkoutSearchResult>> _searchWorkouts(
    Ref ref, String query) async {
  // PHASE 3.1: جستجو در دیتابیس (نه داده‌ی قدیمی const Dart)
  // از جدول WorkoutPrograms استفاده می‌کنیم که در v7 seed شده است.
  final dao = ref.read(exerciseDaoProvider);
  final programs = await dao.getAllPrograms();
  final q = BergamotTextNormalizer.normalize(query);
  return programs
      .where((p) =>
          BergamotTextNormalizer.normalize(p.nameFa).contains(q) ||
          BergamotTextNormalizer.normalize(p.descriptionFa ?? '').contains(q))
      .map((p) => WorkoutSearchResult(
            id: p.id.toString(),
            nameFa: p.nameFa,
            difficulty: p.difficulty,
            dayCount: p.dayCount,
          ))
      .toList();
}

Future<List<HabitSearchResult>> _searchHabits(
    BergamotDatabase db, String query) async {
  final normalized = BergamotTextNormalizer.normalize(query);
  final habits = await (db.select(db.habits)
        ..where((t) =>
            t.name.like('%$normalized%') & t.isArchived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)])
        ..limit(20))
      .get();
  return habits
      .map((h) => HabitSearchResult(
            id: h.id,
            name: h.name,
            frequency: h.frequency,
          ))
      .toList();
}
