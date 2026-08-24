# Bergamot Workout System — Migration Plan (PHASE 4)

**تاریخ:** 2026-08-24  
**Schema فعلی:** v6  
**Schema هدف:** v7

## استراتژی کلی

بدون reset دیتابیس، schema v7 را با migration اضافی ایجاد می‌کنیم.

## تغییرات Schema

### جداول جدید (8 جدول)
1. `MuscleGroups` — 16 گروه عضلانی reference
2. `ExerciseMuscleGroups` — many-to-many Exercise↔MuscleGroup با role primary/secondary
3. `WorkoutTemplates` — preset workouts (جدا از session history)
4. `WorkoutTemplateExercises` — آیتم‌های هر template
5. `WorkoutPrograms` — برنامه‌های چندروزه
6. `WorkoutProgramDays` — روزهای هر program
7. `FavoriteExercises` — علاقه‌مندی‌های کاربر
8. `FavoriteWorkouts` — علاقه‌مندی‌های workout

### ستون‌های جدید در Exercises موجود (16 ستون)
normalizedNameFa, normalizedNameEn, primaryMuscle, exerciseType, isBodyweight, isTimed,
defaultSets, defaultReps, defaultDurationSeconds, restSeconds, caloriesEstimatePerRep,
tips, commonMistakes, source, externalId, imageAsset, videoUrl, updatedAt

### ستون‌های جدید در Workouts (session history) — 5 ستون
templateId, totalReps, totalSets, estimatedCalories, isRestDay

### ستون‌های جدید در WorkoutExercises — 2 ستون
durationSeconds, isTimed

## استراتژی Migration
- بدون DROP/DELETE
- ALTER TABLE ADD COLUMN برای ستون‌های جدید
- Backfill از داده‌های موجود (muscleGroups CSV → primaryMuscle و ...)
- Seed جدید به‌صورت idempotent با شرط `externalId IS NULL`
