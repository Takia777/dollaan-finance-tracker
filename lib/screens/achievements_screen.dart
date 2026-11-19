import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _badges = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final packed = app.packedGoals.reversed.toList();
            final totalPacked = packed.fold<double>(0, (s, g) => s + app.goalSaved(g.id));
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const TopBar(title: 'Achievements'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.unguTua, borderRadius: BorderRadius.circular(24)),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(color: AppColors.kuning, shape: BoxShape.circle),
                              child: const Icon(Icons.emoji_events_rounded, color: AppColors.unguTua),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${packed.length} goals completed',
                                      style: ts(17, FontWeight.w800, AppColors.putih)),
                                  Text('${rupiah(totalPacked)} saved in total',
                                      style: ts(12, FontWeight.w500, AppColors.putih.o(0.7))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.putih, borderRadius: BorderRadius.circular(22)),
                        child: Row(
                          children: [
                            _tab('Completed goals', !_badges, () => setState(() => _badges = false)),
                            _tab('Badges', _badges, () => setState(() => _badges = true)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_badges && packed.isEmpty)
                        const EmptyState(icon: Icons.inventory_2_rounded, text: 'Pack your first goal to see it here.'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: _badges ? _badgeTiles() : [for (final g in packed) _goalTile(g)],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tab(String label, bool on, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.unguTua : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(label, style: ts(13, on ? FontWeight.w700 : FontWeight.w600, on ? AppColors.putih : AppColors.muted)),
          ),
        ),
      );

  Widget _goalTile(Goal g) => _tile(
        leading: ClipOval(child: GoalImage(url: g.imageUrl, size: 52, radius: 26)),
        title: g.name,
        subtitle: '${rupiah(app.goalSaved(g.id))} · ${g.packedAt == null ? '' : dayMonth(g.packedAt!)}',
        done: true,
      );

  List<Widget> _badgeTiles() {
    final saved = app.totalSaved;
    final streak = app.streakDays;
    final early = app.packedGoals.any((g) =>
        g.targetDate != null && g.packedAt != null && g.packedAt!.isBefore(g.targetDate!));
    final badges = [
      ('First goal', 'Pack your first goal', Icons.emoji_events_rounded, app.packedGoals.isNotEmpty),
      ('Saved Rp 1 juta', '${rupiah(saved)} saved so far', Icons.star_rounded, saved >= 1000000),
      ('7-day streak', '$streak / 7 days', Icons.local_fire_department_rounded, streak >= 7),
      ('30-day streak', '$streak / 30 days', Icons.whatshot_rounded, streak >= 30),
      ('Early bird', 'Finish a goal before its date', Icons.wb_sunny_rounded, early),
      ('Big dreamer', 'Have 3 active goals', Icons.cloud_rounded, app.activeGoals.length >= 3),
    ];
    return [
      for (final b in badges)
        _tile(
          leading: IconBubble(icon: b.$4 ? b.$3 : Icons.lock_rounded, color: b.$4 ? AppColors.tosca : AppColors.muted, size: 52),
          title: b.$1,
          subtitle: b.$2,
          done: b.$4,
        ),
    ];
  }

  Widget _tile({required Widget leading, required String title, required String subtitle, required bool done}) {
    return Opacity(
      opacity: done ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.putih, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const Spacer(),
                if (done)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(color: AppColors.tosca, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 14, color: AppColors.putih),
                  ),
              ],
            ),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14, FontWeight.w700)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, FontWeight.w500, AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
