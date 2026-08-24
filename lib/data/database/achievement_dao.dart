import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// دیتابیس دستاوردها
/// مدیریت ثبت، باز کردن قفل و دریافت لیست دستاوردها
class AchievementDao {
  final BergamotDatabase db;
  AchievementDao(this.db);

  /// دریافت تمام دستاوردها (باز شده‌ها اول)
  Future<List<Achievement>> getAllAchievements() {
    return (db.select(db.achievements)
          ..orderBy([
            (t) => OrderingTerm.asc(t.unlockedAt),
          ]))
        .get();
  }

  /// باز کردن قفل یک دستاورد
  Future<void> unlockAchievement(String key) async {
    final existing = await (db.select(db.achievements)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (existing == null) return;
    if (existing.unlockedAt != null) return; // قبلاً باز شده

    final now = DateTime.now().millisecondsSinceEpoch;
    await (db.update(db.achievements)..where((t) => t.key.equals(key)))
        .write(AchievementsCompanion(
      unlockedAt: Value(now),
    ));
  }

  /// بررسی و باز کردن قفل برای مجموعه‌ای از شروط
  Future<void> checkAndUnlock(Map<String, bool> checks) async {
    for (final entry in checks.entries) {
      if (entry.value) {
        await unlockAchievement(entry.key);
      }
    }
  }

  /// ثبت تمام دستاوردهای پیش‌فرض (اگر وجود ندارند)
  Future<void> seedAchievements() async {
    await db.transaction(() async {
      final defaults = [
        const _AchievementDef(
          key: 'first_workout',
          titleFa: 'اولین تمرین',
          descriptionFa: 'اولین تمرین خود را انجام دادی',
          icon: 'fitness_center',
        ),
        const _AchievementDef(
          key: 'first_sleep',
          titleFa: 'اولین خواب ثبت‌شده',
          descriptionFa: 'اولین ورودی خواب را ثبت کردی',
          icon: 'bedtime',
        ),
        const _AchievementDef(
          key: 'first_weight',
          titleFa: 'اولین وزن',
          descriptionFa: 'اولین وزن خود را ثبت کردی',
          icon: 'monitor_weight',
        ),
        const _AchievementDef(
          key: 'first_meal',
          titleFa: 'اولین وعده غذایی',
          descriptionFa: 'اولین وعده غذایی خود را ثبت کردی',
          icon: 'restaurant',
        ),
        const _AchievementDef(
          key: 'water_7day_streak',
          titleFa: '۷ روز آب کافی',
          descriptionFa: '۷ روز متوالی به هدف آب رسیدی',
          icon: 'water_drop',
        ),
        const _AchievementDef(
          key: 'sleep_7day_streak',
          titleFa: '۷ شب خواب کافی',
          descriptionFa: '۷ شب متوالی حداقل ۷ ساعت خواب داشتی',
          icon: 'nightlight',
        ),
        const _AchievementDef(
          key: 'total_100l_water',
          titleFa: '۱۰۰ لیتر آب',
          descriptionFa: 'مجموع ۱۰۰ لیتر آب نوشیدی',
          icon: 'opacity',
        ),
      ];

      for (final def in defaults) {
        final existing = await (db.select(db.achievements)
              ..where((t) => t.key.equals(def.key)))
            .getSingleOrNull();
        if (existing == null) {
          await db.into(db.achievements).insert(AchievementsCompanion(
            key: Value(def.key),
            titleFa: Value(def.titleFa),
            descriptionFa: Value(def.descriptionFa),
            icon: Value(def.icon),
            unlockedAt: const Value(null),
          ));
        }
      }
    });
  }
}

class _AchievementDef {
  final String key;
  final String titleFa;
  final String descriptionFa;
  final String icon;
  const _AchievementDef({
    required this.key,
    required this.titleFa,
    required this.descriptionFa,
    required this.icon,
  });
}
