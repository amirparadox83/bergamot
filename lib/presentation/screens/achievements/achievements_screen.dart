import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/database/achievement_dao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// صفحه دستاوردها
///
/// نمایش شبکه‌ای از دستاوردهای باز شده و قفل‌شده
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final db = ref.read(bergamotDatabaseProvider);
    final dao = AchievementDao(db);
    await dao.seedAchievements();
    final list = await dao.getAllAchievements();
    if (mounted) {
      setState(() {
        _achievements = list;
        _isLoading = false;
      });
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
          title: const Text('دستاوردها'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _achievements.isEmpty
                ? _buildEmptyState(colors, context)
                : GridView.builder(
                    padding: const EdgeInsets.all(BergamotSpacing.s16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: BergamotSpacing.s12,
                      mainAxisSpacing: BergamotSpacing.s12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      final a = _achievements[index];
                      final isUnlocked = a.unlockedAt != null;
                      return _AchievementCard(
                        achievement: a,
                        isUnlocked: isUnlocked,
                        colors: colors,
                      );
                    },
                  ),
      ),
    );
  }

  /// Empty state — وقتی هیچ دستاوردی موجود نیست
  Widget _buildEmptyState(BergamotColors colors, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: colors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: BergamotSpacing.s12),
          Text(
            'هنوز دستاوردی کسب نکرده‌اید',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: BergamotSpacing.s4),
          Text(
            'با ثبت مداوم داده‌ها، دستاوردهای جدید باز می‌شوند',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final BergamotColors colors;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.colors,
  });

  IconData _getIconData() {
    // تبدیل نام آیکون رشته‌ای به IconData
    switch (achievement.icon) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'bedtime':
        return Icons.bedtime;
      case 'monitor_weight':
        return Icons.monitor_weight;
      case 'restaurant':
        return Icons.restaurant;
      case 'water_drop':
        return Icons.water_drop;
      case 'nightlight':
        return Icons.nightlight;
      case 'opacity':
        return Icons.opacity;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatUnlockDate(int? ms) {
    if (ms == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isUnlocked ? colors.surface : colors.surface.withAlpha(180),
      shape: RoundedRectangleBorder(
        borderRadius: BergamotSpacing.br12,
        side: isUnlocked
            ? BorderSide(color: colors.primary.withAlpha(80), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // آیکون
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? colors.primary.withAlpha(25)
                    : colors.textSecondary.withAlpha(20),
                borderRadius: BergamotSpacing.br12,
              ),
              child: Icon(
                isUnlocked ? _getIconData() : Icons.lock_outline,
                color: isUnlocked ? colors.primary : colors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
            // عنوان
            Text(
              achievement.titleFa,
              style: TextStyle(
                color: isUnlocked ? colors.text : colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: BergamotSpacing.s4),
            // توضیحات (فقط برای باز شده)
            if (isUnlocked) ...[
              Text(
                achievement.descriptionFa,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: BergamotSpacing.s4),
              Text(
                _formatUnlockDate(achievement.unlockedAt),
                style: TextStyle(
                  color: colors.textSecondary.withAlpha(150),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
