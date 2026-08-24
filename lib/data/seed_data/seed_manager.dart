import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/drift.dart';

import '../../domain/entities/ingredient_matcher.dart';
import '../database/bergamot_database.dart';
import 'iranian_exercises.dart';
import 'curated_exercises.dart';
import 'workout_reference_data.dart';
import 'workout_templates_seed.dart';

/// مدیریت داده‌های اولیه Bergamot
///
/// این کلاس در اولین اجرای برنامه (یا بعد از upgrade به schema v7) فراخوانی می‌شود
/// و داده‌های زیر را در دیتابیس درج می‌کند:
///
///  - FoodCategories (۲۲ دسته)
///  - Foods (دیتابیس curated شامل USDA + مواد ایرانی)
///  - Recipes + RecipeIngredients (دستور پخت غذاهای ایرانی)
///  - Exercises legacy (داده‌های قدیمی از iranian_exercises.dart)
///  - MuscleGroups (۱۶ گروه عضلانی — v7)
///  - Curated Exercises (تمرین‌های اضافی Bergamot — v7)
///  - ExerciseMuscleGroups (junction — v7)
///  - WorkoutTemplates (پیش‌فرض — v7)
///  - WorkoutTemplateExercises
///  - WorkoutPrograms (چندروزه — v7)
///  - WorkoutProgramDays
///
/// منبع داده‌ها: assets/data/bergamot_foods.json که توسط pipeline خارج از runtime
/// پردازش شده — از USDA FoodData Central + منابع ایرانی.
class SeedManager {
  /// بررسی و درج داده‌های اولیه در صورت نیاز
  ///
  /// این متد باید در اولین اجرای برنامه (بعد از BergamotDatabase.init) فراخوانی شود.
  /// آیدی‌امپوتنت: اگر رکورد با همان (source, externalId) موجود باشد، skip می‌شود.
  static Future<void> seedIfNeeded(BergamotDatabase db) async {
    await _seedCategories(db);
    await _seedFoods(db);
    await _seedRecipes(db);
    await _seedExercises(db);
    // v7 — Workout System
    await _seedMuscleGroups(db);
    await _seedCuratedExercises(db);
    await _seedExerciseMuscleGroups(db);
    await _seedWorkoutTemplates(db);
    await _seedWorkoutPrograms(db);
  }

