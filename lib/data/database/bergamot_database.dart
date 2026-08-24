import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/user_profile_table.dart';
import 'tables/sleep_table.dart';
import 'tables/food_table.dart';
import 'tables/food_category_table.dart';
import 'tables/recipe_table.dart';
import 'tables/meal_entry_table.dart';
import 'tables/water_table.dart';
import 'tables/exercise_table.dart';
import 'tables/workout_table.dart';
import 'tables/workout_exercise_table.dart';
import 'tables/muscle_group_table.dart';
import 'tables/workout_template_table.dart';
import 'tables/workout_program_table.dart';
import 'tables/favorite_table.dart';
import 'tables/weight_table.dart';
import 'tables/habit_table.dart';
import 'tables/habit_log_table.dart';
import 'tables/goal_table.dart';
import 'tables/body_measurement_table.dart';
import 'tables/daily_summary_table.dart';
import 'tables/settings_table.dart';
import 'tables/meal_template_table.dart';
import 'tables/achievement_table.dart';
import 'tables/daily_plan_table.dart';

part 'bergamot_database.g.dart';

/// دیتابیس اصلی برگاموت
/// تمام جداول Drift اینجا ثبت شده و برای کدجنریشن استفاده می‌شوند
/// نسخه فعلی دیتابیس: ۷
///
/// v7 — Workout System Upgrade:
///   - جدول‌های جدید: MuscleGroups, ExerciseMuscleGroups, WorkoutTemplates,
///     WorkoutTemplateExercises, WorkoutPrograms, WorkoutProgramDays,
///     FavoriteExercises, FavoriteWorkouts
///   - ستون‌های جدید در Exercises: normalizedNameFa/En, primaryMuscle,
///     exerciseType, isBodyweight, isTimed, defaultSets, defaultReps,
///     defaultDurationSeconds, restSeconds, caloriesEstimatePerRep,
///     tips, commonMistakes, source, externalId, imageAsset, videoUrl, updatedAt
///   - ستون‌های جدید در Workouts: templateId, totalReps, totalSets,
///     estimatedCalories, isRestDay
///   - ستون‌های جدید در WorkoutExercises: durationSeconds, isTimed
@DriftDatabase(
  tables: [
    UserProfiles,
    SleepEntries,
    Foods,
    FoodCategories,
    Recipes,
    RecipeIngredients,
    MealEntries,
    WaterEntries,
    Exercises,
    Workouts,
    WorkoutExercises,
    MuscleGroups,
    ExerciseMuscleGroups,
    WorkoutTemplates,
    WorkoutTemplateExercises,
    WorkoutPrograms,
    WorkoutProgramDays,
    FavoriteExercises,
    FavoriteWorkouts,
    WeightEntries,
    Habits,
    HabitLogs,
    Goals,
    BodyMeasurements,
    DailySummaries,
    AppSettings,
    MealTemplates,
    MealTemplateItems,
    Achievements,
    DailyPlans,
  ],
)
class BergamotDatabase extends _$BergamotDatabase {
  /// سازنده با QueryExecutor سفارشی
  BergamotDatabase(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(mealTemplates);
            await m.createTable(mealTemplateItems);
          }
          if (from < 3) {
            await m.createTable(achievements);
          }
          if (from < 4) {
            await m.createTable(dailyPlans);
          }
          if (from < 5) {
            // ── v5: Bergamot curated food database ────────────────────────
            await m.createTable(foodCategories);
            await m.createTable(recipes);
            await m.createTable(recipeIngredients);

            const newColumns = <String>[
              "normalizedNameFa TEXT NOT NULL DEFAULT ''",
              "normalizedNameEn TEXT NOT NULL DEFAULT ''",
              "categoryId TEXT NOT NULL DEFAULT 'other'",
              "caloriesPer100g REAL",
              "proteinPer100g REAL",
              "fatPer100g REAL",
              "carbsPer100g REAL",
              "fiberPer100g REAL",
              "sugarPer100g REAL",
              "sodiumPer100g REAL",
              "potassiumPer100g REAL",
              "calciumPer100g REAL",
              "ironPer100g REAL",
              "servingDescriptionFa TEXT",
              "servingDescriptionEn TEXT",
              "source TEXT NOT NULL DEFAULT 'CUSTOM'",
              "externalId TEXT",
              "barcode TEXT",
              "brand TEXT",
              "isVerified BOOLEAN NOT NULL DEFAULT 0",
              "verificationStatus TEXT NOT NULL DEFAULT 'NEEDS_VERIFICATION'",
              "preparationState TEXT",
              "updatedAt INTEGER",
            ];
            for (final colDef in newColumns) {
              final colName = colDef.split(' ')[0];
              await customStatement(
                'ALTER TABLE foods ADD COLUMN $colDef;',
              );
              debugPrint('[migrate v5] added column $colName to foods');
            }

            await customStatement('''
              UPDATE foods
              SET caloriesPer100g = ROUND(caloriesPerServing * 100.0 / NULLIF(servingSize, 0), 2),
                  proteinPer100g  = ROUND(proteinPerServing  * 100.0 / NULLIF(servingSize, 0), 2),
                  fatPer100g      = ROUND(fatPerServing      * 100.0 / NULLIF(servingSize, 0), 2),
                  carbsPer100g    = ROUND(carbPerServing     * 100.0 / NULLIF(servingSize, 0), 2),
                  fiberPer100g    = ROUND(fiberPerServing    * 100.0 / NULLIF(servingSize, 0), 2),
                  normalizedNameEn = LOWER(TRIM(nameEn)),
                  normalizedNameFa = LOWER(TRIM(nameFa)),
                  source = 'CUSTOM',
                  verificationStatus = 'NEEDS_VERIFICATION',
                  isVerified = 0,
                  updatedAt = CAST(strftime('%s','now') AS INTEGER) * 1000
              WHERE caloriesPer100g IS NULL
                AND caloriesPerServing IS NOT NULL
                AND servingSize IS NOT NULL
                AND servingSize > 0;
            ''');

            await _createIndexes(m);

            await customStatement(
              "DELETE FROM foods WHERE isCustom = 0 AND source = 'CUSTOM' AND externalId IS NULL;",
            );
            debugPrint('[migrate v5] cleared legacy non-custom foods');
          }
          if (from < 6) {
            // ── v6: MealEntries snapshot enhancements ───────────────────────
            // اضافه‌کردن ستون‌های snapshot برای حفظ تاریخچه تغذیه کاربر.
            // اگر غذا در آینده تغییر کند، meal_entry دست‌نخورده باقی می‌ماند.
            const newMealColumns = <String>[
              "foodSource TEXT",
              "foodExternalId TEXT",
              "grams REAL",
              "fiber REAL",
            ];
            for (final colDef in newMealColumns) {
              final colName = colDef.split(' ')[0];
              await customStatement(
                'ALTER TABLE meal_entries ADD COLUMN $colDef;',
              );
              debugPrint('[migrate v6] added column $colName to meal_entries');
            }

            // Backfill grams for existing rows using foods.servingSize
            // (best-effort — if food deleted, grams stays NULL)
            await customStatement('''
              UPDATE meal_entries
              SET grams = (SELECT servingSize FROM foods WHERE foods.id = meal_entries.foodId)
                          * meal_entries.servingCount
              WHERE grams IS NULL
                AND meal_entries.foodId IS NOT NULL
                AND EXISTS (SELECT 1 FROM foods WHERE foods.id = meal_entries.foodId
                            AND servingSize IS NOT NULL AND servingSize > 0);
            ''');
          }
          if (from < 7) {
            // ── v7: Workout System Upgrade ────────────────────────────────
            // 1. Create new tables
            await m.createTable(muscleGroups);
            await m.createTable(exerciseMuscleGroups);
            await m.createTable(workoutTemplates);
            await m.createTable(workoutTemplateExercises);
            await m.createTable(workoutPrograms);
            await m.createTable(workoutProgramDays);
            await m.createTable(favoriteExercises);
            await m.createTable(favoriteWorkouts);

            // 2. Add new columns to existing Exercises table (ALTER TABLE)
            const newExerciseColumns = <String>[
              "normalizedNameFa TEXT",
              "normalizedNameEn TEXT",
              "primaryMuscle TEXT",
              "exerciseType TEXT NOT NULL DEFAULT 'rep_based'",
              "isBodyweight BOOLEAN NOT NULL DEFAULT 0",
              "isTimed BOOLEAN NOT NULL DEFAULT 0",
              "defaultSets INTEGER NOT NULL DEFAULT 3",
              "defaultReps INTEGER",
              "defaultDurationSeconds INTEGER",
              "restSeconds INTEGER NOT NULL DEFAULT 30",
              "caloriesEstimatePerRep REAL",
              "tips TEXT",
              "commonMistakes TEXT",
              "source TEXT NOT NULL DEFAULT 'CUSTOM'",
              "externalId TEXT",
              "imageAsset TEXT",
              "videoUrl TEXT",
              "updatedAt INTEGER",
            ];
            for (final colDef in newExerciseColumns) {
              final colName = colDef.split(' ')[0];
              await customStatement(
                'ALTER TABLE exercises ADD COLUMN $colDef;',
              );
              debugPrint('[migrate v7] added column $colName to exercises');
            }

            // 3. Add new columns to Workouts (session history)
            const newWorkoutColumns = <String>[
              "templateId INTEGER REFERENCES workout_templates(id) ON DELETE SET NULL",
              "totalReps INTEGER",
              "totalSets INTEGER",
              "estimatedCalories INTEGER",
              "isRestDay BOOLEAN NOT NULL DEFAULT 0",
            ];
            for (final colDef in newWorkoutColumns) {
              final colName = colDef.split(' ')[0];
              await customStatement(
                'ALTER TABLE workouts ADD COLUMN $colDef;',
              );
              debugPrint('[migrate v7] added column $colName to workouts');
            }

            // 4. Add new columns to WorkoutExercises
            const newWorkoutExerciseColumns = <String>[
              "durationSeconds INTEGER",
              "isTimed BOOLEAN NOT NULL DEFAULT 0",
            ];
            for (final colDef in newWorkoutExerciseColumns) {
              final colName = colDef.split(' ')[0];
              await customStatement(
                'ALTER TABLE workout_exercises ADD COLUMN $colDef;',
              );
              debugPrint('[migrate v7] added column $colName to workout_exercises');
            }

            // 5. Backfill: normalizedNameFa/En from nameFa/nameEn
            await customStatement('''
              UPDATE exercises
              SET normalizedNameFa = LOWER(TRIM(nameFa)),
                  normalizedNameEn = LOWER(TRIM(COALESCE(nameEn, ''))),
                  source = 'BERGAMOT_LEGACY',
                  updatedAt = CAST(strftime('%s','now') AS INTEGER) * 1000
              WHERE normalizedNameFa IS NULL OR normalizedNameFa = '';
            ''');

            // 6. Backfill: isBodyweight from equipment
            await customStatement('''
              UPDATE exercises
              SET isBodyweight = 1
              WHERE equipment = 'bodyweight';
            ''');

            // 7. Backfill: primaryMuscle from muscleGroups CSV (first item)
            //    e.g. 'سینه,جلو شانه,سه‌سر بازو' → primaryMuscle = first item
            //    But we want the code, not the Persian name.
            //    Map Persian → code for known categories.
            await customStatement('''
              UPDATE exercises
              SET primaryMuscle = CASE
                WHEN muscleGroups LIKE '%سینه%' OR category = 'chest' THEN 'chest'
                WHEN muscleGroups LIKE '%زیربغل%' OR category = 'back' THEN 'back'
                WHEN muscleGroups LIKE '%شانه%' OR category = 'shoulder' THEN 'shoulders'
                WHEN muscleGroups LIKE '%جلو بازو%' OR category = 'bicep' THEN 'biceps'
                WHEN muscleGroups LIKE '%سه‌سر%' OR muscleGroups LIKE '%سه سر%' OR category = 'tricep' THEN 'triceps'
                WHEN muscleGroups LIKE '%پا%' OR muscleGroups LIKE '%ران%' OR muscleGroups LIKE '%پاستان%' OR category = 'leg' THEN 'quadriceps'
                WHEN muscleGroups LIKE '%سرینی%' OR category = 'glute' THEN 'glutes'
                WHEN muscleGroups LIKE '%شکم%' OR muscleGroups LIKE '%شکم%' OR category = 'core' THEN 'abs'
                WHEN muscleGroups LIKE '%هوازی%' OR category = 'cardio' THEN 'cardio'
                WHEN muscleGroups LIKE '%کشش%' OR category = 'stretch' THEN 'stretching'
                ELSE NULL
              END
              WHERE primaryMuscle IS NULL;
            ''');

            // 8. Backfill: restSeconds to default 90 (matching legacy default)
            await customStatement('''
              UPDATE exercises SET restSeconds = 90 WHERE restSeconds = 30 AND source = 'BERGAMOT_LEGACY';
            ''');

            // 9. Create indexes for new schema
            await _createWorkoutIndexes();

            debugPrint('[migrate v7] workout system upgrade complete');
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON;');
          // Create workout indexes if not exists (idempotent for fresh installs)
          if (details.versionBefore != null) {
            await _createWorkoutIndexes();
          }
        },
      );

  /// ایجاد indexهای search روی جداول foods و recipes
  ///
  /// توجه: Drift به‌طور پیش‌فرض ستون‌ها را به snake_case تبدیل می‌کند
  /// (مثلاً `normalizedNameFa` → `normalized_name_fa`). بنابراین در
  /// SQL دستی باید از شکل snake_case استفاده کنیم.
  Future<void> _createIndexes(Migrator m) async {
    // Search indexes (Persian + English normalized names)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_norm_fa ON foods (normalized_name_fa);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_norm_en ON foods (normalized_name_en);',
    );
    // Category filter index
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_category ON foods (category_id);',
    );
    // Barcode lookup (for future Open Food Facts integration)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_barcode ON foods (barcode);',
    );
    // Source + externalId for USDA updates
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_source_ext ON foods (source, external_id);',
    );
    // Recipe ingredients
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe ON recipe_ingredients (recipe_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_food ON recipe_ingredients (food_id);',
    );
    // Meal entries indexes (Stage 3 audit)
    await customStatement('CREATE INDEX IF NOT EXISTS idx_meal_entries_date ON meal_entries (date);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_meal_entries_date_mealtype ON meal_entries (date, meal_type);');
    // Sleep/Weight/Water indexes
    await customStatement('CREATE INDEX IF NOT EXISTS idx_sleep_entries_date ON sleep_entries (date);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_weight_entries_date ON weight_entries (date);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_water_entries_date ON water_entries (date);');
  }

  /// ایجاد indexهای جستجوی Workout (v7)
  Future<void> _createWorkoutIndexes() async {
    // Exercise search indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exercises_norm_fa ON exercises (normalized_name_fa);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exercises_norm_en ON exercises (normalized_name_en);',
    );
    // Exercise filter indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exercises_primary_muscle ON exercises (primary_muscle);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exercises_difficulty ON exercises (difficulty);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON exercises (equipment);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exercises_category ON exercises (category);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exercises_source ON exercises (source);',
    );
    // ExerciseMuscleGroups
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_emg_exercise ON exercise_muscle_groups (exercise_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_emg_muscle ON exercise_muscle_groups (muscle_group_code);',
    );
    // WorkoutTemplate indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wt_norm_fa ON workout_templates (normalized_name_fa);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wt_norm_en ON workout_templates (normalized_name_en);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wt_difficulty ON workout_templates (difficulty);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wt_goal ON workout_templates (goal_code);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wt_quick ON workout_templates (is_quick);',
    );
    // WorkoutTemplateExercises
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wte_template ON workout_template_exercises (template_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wte_exercise ON workout_template_exercises (exercise_id);',
    );
    // WorkoutPrograms
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wp_difficulty ON workout_programs (difficulty);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wp_goal ON workout_programs (goal_code);',
    );
    // WorkoutProgramDays
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wpd_program ON workout_program_days (program_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_wpd_template ON workout_program_days (template_id);',
    );
    // Favorites
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fav_ex ON favorite_exercises (exercise_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fav_wt ON favorite_workouts (template_id);',
    );
    // Workout session history (Workouts table)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_date ON workouts (date);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_template ON workouts (template_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_completed ON workouts (is_completed);',
    );
    // WorkoutExercises
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_we_workout ON workout_exercises (workout_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_we_exercise ON workout_exercises (exercise_id);',
    );
  }

  /// نمونه واحد دیتابیس (Singleton)
  /// با اولین فراخوانی مقداردهی تنبل (Lazy) می‌شود
  static late final BergamotDatabase instance;

  /// مقداردهی تنبل دیتابیس
  /// فایل دیتابیس در مسیر استاندارد برنامه ذخیره می‌شود
  static Future<void> init() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bergamot.db'));
    instance = BergamotDatabase(NativeDatabase.createInBackground(file));
  }

  /// بستن اتصال دیتابیس
  /// حتماً در زمان خروج از برنامه فراخوانی شود
  @override
  Future<void> close() async {
    // Only run WAL checkpoint if `instance` has been initialized
    // (in tests we use direct BergamotDatabase instances without going
    // through `init()`, so `instance` may not be set).
    try {
      await this.customSelect('PRAGMA wal_checkpoint(FULL)').get();
    } catch (e) {
      debugPrint('Error closing DB: $e');
    }
    await super.close();
  }
}
