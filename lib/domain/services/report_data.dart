// مدل داده‌های گزارش سلامت برگاموت

/// داده‌های گزارش سلامت
///
/// شامل تمام آمار و توصیه‌های لازم برای تولید گزارش PDF
class ReportData {
  /// عنوان دوره (مثلاً '۱۰/۳ تا ۱۶/۳')
  final String periodTitle;

  /// محدوده تاریخی فارسی
  final String dateRange;

  /// تاریخ شروع به میلی‌ثانیه
  final int startDate;

  /// تاریخ پایان به میلی‌ثانیه
  final int endDate;

  /// امتیاز کلی سبک زندگی (میانگین)
  final double overallScore;

  /// امتیاز هر دسته‌بندی
  final Map<String, double> categoryScores;

  /// آمار خواب
  final SleepStats? sleepStats;

  /// آمار تغذیه
  final NutritionStats? nutritionStats;

  /// آمار تمرین
  final WorkoutStats? workoutStats;

  /// آمار آب
  final HydrationStats? hydrationStats;

  /// تغییر وزن
  final WeightChange? weightChange;

  /// توصیه‌های فارسی از Rule Engine
  final List<String> recommendations;

  /// بزرگ‌ترین موفقیت هفته (نام متریک + درصد بهبود)
  final String? biggestWin;

  /// تمرکز هفته آینده (نام متریک + درصد هدف)
  final String? nextWeekFocus;

  const ReportData({
    required this.periodTitle,
    required this.dateRange,
    required this.startDate,
    required this.endDate,
    required this.overallScore,
    required this.categoryScores,
    this.sleepStats,
    this.nutritionStats,
    this.workoutStats,
    this.hydrationStats,
    this.weightChange,
    required this.recommendations,
    this.biggestWin,
    this.nextWeekFocus,
  });
}

/// آمار خواب
class SleepStats {
  /// میانگین مدت خواب به دقیقه
  final double avgDurationMinutes;

  /// میانگین کیفیت خواب (۱ تا ۵)
  final double avgQuality;

  /// بهترین شب (مدت به دقیقه)
  final int? bestDuration;

  /// بدترین شب (مدت به دقیقه)
  final int? worstDuration;

  const SleepStats({
    required this.avgDurationMinutes,
    required this.avgQuality,
    this.bestDuration,
    this.worstDuration,
  });

  /// تبدیل به نقشه
  Map<String, dynamic> toMap() => {
        'avgDurationMinutes': avgDurationMinutes,
        'avgQuality': avgQuality,
        'bestDuration': bestDuration,
        'worstDuration': worstDuration,
      };
}

/// آمار تغذیه
class NutritionStats {
  /// میانگین کالری دریافتی
  final double avgCalories;

  /// میانگین پروتئین به گرم
  final double avgProtein;

  /// میانگین چربی به گرم
  final double avgFat;

  /// میانگین کربوهیدرات به گرم
  final double avgCarb;

  /// تعداد روزهایی که کالری در محدوده هدف بوده
  final int daysOnTarget;

  const NutritionStats({
    required this.avgCalories,
    required this.avgProtein,
    required this.avgFat,
    required this.avgCarb,
    required this.daysOnTarget,
  });

  /// تبدیل به نقشه
  Map<String, dynamic> toMap() => {
        'avgCalories': avgCalories,
        'avgProtein': avgProtein,
        'avgFat': avgFat,
        'avgCarb': avgCarb,
        'daysOnTarget': daysOnTarget,
      };
}

/// آمار تمرین
class WorkoutStats {
  /// تعداد تمرینات
  final int count;

  /// مجموع حجم تمرین
  final double totalVolume;

  /// مجموع مدت تمرین به دقیقه
  final int totalDurationMinutes;

  const WorkoutStats({
    required this.count,
    required this.totalVolume,
    required this.totalDurationMinutes,
  });

  /// تبدیل به نقشه
  Map<String, dynamic> toMap() => {
        'count': count,
        'totalVolume': totalVolume,
        'totalDurationMinutes': totalDurationMinutes,
      };
}

/// آمار آب
class HydrationStats {
  /// میانگین آب مصرفی به میلی‌لیتر
  final double avgMl;

  /// تعداد روزهایی که به هدف آب رسیده
  final int daysOnTarget;

  const HydrationStats({
    required this.avgMl,
    required this.daysOnTarget,
  });

  /// تبدیل به نقشه
  Map<String, dynamic> toMap() => {
        'avgMl': avgMl,
        'daysOnTarget': daysOnTarget,
      };
}

/// تغییر وزن
class WeightChange {
  /// وزن شروع دوره
  final double startWeight;

  /// وزن پایان دوره
  final double endWeight;

  /// تغییر به کیلوگرم (مثبت = افزایش)
  final double diffKg;

  const WeightChange({
    required this.startWeight,
    required this.endWeight,
    required this.diffKg,
  });

  /// فرمت متنی تغییر وزن
  String formatDiff() {
    final absDiff = diffKg.abs().toStringAsFixed(1);
    if (diffKg > 0) return '+$absDiff کیلوگرم';
    if (diffKg < 0) return '-$absDiff کیلوگرم';
    return 'بدون تغییر';
  }
}