  // ────────────────────────────────────────────────────────────────────
  // Categories
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedCategories(BergamotDatabase db) async {
    final existing = await db.select(db.foodCategories).get();
    if (existing.isNotEmpty) return;

    final raw = await rootBundle.loadString(
      'assets/data/bergamot_categories.json',
    );
    final data = json.decode(raw) as Map<String, dynamic>;
    final cats = data['categories'] as List<dynamic>;

    await db.batch((b) {
      for (final c in cats) {
        b.insert(
          db.foodCategories,
          FoodCategoriesCompanion.insert(
            code: c['code'] as String,
            nameEn: c['nameEn'] as String,
            nameFa: c['nameFa'] as String,
            normalizedNameFa: Value(c['normalizedNameFa'] as String? ?? ''),
            normalizedNameEn: Value(c['normalizedNameEn'] as String? ?? ''),
            icon: const Value('restaurant'),
          ),
        );
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────
  // Foods
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedFoods(BergamotDatabase db) async {
    // فقط در صورتی seed می‌کنیم که جدول foods خالی از رکوردهای Bergamot باشد.
    // غذاهای سفارشی کاربر (isCustom=1) هرگز پاک نمی‌شوند.
    final existingCount = await (db.selectOnly(db.foods)
          ..addColumns([db.foods.id.count()])
          ..where(db.foods.source.isNotIn(['CUSTOM'])))
        .getSingle();
    final n = existingCount.read(db.foods.id.count());
    if (n != null && n > 0) {
      // Food database already seeded — skip.
      return;
    }

    final raw = await rootBundle.loadString('assets/data/bergamot_foods.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final foods = data['foods'] as List<dynamic>;

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.batch((b) {
      for (final f in foods) {
        final source = f['source'] as String? ?? 'CUSTOM';
        final servingSize = (f['servingSize'] as num?)?.toDouble();
        final caloriesPer100g = (f['caloriesPer100g'] as num?)?.toDouble();
        final proteinPer100g = (f['proteinPer100g'] as num?)?.toDouble();
        final fatPer100g = (f['fatPer100g'] as num?)?.toDouble();
        final carbsPer100g = (f['carbsPer100g'] as num?)?.toDouble();
        final fiberPer100g = (f['fiberPer100g'] as num?)?.toDouble();

        double? perServing(double? per100g) {
          if (per100g == null || servingSize == null || servingSize <= 0) {
            return null;
          }
          return per100g * servingSize / 100.0;
        }

        b.insert(
          db.foods,
          FoodsCompanion.insert(
            nameFa: Value(f['nameFa'] as String?),
            nameEn: f['nameEn'] as String,
            normalizedNameFa: Value(f['normalizedNameFa'] as String? ?? ''),
            normalizedNameEn: Value(f['normalizedNameEn'] as String? ?? ''),
            categoryId: Value(f['categoryId'] as String? ?? 'other'),
            caloriesPer100g: Value(caloriesPer100g),
            proteinPer100g: Value(proteinPer100g),
            fatPer100g: Value(fatPer100g),
            carbsPer100g: Value(carbsPer100g),
            fiberPer100g: Value(fiberPer100g),
            sugarPer100g: Value((f['sugarPer100g'] as num?)?.toDouble()),
            sodiumPer100g: Value((f['sodiumPer100g'] as num?)?.toDouble()),
            potassiumPer100g:
                Value((f['potassiumPer100g'] as num?)?.toDouble()),
            calciumPer100g: Value((f['calciumPer100g'] as num?)?.toDouble()),
            ironPer100g: Value((f['ironPer100g'] as num?)?.toDouble()),
            servingSize: Value(servingSize),
            servingUnit: Value(f['servingUnit'] as String? ?? 'gram'),
            servingDescriptionFa:
                Value(f['servingDescriptionFa'] as String?),
            servingDescriptionEn:
                Value(f['servingDescriptionEn'] as String?),
            source: Value(source),
            externalId: Value(f['externalId'] as String?),
            barcode: Value(f['barcode'] as String?),
            brand: Value(f['brand'] as String?),
            isCustom: Value(f['isCustom'] as bool? ?? false),
            isVerified: Value(f['isVerified'] as bool? ?? false),
            verificationStatus:
                Value(f['verificationStatus'] as String? ?? 'NEEDS_VERIFICATION'),
            preparationState: Value(f['preparationState'] as String?),
            createdAt: now,
            // Legacy per-serving columns (deprecated but kept for compat with
            // any code that still reads them)
            caloriesPerServing: Value(perServing(caloriesPer100g) ?? 0),
            proteinPerServing: Value(perServing(proteinPer100g) ?? 0),
            fatPerServing: Value(perServing(fatPer100g) ?? 0),
            carbPerServing: Value(perServing(carbsPer100g) ?? 0),
            fiberPerServing: Value(perServing(fiberPer100g) ?? 0),
          ),
        );
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────
  // Recipes
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedRecipes(BergamotDatabase db) async {
    final existing = await db.select(db.recipes).get();
    if (existing.isNotEmpty) return;

    final raw = await rootBundle.loadString('assets/data/bergamot_recipes.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final recipes = data['recipes'] as List<dynamic>;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Load all foods ONCE for efficient matching.
    // The IngredientMatcher is a pure-Dart utility that handles exact match,
    // plural/singular, token-superset, token-subset, and token-overlap
    // strategies. This is required because USDA naming conventions
    // (e.g. "onions raw" plural, "beans kidney red mature seeds raw") do
    // not match the simpler recipe ingredientKeys ("onion raw",
    // "kidney beans raw") without smart fallback.
    final allFoods = await db.select(db.foods).get();
    final candidates = allFoods
        .map((f) => FoodCandidate(
              id: f.id,
              normalizedNameEn: f.normalizedNameEn,
              source: f.source,
              nameFa: f.nameFa,
            ))
        .toList();
    const matcher = IngredientMatcher();

    int totalIngredients = 0;
    int totalMatched = 0;

    for (final r in recipes) {
      final recipeId = await db.into(db.recipes).insert(
            RecipesCompanion.insert(
              nameFa: r['nameFa'] as String,
              nameEn: r['nameEn'] as String,
              normalizedNameFa:
                  Value(r['normalizedNameFa'] as String? ?? ''),
              normalizedNameEn:
                  Value(r['normalizedNameEn'] as String? ?? ''),
              categoryId: Value(r['categoryId'] as String? ?? 'iranian_foods'),
              totalYieldGrams: (r['totalYieldGrams'] as num).toDouble(),
              servingSize: (r['servingSize'] as num).toDouble(),
              servingUnit: Value(r['servingUnit'] as String? ?? 'plate'),
              servingDescriptionFa:
                  Value(r['servingDescriptionFa'] as String?),
              source: Value(r['source'] as String? ?? 'IRANIAN_RECIPE'),
              verificationStatus: Value(
                  r['verificationStatus'] as String? ?? 'COMMUNITY_RECIPE'),
              isCustom: Value(r['isCustom'] as bool? ?? false),
              notes: Value(r['notes'] as String?),
              createdAt: now,
            ),
          );

      // Resolve ingredient keys to Food IDs using the smart matcher.
      final ingredients = r['ingredients'] as List<dynamic>;
      int order = 0;
      int matchedCount = 0;
      final unmatchedKeys = <String>[];
      for (final ing in ingredients) {
        final key = ing['ingredientKey'] as String;
        final grams = (ing['grams'] as num).toDouble();
        totalIngredients++;

        final result = matcher.findBestMatch(
          ingredientKey: key,
          foods: candidates,
        );

        if (result == null) {
          // Ingredient not found — skip. Recipe nutrition will be partial.
          // We do NOT fail the whole seed — partial recipe is still useful.
          // ignore: avoid_print
          print('[seed] recipe ingredient not found: $key '
              '(recipe: ${r['nameFa']})');
          unmatchedKeys.add(key);
          continue;
        }

        await db.into(db.recipeIngredients).insert(
              RecipeIngredientsCompanion.insert(
                recipeId: recipeId,
                foodId: result.food.id,
                grams: grams,
                orderIndex: Value(order++),
              ),
            );
        matchedCount++;
        totalMatched++;
      }

      final ratio = ingredients.isEmpty
          ? 0.0
          : matchedCount / ingredients.length;
      // ignore: avoid_print
      print('[seed] recipe "${r['nameFa']}": '
          '$matchedCount/${ingredients.length} matched '
          '(${(ratio * 100).round()}%) '
          'strategy=smart-match'
          '${unmatchedKeys.isEmpty ? '' : ' unmatched=$unmatchedKeys'}');
    }

    // ignore: avoid_print
    print('[seed] recipes: total ingredients matched=$totalMatched/'
        '$totalIngredients '
        '(${totalIngredients == 0 ? 0 : (totalMatched * 100 / totalIngredients).round()}%)');
  }

  // ────────────────────────────────────────────────────────────────────
  // Exercises (legacy)
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedExercises(BergamotDatabase db) async {
    final exerciseCount = await db.select(db.exercises).get();
    if (exerciseCount.isEmpty) {
      await db.batch((b) {
        b.insertAll(db.exercises, getIranianExerciseSeedData());
      });
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // PHASE 8 — Muscle Groups reference data (v7)
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedMuscleGroups(BergamotDatabase db) async {
    final existing = await db.select(db.muscleGroups).get();
    if (existing.isNotEmpty) return;

    await db.batch((b) {
      for (final m in kMuscleGroups) {
        b.insert(
          db.muscleGroups,
          MuscleGroupsCompanion.insert(
            code: m.code,
            nameEn: m.nameEn,
            nameFa: m.nameFa,
            normalizedNameFa: Value(m.nameFa.toLowerCase()),
            normalizedNameEn: Value(m.nameEn.toLowerCase()),
            icon: Value(m.icon),
          ),
        );
      }
    });
    // ignore: avoid_print
    print('[seed v7] inserted ${kMuscleGroups.length} muscle groups');
  }

  // ────────────────────────────────────────────────────────────────────
  // PHASE 10 — Curated Exercises (v7)
  // Idempotent: اگر externalId موجود باشد، skip می‌شود.
  //
  // TODO: Currently does one SELECT per exercise for idempotency check.
  // Could be optimized to batch-check with a single IN-clause query.
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedCuratedExercises(BergamotDatabase db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    int added = 0;
    int skipped = 0;

    for (final ex in kCuratedExercises) {
      final externalId = ex.computedExternalId;
      // Idempotency check
      final exists = await (db.select(db.exercises)
            ..where((t) => t.externalId.equals(externalId)))
          .getSingleOrNull();
      if (exists != null) {
        skipped++;
        continue;
      }

      // Normalize name for search
      final normalizedNameFa = _normalizeFa(ex.nameFa);
      final normalizedNameEn = _normalizeEn(ex.nameEn);

      await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
              nameFa: ex.nameFa,
              nameEn: Value(ex.nameEn),
              normalizedNameFa: Value(normalizedNameFa),
              normalizedNameEn: Value(normalizedNameEn),
              category: ex.category,
              equipment: ex.equipment,
              difficulty: ex.difficulty,
              instructionsFa: Value(ex.instructionsFa),
              muscleGroups: ex.primaryMuscle,  // legacy CSV field (single item for compat)
              // v7 new fields
              primaryMuscle: Value(ex.primaryMuscle),
              exerciseType: Value(ex.exerciseType),
              isBodyweight: Value(ex.equipment == 'bodyweight'),
              isTimed: Value(ex.exerciseType == 'time_based'),
              defaultSets: Value(ex.defaultSets),
              defaultReps: Value(ex.defaultReps),
              defaultDurationSeconds: Value(ex.defaultDurationSeconds),
              restSeconds: Value(ex.restSeconds),
              caloriesEstimatePerRep: Value(ex.caloriesEstimatePerRep),
              tips: Value(ex.tips),
              commonMistakes: Value(ex.commonMistakes),
              source: const Value('BERGAMOT_CURATED'),
              externalId: Value(externalId),
              imageAsset: const Value(null),
              videoUrl: const Value(null),
              isCustom: const Value(false),
              createdAt: now,
              updatedAt: Value(now),
            ),
          );
      added++;
    }
    // ignore: avoid_print
    print('[seed v7] curated exercises: added=$added, skipped=$skipped');
  }

  // ────────────────────────────────────────────────────────────────────
  // PHASE 10 — ExerciseMuscleGroups (junction)
  // برای هر exercise: primary + secondaries را در junction table ذخیره کن
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedExerciseMuscleGroups(BergamotDatabase db) async {
    // اگر قبلاً seed شده، skip
    final existingCount = await (db.selectOnly(db.exerciseMuscleGroups)
          ..addColumns([db.exerciseMuscleGroups.id.count()]))
        .getSingle();
    final n = existingCount.read(db.exerciseMuscleGroups.id.count());
    if (n != null && n > 0) return;

    // برای همه‌ی exercises (legacy + curated)
    final allExercises = await db.select(db.exercises).get();
    int inserted = 0;
    for (final ex in allExercises) {
      // اگر primaryMuscle داشتیم، اضافه‌اش کن
      if (ex.primaryMuscle != null && ex.primaryMuscle!.isNotEmpty) {
        await db.into(db.exerciseMuscleGroups).insert(
              ExerciseMuscleGroupsCompanion.insert(
                exerciseId: ex.id,
                muscleGroupCode: ex.primaryMuscle!,
                role: const Value('primary'),
                orderIndex: const Value(0),
              ),
            );
        inserted++;

        // اضافه‌کردن secondary muscles از muscleGroups legacy CSV
        // (در legacy فقط نام فارسی ذخیره شده، برای primary از primaryMuscle استفاده می‌کنیم)
      }
    }
    // ignore: avoid_print
    print('[seed v7] exercise_muscle_groups: inserted=$inserted');
  }

  // ────────────────────────────────────────────────────────────────────
  // PHASE 11 — Workout Templates (preset workouts)
  //
  // TODO: Each template does a SELECT for idempotency + per-exercise
  // name lookup. Batch-check externalIds first, then batch lookup
  // exercise names. Also, recipe ingredients are inserted one-by-one
  // instead of in a batch.
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedWorkoutTemplates(BergamotDatabase db) async {
    // Idempotent: اگر externalId موجود باشد، skip
    final now = DateTime.now().millisecondsSinceEpoch;
    int added = 0;
    int skipped = 0;

    for (final tmpl in kWorkoutTemplates) {
      final exists = await (db.select(db.workoutTemplates)
            ..where((t) => t.externalId.equals(tmpl.externalId)))
          .getSingleOrNull();
      if (exists != null) {
        skipped++;
        continue;
      }

      final templateId = await db.into(db.workoutTemplates).insert(
            WorkoutTemplatesCompanion.insert(
              code: tmpl.code,
              nameFa: tmpl.nameFa,
              nameEn: Value(tmpl.nameEn),
              normalizedNameFa: Value(_normalizeFa(tmpl.nameFa)),
              normalizedNameEn: Value(_normalizeEn(tmpl.nameEn)),
              descriptionFa: Value(tmpl.descriptionFa),
              difficulty: Value(tmpl.difficulty),
              goalCode: Value(tmpl.goalCode),
              durationMinutes: Value(tmpl.durationMinutes),
              caloriesEstimate: Value(tmpl.caloriesEstimate),
              equipment: Value(tmpl.equipment),
              muscleGroups: Value(tmpl.muscleGroups),
              isPreset: const Value(true),
              isQuick: Value(tmpl.isQuick),
              source: const Value('BERGAMOT_PRESET'),
              externalId: Value(tmpl.externalId),
              createdAt: now,
            ),
          );

      // اضافه‌کردن تمرین‌های template با lookup به نام فارسی
      int order = 0;
      for (final item in tmpl.exercises) {
        // پیدا کردن exercise با nameFa دقیق
        final exMatch = await (db.select(db.exercises)
              ..where((t) => t.nameFa.equals(item.exerciseNameFa))
              ..limit(1))
            .getSingleOrNull();
        if (exMatch == null) {
          // ignore: avoid_print
          print('[seed v7] template exercise not found: ${item.exerciseNameFa} (template: ${tmpl.nameFa})');
          continue;
        }
        await db.into(db.workoutTemplateExercises).insert(
              WorkoutTemplateExercisesCompanion.insert(
                templateId: templateId,
                exerciseId: exMatch.id,
                orderIndex: order++,
                sets: Value(item.sets),
                reps: Value(item.reps),
                durationSeconds: Value(item.durationSeconds),
                restSeconds: Value(item.restSeconds),
                isTimed: Value(item.isTimed),
                notesFa: Value(item.notesFa),
              ),
            );
      }
      added++;
    }
    // ignore: avoid_print
    print('[seed v7] workout templates: added=$added, skipped=$skipped');
  }

  // ────────────────────────────────────────────────────────────────────
  // PHASE 11 — Workout Programs (multi-day)
  // ────────────────────────────────────────────────────────────────────
  static Future<void> _seedWorkoutPrograms(BergamotDatabase db) async {
    final existing = await db.select(db.workoutPrograms).get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    int addedPrograms = 0;
    int addedDays = 0;

    for (final prog in kWorkoutPrograms) {
      final programId = await db.into(db.workoutPrograms).insert(
            WorkoutProgramsCompanion.insert(
              code: prog.code,
              nameFa: prog.nameFa,
              nameEn: Value(prog.nameEn),
              descriptionFa: Value(prog.descriptionFa),
              difficulty: Value(prog.difficulty),
              goalCode: Value(prog.goalCode),
              dayCount: prog.days.length,
              isCustom: const Value(false),
              source: const Value('BERGAMOT_PRESET'),
              createdAt: now,
            ),
          );

      for (final day in prog.days) {
        // پیدا کردن template با code
        int? templateId;
        if (!day.isRestDay && day.templateCode != null) {
          final tmpl = await (db.select(db.workoutTemplates)
                ..where((t) => t.code.equals(day.templateCode!))
                ..limit(1))
              .getSingleOrNull();
          templateId = tmpl?.id;
        }
        await db.into(db.workoutProgramDays).insert(
              WorkoutProgramDaysCompanion.insert(
                programId: programId,
                dayNumber: day.dayNumber,
                nameFa: day.nameFa,
                isRestDay: Value(day.isRestDay),
                templateId: Value(templateId),
                notesFa: Value(day.notesFa),
              ),
            );
        addedDays++;
      }
      addedPrograms++;
    }
    // ignore: avoid_print
    print('[seed v7] workout programs: $addedPrograms programs, $addedDays days');
  }

  // ────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────

  // TODO: reuse BergamotTextNormalizer.normalize() to avoid divergence
  /// Normalize Persian text (ي→ی، ك→ک، ZWNJ→space، lowercase)
  static String _normalizeFa(String s) {
    if (s.isEmpty) return '';
    var r = s;
    r = r.replaceAll('\u064A', '\u06CC'); // ي → ی
    r = r.replaceAll('\u0643', '\u06A9'); // ك → ک
    r = r.replaceAll('\u200C', ' ');      // ZWNJ → space
    r = r.replaceAll(_faPunctRe, ' ');
    r = r.replaceAll(_wsRe, ' ').trim();
    return r.toLowerCase();
  }

  // TODO: reuse BergamotTextNormalizer.normalize() to avoid divergence
  /// Normalize English text (lowercase, trim, collapse whitespace)
  static String _normalizeEn(String s) {
    if (s.isEmpty) return '';
    var r = s;
    r = r.replaceAll(_enPunctRe, ' ');
    r = r.replaceAll(_wsRe, ' ').trim();
    return r.toLowerCase();
  }
}

// Pre-compiled regexes for normalize helpers
final _faPunctRe = RegExp(r'[\u0600-\u0606\u060C\u060D\u061B\u061E\u061F\u2000-\u206F]');
final _enPunctRe = RegExp(r'''[!?,;:"'`(){}\[\]/\\@#$%^&*+=<>|~]''');
final _wsRe = RegExp(r'\s+');
