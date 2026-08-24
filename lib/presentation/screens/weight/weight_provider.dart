import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/weight_dao.dart';
import '../../../data/database/profile_dao.dart';
import '../../../data/database/database_provider.dart';

/// پرووایدر DAO وزن
final weightDaoProvider = Provider<WeightDao>((ref) {
  return WeightDao(ref.watch(bergamotDatabaseProvider));
});

/// پرووایدر DAO پروفایل
final profileDaoProvider = Provider<ProfileDao>((ref) {
  return ProfileDao(ref.watch(bergamotDatabaseProvider));
});

/// حالت وزن
///
/// شامل لیست ورودی‌های وزن، آخرین وزن و BMI محاسبه‌شده
class WeightState {
  /// تمام ورودی‌های وزن
  final List<WeightEntry> entries;

  /// آخرین وزن ثبت‌شده (کیلوگرم)
  final double? latestWeight;

  const WeightState({
    this.entries = const [],
    this.latestWeight,
  });

  WeightState copyWith({
    List<WeightEntry>? entries,
    double? latestWeight,
  }) {
    return WeightState(
      entries: entries ?? this.entries,
      latestWeight: latestWeight ?? this.latestWeight,
    );
  }
}

/// Notifier وزن
///
/// تمام ورودی‌های وزن را واچ می‌کند و BMI محاسبه می‌کند.
class WeightNotifier extends AsyncNotifier<WeightState> {
  StreamSubscription? _weightSubscription;

  @override
  Future<WeightState> build() async {
    _weightSubscription?.cancel();

    final weightDao = ref.watch(weightDaoProvider);

    // واچ استریم ورودی‌ها — ذخیره subscription برای cancel در dispose
    final stream = weightDao.watchAllWeights();
    _weightSubscription = stream.listen((entries) {
      final latest = entries.isNotEmpty ? entries.last.weightKg : null;
      state = AsyncData(
        WeightState(entries: entries, latestWeight: latest),
      );
    });

    // Cancel subscription when provider is disposed
    ref.onDispose(() {
      _weightSubscription?.cancel();
      _weightSubscription = null;
    });

    // مقدار اولیه — استفاده از همان stream به جای .first مجزا
    final entries = await stream.first;
    final latest = entries.isNotEmpty ? entries.last.weightKg : null;

    return WeightState(
      entries: entries,
      latestWeight: latest,
    );
  }

  /// افزودن وزن جدید
  Future<void> addWeight({required double weightKg, String? note}) async {
    final dao = ref.read(weightDaoProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;

    final entry = WeightEntriesCompanion(
      date: Value(startOfDay),
      weightKg: Value(weightKg),
      note: Value(note),
      createdAt: Value(now.millisecondsSinceEpoch),
    );

    await dao.addWeight(entry);
    ref.invalidateSelf();
  }

  /// حذف ورودی وزن
  Future<void> deleteWeight(int id) async {
    final dao = ref.read(weightDaoProvider);
    await dao.deleteWeight(id);
    ref.invalidateSelf();
  }
}

/// Provider اصلی وزن
final weightProvider = AsyncNotifierProvider<WeightNotifier, WeightState>(
  WeightNotifier.new,
);

/// دسته‌بندی BMI
String bmiCategory(double bmi) {
  if (bmi < 18.5) return 'کمبود وزن';
  if (bmi < 25) return 'طبیعی';
  if (bmi < 30) return 'اضافه وزن';
  return 'چاقی';
}

/// رنگ دسته‌بندی BMI
Color bmiCategoryColor(double bmi) {
  if (bmi < 18.5) return const Color(0xFF3B82F6); // آبی
  if (bmi < 25) return const Color(0xFF10B981); // سبز
  if (bmi < 30) return const Color(0xFFF59E0B); // نارنجی
  return const Color(0xFFEF4444); // قرمز
}
