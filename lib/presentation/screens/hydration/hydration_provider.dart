import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/hydration_dao.dart';
import '../../../data/database/database_provider.dart';

/// پرووایدر DAO هیدراتاسیون
final hydrationDaoProvider = Provider<HydrationDao>((ref) {
  return HydrationDao(ref.watch(bergamotDatabaseProvider));
});

/// حالت هیدراتاسیون امروز
///
/// شامل لیست ورودی‌های آب امروز و مجموع مصرفی
class HydrationState {
  /// مجموع آب مصرفی امروز (میلی‌لیتر)
  final int totalMl;

  /// هدف روزانه (میلی‌لیتر) — پیش‌فرض ۲۵۰۰
  final int targetMl;

  const HydrationState({
    this.totalMl = 0,
    this.targetMl = 2500,
  });

  /// درصد پیشرفت (۰ تا ۱۰۰+)
  double get percentage => (totalMl / targetMl) * 100;

  /// آیا به هدف رسیده؟
  bool get isGoalReached => totalMl >= targetMl;

  /// تعداد لیوان‌های پر (هر لیوان ~۳۱۲ میلی‌لیتر از ۲۵۰۰)
  int get filledGlasses => (totalMl / 312).floor().clamp(0, 8);

  HydrationState copyWith({
    int? totalMl,
    int? targetMl,
  }) {
    return HydrationState(
      totalMl: totalMl ?? this.totalMl,
      targetMl: targetMl ?? this.targetMl,
    );
  }
}

/// Notifier هیدراتاسیون
///
/// داده‌های آب امروز را از دیتابیس خوانده و به‌روز می‌کند.
class HydrationNotifier extends FamilyAsyncNotifier<HydrationState, void> {
  StreamSubscription? _waterSubscription;

  @override
  Future<HydrationState> build(void arg) async {
    // Cancel any previous subscription when provider is rebuilt
    _waterSubscription?.cancel();

    final dao = ref.watch(hydrationDaoProvider);

    // گوش دادن به استریم ورودی‌های امروز
    final stream = dao.watchTodayWater();
    _waterSubscription = stream.listen((entries) {
      final total = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      state = AsyncData(state.valueOrNull?.copyWith(totalMl: total) ??
          HydrationState(totalMl: total));
    });

    // Cancel subscription when provider is disposed
    ref.onDispose(() {
      _waterSubscription?.cancel();
      _waterSubscription = null;
    });

    // مقدار اولیه
    final total = await dao.getTodayTotalMl();
    return HydrationState(totalMl: total);
  }

  /// افزودن آب
  Future<void> addWater(int amountMl) async {
    final dao = ref.read(hydrationDaoProvider);
    await dao.addWater(amountMl);
    ref.invalidateSelf();
  }

  /// حذف ورودی آب
  Future<void> deleteWater(int id) async {
    final dao = ref.read(hydrationDaoProvider);
    await dao.deleteWaterEntry(id);
    ref.invalidateSelf();
  }
}

/// Provider اصلی هیدراتاسیون
final hydrationProvider =
    AsyncNotifierProvider.family<HydrationNotifier, HydrationState, void>(
  HydrationNotifier.new,
);
