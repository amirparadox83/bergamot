import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/database/profile_dao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../weight/weight_provider.dart';
import '../home/home_provider.dart';

/// صفحه پروفایل کاربر
///
/// نمایش و ویرایش اطلاعات فیزیکی و هدف کاربر.
/// از Design System موجود پروژه (رنگ‌ها/فاصله‌گذاری) استفاده می‌کند.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  /// کنترلرهای ویرایش
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _ageController;

  /// مقادیر انتخابی
  int? _gender;
  int? _activityLevel;
  int? _goalType;

  /// وضعیت ویرایش
  bool _isEditing = false;
  bool _isSaving = false;

  /// لیست اهداف
  static const List<Map<String, String>> _goals = [
    {'title': 'حفظ وزن', 'desc': 'حفظ وزن فعلی و سلامتی'},
    {'title': 'کاهش وزن', 'desc': 'کاهش چربی و رسیدن به وزن ایده‌آل'},
    {'title': 'افزایش وزن', 'desc': 'افزایش حجم عضلات و قدرت'},
  ];

  /// لیست سطوح فعالیت
  static const List<Map<String, String>> _activityLevels = [
    {'title': 'کم‌تحرک', 'desc': 'فعالیت بدنی بسیار کم'},
    {'title': 'سبک', 'desc': 'پیاده‌روی سبک (۱-۲ بار در هفته)'},
    {'title': 'متوسط', 'desc': 'ورزش منظم (۳-۵ بار در هفته)'},
    {'title': 'فعال', 'desc': 'تمرینات سنگین (۶-۷ بار در هفته)'},
    {'title': 'بسیار فعال', 'desc': 'ورزشکار حرفه‌ای یا شغل فیزیکی'},
  ];

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// بارگذاری پروفایل از دیتابیس
  Future<void> _loadProfile() async {
    final db = ref.read(bergamotDatabaseProvider);
    final profileDao = ProfileDao(db);
    final profile = await profileDao.getProfile();

    if (profile != null && mounted) {
      setState(() {
        _profile = profile;
        _gender = profile.gender;
        _activityLevel = profile.activityLevel;
        _goalType = profile.goalType;
        _heightController.text = profile.heightCm.toStringAsFixed(1);
        _weightController.text = profile.weightKg.toStringAsFixed(1);
        final age = _calculateAge(profile.birthDate);
        _ageController.text = age.toString();
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// محاسبه سن از تاریخ تولد epoch
  int _calculateAge(int birthDateEpoch) {
    final birth = DateTime.fromMillisecondsSinceEpoch(birthDateEpoch);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  /// تبدیل سن به تاریخ تولد تقریبی (epoch ms)
  int _ageToBirthDate(int age) {
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day)
        .millisecondsSinceEpoch;
  }

  /// ذخیره پروفایل
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final db = ref.read(bergamotDatabaseProvider);
      final profileDao = ProfileDao(db);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final age = int.tryParse(_ageController.text) ?? 25;
      final heightCm = double.tryParse(_heightController.text) ?? 170.0;
      final weightKg = double.tryParse(_weightController.text) ?? 70.0;

      await profileDao.upsertProfile(UserProfilesCompanion(
        gender: Value(_gender ?? 0),
        birthDate: Value(_ageToBirthDate(age)),
        heightCm: Value(heightCm),
        weightKg: Value(weightKg),
        activityLevel: Value(_activityLevel ?? 2),
        goalType: Value(_goalType ?? 0),
        createdAt: Value(
            _profile?.createdAt ?? timestamp),
        updatedAt: Value(timestamp),
      ));

      // invalidate providerهای وابسته تا داده جدید نمایش داده شود
      ref.invalidate(weightProvider);
      ref.invalidate(homeProvider);

      await _loadProfile();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پروفایل ذخیره شد')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('پروفایل'),
          actions: [
            if (!_isEditing && _profile != null)
              TextButton(
                onPressed: () => setState(() => _isEditing = true),
                child: const Text('ویرایش'),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null && !_isEditing
                ? _buildEmptyProfile(context, colors)
                : _buildProfileContent(context, colors),
      ),
    );
  }

  /// حالت خالی — پروفایل تکمیل نشده
  Widget _buildEmptyProfile(BuildContext context, BergamotColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: colors.textSecondary,
            ),
            const SizedBox(height: BergamotSpacing.s24),
            Text(
              'پروفایل شما تکمیل نشده',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.text,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'برای دریافت محاسبات دقیق BMI و کالری، پروفایل خود را تکمیل کنید',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BergamotSpacing.s24),
            ElevatedButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('تکمیل پروفایل'),
            ),
          ],
        ),
      ),
    );
  }

  /// محتوای اصلی پروفایل
  Widget _buildProfileContent(BuildContext context, BergamotColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BergamotSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── کارت خلاصه ──
          _buildSummaryCard(context, colors),
          const SizedBox(height: BergamotSpacing.s24),

          // ── اطلاعات بدنی ──
          _buildSectionTitle(context, 'اطلاعات بدنی'),
          const SizedBox(height: BergamotSpacing.s12),
          _buildBodyInfoSection(context, colors),
          const SizedBox(height: BergamotSpacing.s24),

          // ── هدف ──
          _buildSectionTitle(context, 'هدف'),
          const SizedBox(height: BergamotSpacing.s12),
          _buildGoalSection(context, colors),
          const SizedBox(height: BergamotSpacing.s24),

          // ── سطح فعالیت ──
          _buildSectionTitle(context, 'سطح فعالیت'),
          const SizedBox(height: BergamotSpacing.s12),
          _buildActivitySection(context, colors),
          const SizedBox(height: BergamotSpacing.s32),

          // ── دکمه ذخیره (فقط در حالت ویرایش) ──
          if (_isEditing) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ذخیره تغییرات'),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() => _isEditing = false);
                        _loadProfile();
                      },
                child: const Text('انصراف'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// کارت خلاصه پروفایل
  Widget _buildSummaryCard(BuildContext context, BergamotColors colors) {
    final genderText = _gender == 0 ? 'مرد' : _gender == 1 ? 'زن' : 'سایر';
    final age = _ageController.text.isEmpty
        ? '-'
        : _ageController.text;
    final goalText = _goalType != null && _goalType! < _goals.length
        ? _goals[_goalType!]['title']!
        : '-';
    final activityText = _activityLevel != null &&
            _activityLevel! < _activityLevels.length
        ? _activityLevels[_activityLevel!]['title']!
        : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BergamotSpacing.s24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BergamotSpacing.br16,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BergamotSpacing.br20,
                ),
                child: Icon(
                  Icons.person,
                  color: colors.primary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: BergamotSpacing.s16),
          _SummaryRow(label: 'جنسیت', value: genderText, colors: colors),
          const SizedBox(height: BergamotSpacing.s8),
          _SummaryRow(label: 'سن', value: '$age سال', colors: colors),
          const SizedBox(height: BergamotSpacing.s8),
          _SummaryRow(
            label: 'قد',
            value: '${_heightController.text} سانتی‌متر',
            colors: colors,
          ),
          const SizedBox(height: BergamotSpacing.s8),
          _SummaryRow(
            label: 'وزن پایه',
            value: '${_weightController.text} کیلوگرم',
            colors: colors,
          ),
          const SizedBox(height: BergamotSpacing.s8),
          _SummaryRow(label: 'هدف', value: goalText, colors: colors),
          const SizedBox(height: BergamotSpacing.s8),
          _SummaryRow(
              label: 'سطح فعالیت', value: activityText, colors: colors),
        ],
      ),
    );
  }

  /// بخش اطلاعات بدنی (سن، قد، وزن، جنسیت)
  Widget _buildBodyInfoSection(BuildContext context, BergamotColors colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          children: [
            // جنسیت
            if (_isEditing) ...[
              Text(
                'جنسیت',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption(
                      icon: Icons.male,
                      label: 'مرد',
                      isSelected: _gender == 0,
                      onTap: () => setState(() => _gender = 0),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s12),
                  Expanded(
                    child: _buildGenderOption(
                      icon: Icons.female,
                      label: 'زن',
                      isSelected: _gender == 1,
                      onTap: () => setState(() => _gender = 1),
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BergamotSpacing.s16),
            ],

            // سن
            _buildEditableField(
              label: 'سن',
              controller: _ageController,
              hint: 'مثلاً ۲۵',
              suffix: 'سال',
              keyboardType: TextInputType.number,
              enabled: _isEditing,
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // قد
            _buildEditableField(
              label: 'قد',
              controller: _heightController,
              hint: 'مثلاً ۱۷۵',
              suffix: 'سانتی‌متر',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enabled: _isEditing,
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // وزن پایه
            _buildEditableField(
              label: 'وزن پایه',
              controller: _weightController,
              hint: 'مثلاً ۷۵',
              suffix: 'کیلوگرم',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enabled: _isEditing,
            ),
          ],
        ),
      ),
    );
  }

  /// بخش هدف
  Widget _buildGoalSection(BuildContext context, BergamotColors colors) {
    if (!_isEditing) {
      // حالت نمایش
      return Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha((0.12 * 255).round()),
              borderRadius: BergamotSpacing.br12,
            ),
            child: const Icon(Icons.flag_outlined,
                color: Color(0xFFF59E0B), size: 22),
          ),
          title: const Text('هدف'),
          subtitle: Text(_goalType != null && _goalType! < _goals.length
              ? _goals[_goalType!]['title']!
              : '-'),
        ),
      );
    }

    // حالت ویرایش
    return Column(
      children: _goals.asMap().entries.map((entry) {
        final i = entry.key;
        final goal = entry.value;
        final isSelected = _goalType == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
          child: _buildSelectionCard(
            icon: i == 0
                ? '⚖️'
                : i == 1
                    ? '🔥'
                    : '💪',
            title: goal['title']!,
            description: goal['desc']!,
            isSelected: isSelected,
            onTap: () => setState(() => _goalType = i),
            colors: colors,
          ),
        );
      }).toList(),
    );
  }

  /// بخش سطح فعالیت
  Widget _buildActivitySection(BuildContext context, BergamotColors colors) {
    if (!_isEditing) {
      return Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha((0.12 * 255).round()),
              borderRadius: BergamotSpacing.br12,
            ),
            child: const Icon(Icons.directions_run,
                color: Color(0xFF10B981), size: 22),
          ),
          title: const Text('سطح فعالیت'),
          subtitle: Text(_activityLevel != null &&
                  _activityLevel! < _activityLevels.length
              ? _activityLevels[_activityLevel!]['title']!
              : '-'),
        ),
      );
    }

    return Column(
      children: _activityLevels.asMap().entries.map((entry) {
        final i = entry.key;
        final level = entry.value;
        final isSelected = _activityLevel == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
          child: _buildSelectionCard(
            icon: i == 0
                ? '🪑'
                : i == 1
                    ? '🚶'
                    : i == 2
                        ? '🏃'
                        : i == 3
                            ? '🏋️'
                            : '⚡',
            title: level['title']!,
            description: level['desc']!,
            isSelected: isSelected,
            onTap: () => setState(() => _activityLevel = i),
            colors: colors,
          ),
        );
      }).toList(),
    );
  }

  /// عنوان بخش
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  /// فیلد قابل ویرایش
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required TextInputType keyboardType,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: BergamotSpacing.s8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
          ),
        ),
      ],
    );
  }

  /// کارت انتخاب جنسیت
  Widget _buildGenderOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required BergamotColors colors,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BergamotSpacing.br16,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: 0,
      color: isSelected ? colorScheme.primaryContainer : colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BergamotSpacing.br16,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BergamotSpacing.s16),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? colorScheme.primary : colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// کارت انتخاب (هدف / سطح فعالیت)
  Widget _buildSelectionCard({
    required String icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required BergamotColors colors,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BergamotSpacing.br16,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: 0,
      color: isSelected ? colorScheme.primaryContainer : colors.surface,
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : colors.text,
                          ),
                    ),
                    const SizedBox(height: BergamotSpacing.s4),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: colorScheme.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// ردیف خلاصه
///
/// نمایش یک جفت کلید:مقدار در کارت خلاصه پروفایل
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final BergamotColors colors;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
