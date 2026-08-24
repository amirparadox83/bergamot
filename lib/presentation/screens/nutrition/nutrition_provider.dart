import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/nutrition_dao.dart';
import '../../../data/database/database_provider.dart';

/// پرووایدر DAO تغذیه
final nutritionDaoProvider = Provider<NutritionDao>((ref) {
  return NutritionDao(ref.watch(bergamotDatabaseProvider));
});

/// نام‌های فارسی انواع وعده غذایی
const Map<int, String> mealTypeNames = {
  0: 'صبحانه',
  1: 'ناهار',
  2: 'شام',
  3: 'میان‌وعده',
};

/// آیکون‌های انواع وعده غذایی
const Map<int, IconData> mealTypeIcons = {
  0: Icons.wb_sunny_outlined,
  1: Icons.lunch_dining_outlined,
  2: Icons.dinner_dining_outlined,
  3: Icons.cookie_outlined,
};

/// Notifier وعده‌های غذایی امروز
///
/// لیست وعده‌های امروز را از دیتابیس می‌خواند و امکان افزودن/حذف فراهم می‌کند.
class TodayMealsNotifier extends AsyncNotifier<List<MealEntry>> {
  @override
  Future<List<MealEntry>> build() async {
    final dao = ref.watch(nutritionDaoProvider);
    final meals = await dao.watchTodayMeals().first;
    return meals;
  }

  /// افزودن غذای جدید به یک وعده
  ///
  /// مقادیر nutrition به‌عنوان snapshot ذخیره می‌شوند — یعنی اگر غذا در آینده
  /// تغییر کند، meal_entry دست‌نخورده باقی می‌ماند.
  Future<void> addMeal({
    required int foodId,
    required String foodName,
    required int mealType,
    required double servingCount,
    required double calories,
    required double protein,
    required double fat,
    required double carb,
    double? fiber,
    double? grams,
    String? foodSource,
    String? foodExternalId,
  }) async {
    final dao = ref.read(nutritionDaoProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    await dao.insertMeal(MealEntriesCompanion.insert(
      date: startOfDay,
      mealType: mealType,
      foodId: Value(foodId),
      foodName: foodName,
      servingCount: Value(servingCount),
      calories: calories,
      protein: protein,
      fat: fat,
      carb: carb,
      fiber: Value(fiber),
      grams: Value(grams),
      foodSource: Value(foodSource),
      foodExternalId: Value(foodExternalId),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    ref.invalidateSelf();
  }

  /// حذف وعده غذایی
  Future<void> deleteMeal(int id) async {
    final dao = ref.read(nutritionDaoProvider);
    await dao.deleteMeal(id);
    ref.invalidateSelf();
  }
}

/// پرووایدر لیست وعده‌های غذایی امروز
final todayMealsProvider =
    AsyncNotifierProvider<TodayMealsNotifier, List<MealEntry>>(
  TodayMealsNotifier.new,
);

/// خلاصه‌ی تغذیه‌ی امروز
///
/// از لیست وعده‌ها مجموع کالری و ماکروها محاسبه می‌شود.
class TodayNutrition {
  final double calories;
  final double protein;
  final double fat;
  final double carb;

  const TodayNutrition({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carb = 0,
  });
}

/// پرووایدر محاسبه‌شده‌ی خلاصه تغذیه امروز
final todayNutritionProvider = Provider<TodayNutrition>((ref) {
  final mealsAsync = ref.watch(todayMealsProvider);
  return mealsAsync.when(
    data: (meals) {
      double cal = 0, pro = 0, fat = 0, carb = 0;
      for (final m in meals) {
        cal += m.calories;
        pro += m.protein;
        fat += m.fat;
        carb += m.carb;
      }
      return TodayNutrition(
        calories: cal,
        protein: pro,
        fat: fat,
        carb: carb,
      );
    },
    loading: () => const TodayNutrition(),
    error: (_, __) => const TodayNutrition(),
  );
});

/// نام واحد سروینگ به فارسی
String servingUnitFa(String unit) {
  switch (unit) {
    case 'gram':
      return 'گرم';
    case 'piece':
      return 'عدد';
    case 'spoon':
      return 'قاشق';
    case 'glass':
      return 'لیوان';
    case 'palm':
      return 'کف دست';
    case 'plate':
      return 'بشقاب';
    default:
      return unit;
  }
}
