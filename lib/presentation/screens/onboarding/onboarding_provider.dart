import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالت آنبوردینگ
///
/// شامل تمام داده‌های جمع‌آوری‌شده در فرآیند آنبوردینگ است.
class OnboardingState {
  /// مرحله فعلی (۰ تا ۴)
  final int currentStep;

  /// هدف انتخاب‌شده (۰: لاغری، ۱: عضله‌سازی، ۲: حفظ وزن، ۳: سبک زندگی سالم)
  final int? selectedGoal;

  /// جنسیت (۰: مرد، ۱: زن)
  final int? gender;

  /// سن
  final String? age;

  /// قد (سانتی‌متر)
  final String? height;

  /// وزن (کیلوگرم)
  final String? weight;

  /// سطح فعالیت (۰: کم‌تحرک، ۱: سبک، ۲: متوسط، ۳: فعال، ۴: بسیار فعال)
  final int? activityLevel;

  const OnboardingState({
    this.currentStep = 0,
    this.selectedGoal,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
  });

  OnboardingState copyWith({
    int? currentStep,
    int? selectedGoal,
    int? gender,
    String? age,
    String? height,
    String? weight,
    int? activityLevel,
    bool clearGender = false,
    bool clearAge = false,
    bool clearHeight = false,
    bool clearWeight = false,
    bool clearActivityLevel = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      gender: clearGender ? null : (gender ?? this.gender),
      age: clearAge ? null : (age ?? this.age),
      height: clearHeight ? null : (height ?? this.height),
      weight: clearWeight ? null : (weight ?? this.weight),
      activityLevel: clearActivityLevel ? null : (activityLevel ?? this.activityLevel),
    );
  }
}

/// Notifier مدیریت حالت آنبوردینگ
class OnboardingNotifier extends Notifier<OnboardingState> {
  /// تعداد کل مراحل
  static const int totalSteps = 5;

  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  /// رفتن به مرحله بعد
  void nextStep() {
    if (state.currentStep < totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// برگشت به مرحله قبل
  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// تنظیم هدف
  void setGoal(int goal) {
    state = state.copyWith(selectedGoal: goal);
  }

  /// تنظیم جنسیت
  void setGender(int gender) {
    state = state.copyWith(gender: gender);
  }

  /// تنظیم سن
  void setAge(String age) {
    state = state.copyWith(age: age);
  }

  /// تنظیم قد
  void setHeight(String height) {
    state = state.copyWith(height: height);
  }

  /// تنظیم وزن
  void setWeight(String weight) {
    state = state.copyWith(weight: weight);
  }

  /// تنظیم سطح فعالیت
  void setActivityLevel(int level) {
    state = state.copyWith(activityLevel: level);
  }
}

/// Provider حالت آنبوردینگ
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
