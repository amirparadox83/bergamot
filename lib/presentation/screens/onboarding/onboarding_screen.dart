import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/database_provider.dart';
import '../../../data/database/profile_dao.dart';
import '../../../data/database/bergamot_database.dart';
import '../../../presentation/theme/app_colors.dart';
import '../../../presentation/theme/app_spacing.dart';
import 'onboarding_provider.dart';
import '../../providers/first_launch_provider.dart';

/// صفحه آنبوردینگ ۵ مرحله‌ای
///
/// شامل: هدف، اطلاعات بدنی، سطح فعالیت، ترجیحات غذایی، خلاصه
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  /// لیست اهداف
  static const List<Map<String, String>> _goals = [
    {'icon': '🔥', 'title': 'لاغری', 'desc': 'کاهش چربی و رسیدن به وزن ایده‌آل'},
    {'icon': '💪', 'title': 'عضله‌سازی', 'desc': 'افزایش حجم عضلات و قدرت'},
    {'icon': '⚖️', 'title': 'حفظ وزن', 'desc': 'حفظ وزن فعلی و سلامتی'},
    {'icon': '🌿', 'title': 'سبک زندگی سالم', 'desc': 'بهبود کلی کیفیت زندگی'},
  ];

  /// لیست سطوح فعالیت
  static const List<Map<String, String>> _activityLevels = [
    {'icon': '🪑', 'title': 'کم‌تحرک', 'desc': 'فعالیت بدنی بسیار کم'},
    {'icon': '🚶', 'title': 'سبک', 'desc': 'پیاده‌روی سبک (۱-۲ بار در هفته)'},
    {'icon': '🏃', 'title': 'متوسط', 'desc': 'ورزش منظم (۳-۵ بار در هفته)'},
    {'icon': '🏋️', 'title': 'فعال', 'desc': 'تمرینات سنگین (۶-۷ بار در هفته)'},
    {'icon': '⚡', 'title': 'بسیار فعال', 'desc': 'ورزشکار حرفه‌ای یا شغل فیزیکی'},
  ];

  /// محدودیت‌های غذایی
  static const List<String> _restrictions = [
    'گیاهی (Vegan)',
    'گیاهی-لبنی (Vegetarian)',
    'بدون گلوتن',
    'بدون لبنیات',
    'بدون آجیل',
    'بدون شکر',
  ];

  /// محدودیت‌های غذایی انتخاب‌شده
  final Set<int> _selectedRestrictions = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? BergamotDarkColors.background
            : BergamotLightColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // نوار پیشرفت
              _buildProgressBar(state.currentStep, colorScheme),
              const SizedBox(height: BergamotSpacing.s8),

              // دکمه رد شدن
              if (state.currentStep < 4)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BergamotSpacing.s24,
                    ),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'رد شدن',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface
                              .withAlpha((0.5 * 255).round()),
                        ),
                      ),
                    ),
                  ),
                ),

              // محتوای مرحله
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    // همگام‌سازی با state
                  },
                  children: [
                    _buildGoalStep(colorScheme),
                    _buildBodyInfoStep(colorScheme),
                    _buildActivityStep(colorScheme),
                    _buildFoodPreferencesStep(colorScheme),
                    _buildSummaryStep(colorScheme),
                  ],
                ),
              ),

              // دکمه‌های پایین
              _buildBottomButtons(state, colorScheme),
              const SizedBox(height: BergamotSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }

  /// نوار پیشرفت مراحل
  Widget _buildProgressBar(int step, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s24,
        vertical: BergamotSpacing.s16,
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= step;
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: index > 0 ? BergamotSpacing.s8 : 0,
              ),
              child: AnimatedContainer(
                duration: BergamotSpacing.medium,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// مرحله ۱: انتخاب هدف
  Widget _buildGoalStep(ColorScheme colorScheme) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BergamotSpacing.s16),
            Text(
              'هدف تو چیست؟',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'یک هدف اصلی انتخاب کن تا برنامه شخصی‌سازی‌شده دریافت کنی.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface
                    .withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),
            ...List.generate(_goals.length, (index) {
              final isSelected = state.selectedGoal == index;
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: BergamotSpacing.s12,
                ),
                child: _buildSelectionCard(
                  icon: _goals[index]['icon']!,
                  title: _goals[index]['title']!,
                  description: _goals[index]['desc']!,
                  isSelected: isSelected,
                  onTap: () => notifier.setGoal(index),
                  colorScheme: colorScheme,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// مرحله ۲: اطلاعات بدنی
  Widget _buildBodyInfoStep(ColorScheme colorScheme) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BergamotSpacing.s16),
            Text(
              'اطلاعات بدنی',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'برای محاسبه دقیق نیازهای بدنی تو، کمی اطلاعات لازمه.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface
                    .withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // جنسیت
            Text(
              'جنسیت',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Row(
              children: [
                Expanded(
                  child: _buildGenderCard(
                    icon: Icons.male,
                    label: 'مرد',
                    isSelected: state.gender == 0,
                    onTap: () => notifier.setGender(0),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Expanded(
                  child: _buildGenderCard(
                    icon: Icons.female,
                    label: 'زن',
                    isSelected: state.gender == 1,
                    onTap: () => notifier.setGender(1),
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // سن
            _buildTextField(
              label: 'سن',
              hint: 'مثلاً ۲۵',
              value: state.age,
              onChanged: notifier.setAge,
              colorScheme: colorScheme,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // قد
            _buildTextField(
              label: 'قد (سانتی‌متر)',
              hint: 'مثلاً ۱۷۵',
              value: state.height,
              onChanged: notifier.setHeight,
              colorScheme: colorScheme,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // وزن
            _buildTextField(
              label: 'وزن (کیلوگرم)',
              hint: 'مثلاً ۷۰',
              value: state.weight,
              onChanged: notifier.setWeight,
              colorScheme: colorScheme,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  /// مرحله ۳: سطح فعالیت
  Widget _buildActivityStep(ColorScheme colorScheme) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BergamotSpacing.s16),
            Text(
              'سطح فعالیت بدنی',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'چقدر فعال هستی؟ این به محاسبه کالری مورد نیازت کمک می‌کنه.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface
                    .withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),
            ...List.generate(_activityLevels.length, (index) {
              final isSelected = state.activityLevel == index;
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: BergamotSpacing.s12,
                ),
                child: _buildSelectionCard(
                  icon: _activityLevels[index]['icon']!,
                  title: _activityLevels[index]['title']!,
                  description: _activityLevels[index]['desc']!,
                  isSelected: isSelected,
                  onTap: () => notifier.setActivityLevel(index),
                  colorScheme: colorScheme,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// مرحله ۴: ترجیحات غذایی
  Widget _buildFoodPreferencesStep(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BergamotSpacing.s16),
            Text(
              'ترجیحات غذایی',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'اگر محدودیت غذایی داری انتخاب کن. این مرحله اختیاریه.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface
                    .withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),
            Wrap(
              spacing: BergamotSpacing.s8,
              runSpacing: BergamotSpacing.s8,
              children: List.generate(_restrictions.length, (index) {
                final isSelected = _selectedRestrictions.contains(index);
                return FilterChip(
                  label: Text(_restrictions[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedRestrictions.add(index);
                      } else {
                        _selectedRestrictions.remove(index);
                      }
                    });
                  },
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface
                            .withAlpha((0.7 * 255).round()),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// مرحله ۵: خلاصه و تأیید
  Widget _buildSummaryStep(ColorScheme colorScheme) {
    final state = ref.watch(onboardingProvider);

    final goalText = state.selectedGoal != null
        ? _goals[state.selectedGoal!]['title']
        : '—';
    final genderText = state.gender == 0
        ? 'مرد'
        : state.gender == 1
            ? 'زن'
            : '—';
    final activityText = state.activityLevel != null
        ? _activityLevels[state.activityLevel!]['title']
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: BergamotSpacing.s16),
            Text(
              'خلاصه پروفایل',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'اطلاعات تو ثبت شد. حالا آماده‌ای شروع کنی!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface
                    .withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s32),

            // Lifestyle Score preview
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _ScoreRingPainter(
                        score: 0,
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '۰',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontSize: 36,
                                  ),
                            ),
                            Text(
                              'امتیاز شروع',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withAlpha((0.5 * 255).round()),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: BergamotSpacing.s16),
                  Text(
                    'امتیاز سبک زندگی تو هر روز محاسبه می‌شه',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface
                          .withAlpha((0.6 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BergamotSpacing.s32),

            // خلاصه اطلاعات
            _buildSummaryRow('هدف', goalText!, colorScheme),
            const SizedBox(height: BergamotSpacing.s12),
            _buildSummaryRow('جنسیت', genderText, colorScheme),
            const SizedBox(height: BergamotSpacing.s12),
            _buildSummaryRow(
              'سن',
              state.age ?? '—',
              colorScheme,
            ),
            const SizedBox(height: BergamotSpacing.s12),
            _buildSummaryRow(
              'قد',
              state.height != null ? '${state.height} سانتی‌متر' : '—',
              colorScheme,
            ),
            const SizedBox(height: BergamotSpacing.s12),
            _buildSummaryRow(
              'وزن',
              state.weight != null ? '${state.weight} کیلوگرم' : '—',
              colorScheme,
            ),
            const SizedBox(height: BergamotSpacing.s12),
            _buildSummaryRow('سطح فعالیت', activityText!, colorScheme),
          ],
        ),
      ),
    );
  }

  /// دکمه‌های پایین صفحه
  Widget _buildBottomButtons(OnboardingState state, ColorScheme colorScheme) {
    final isLastStep = state.currentStep == 4;
    final isFirstStep = state.currentStep == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s24,
      ),
      child: Row(
        children: [
          // دکمه قبلی
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(onboardingProvider.notifier).prevStep();
                  _pageController.previousPage(
                    duration: BergamotSpacing.medium,
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('قبلی'),
              ),
            ),
          if (!isFirstStep)
            const SizedBox(width: BergamotSpacing.s12),

          // دکمه بعدی / شروع
          Expanded(
            child: ElevatedButton(
              onPressed: isLastStep
                  ? _completeOnboarding
                  : _goToNextStep,
              child: Text(isLastStep ? 'شروع کن!' : 'بعدی'),
            ),
          ),
        ],
      ),
    );
  }

  /// رفتن به مرحله بعد
  void _goToNextStep() {
    ref.read(onboardingProvider.notifier).nextStep();
    _pageController.nextPage(
      duration: BergamotSpacing.medium,
      curve: Curves.easeInOut,
    );
  }

  /// رد شدن از آنبوردینگ
  Future<void> _skipOnboarding() async {
    await setFirstLaunchCompleted();
    if (mounted) context.go('/');
  }

  /// تکمیل آنبوردینگ
  ///
  /// اطلاعات جمع‌آوری‌شده را در دیتابیس ذخیره می‌کند و پرووایدرهای
  /// وابسته را invalidate می‌کند تا بدون نیاز به ریستارت اپ،
  /// داده جدید در صفحه وزن و خانه نمایش داده شود.
  Future<void> _completeOnboarding() async {
    final state = ref.read(onboardingProvider);

    // تبدیل سن به تاریخ تولد تقریبی (epoch ms)
    final age = int.tryParse(state.age ?? '') ?? 25;
    final now = DateTime.now();
    final birthYear = now.year - age;
    final birthDate = DateTime(birthYear, now.month, now.day).millisecondsSinceEpoch;

    // تبدیل هدف آنبوردینگ به goalType دیتابیس
    // آنبوردینگ: ۰=لاغری، ۱=عضله‌سازی، ۲=حفظ وزن، ۳=سبک زندگی سالم
    // دیتابیس:   ۰=حفظ وزن، ۱=کاهش وزن، ۲=افزایش وزن
    final goalTypeMap = {0: 1, 1: 2, 2: 0, 3: 0};
    final goalType = goalTypeMap[state.selectedGoal] ?? 0;

    final heightCm = double.tryParse(state.height ?? '') ?? 170.0;
    final weightKg = double.tryParse(state.weight ?? '') ?? 70.0;
    final gender = state.gender ?? 0;
    final activityLevel = state.activityLevel ?? 2;

    final db = ref.read(bergamotDatabaseProvider);
    final profileDao = ProfileDao(db);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await profileDao.upsertProfile(UserProfilesCompanion(
      gender: Value(gender),
      birthDate: Value(birthDate),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      activityLevel: Value(activityLevel),
      goalType: Value(goalType),
      createdAt: Value(timestamp),
      updatedAt: Value(timestamp),
    ));

    await setFirstLaunchCompleted();

    if (mounted) context.go('/');
  }

  /// کارت انتخاب (هدف / سطح فعالیت)
  Widget _buildSelectionCard({
    required String icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BergamotSpacing.br16,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : BergamotLightColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: 0,
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BergamotSpacing.br16,
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: BergamotSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: BergamotSpacing.s4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface
                            .withAlpha((0.6 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// کارت جنسیت
  Widget _buildGenderCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BergamotSpacing.br16,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: 0,
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BergamotSpacing.br16,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: BergamotSpacing.s16,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface
                        .withAlpha((0.5 * 255).round()),
                size: 32,
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// فیلد متنی
  Widget _buildTextField({
    required String label,
    required String hint,
    required String? value,
    required ValueChanged<String> onChanged,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: BergamotSpacing.s8),
        TextFormField(
          initialValue: value ?? '',
          onChanged: onChanged,
          keyboardType: keyboardType,
          textAlign: TextAlign.end,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }

  /// ردیف خلاصه
  Widget _buildSummaryRow(
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s16,
        vertical: BergamotSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BergamotSpacing.br12,
        border: Border.all(
          color: colorScheme.surfaceContainerHighest,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface
                  .withAlpha((0.6 * 255).round()),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// نقاش حلقه امتیاز
///
/// یک دایره پیشرفت دایره‌ای برای نمایش امتیاز سبک زندگی
class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;
    final radius = (size.width - strokeWidth * 2) / 2;

    // پس‌زمینه حلقه
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // حلقه پیشرفت
    if (score > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * 3.14159265359 * (score / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159265359 / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
