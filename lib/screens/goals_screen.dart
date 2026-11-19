import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'achievements_screen.dart';
import 'goal_detail_screen.dart';
import 'new_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final active = app.activeGoals;
        final packed = app.packedGoals;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Row(
                children: [
                  Expanded(child: Text('My Goals', style: ts(24, FontWeight.w800))),
                  CircleBtn(
                    icon: Icons.add_rounded,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const NewGoalScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.unguTua, borderRadius: BorderRadius.circular(24)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -80,
                      top: -80,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(color: AppColors.ungu.o(0.35), shape: BoxShape.circle),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total saved', style: ts(12, FontWeight.w500, AppColors.putih.o(0.7))),
                                  const SizedBox(height: 4),
                                  Text(rupiah(app.totalSaved), style: ts(26, FontWeight.w800, AppColors.putih)),
                                ],
                              ),
                            ),
                            StreakChip(days: app.streakDays),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${active.length} active goals  ·  ${packed.length} completed',
                          style: ts(12, FontWeight.w500, AppColors.putih.o(0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('Active goals'),
              const SizedBox(height: 12),
              if (active.isEmpty)
                const EmptyState(icon: Icons.track_changes_rounded, text: 'No goal yet. Create one and start saving!')
              else
                for (final g in active) ...[
                  GoalCard(goal: g),
                  const SizedBox(height: 12),
                ],
              GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const NewGoalScreen())),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.unguTua.o(0.35), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded),
                      const SizedBox(width: 8),
                      Text('New goal', style: ts(14, FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                'Past achievements',
                action: 'See all',
                onAction: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen())),
              ),
              const SizedBox(height: 12),
              if (packed.isEmpty)
                const EmptyState(icon: Icons.emoji_events_rounded, text: 'Finish a goal to earn your first trophy.')
              else
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: packed.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _AchievementMini(goal: packed[packed.length - 1 - i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class StreakChip extends StatelessWidget {
  final int days;
  final bool light;
  const StreakChip({super.key, required this.days, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: light ? AppColors.kuning.o(0.35) : AppColors.kuning,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.unguTua),
          const SizedBox(width: 4),
          Text(days == 1 ? '1 day' : '$days days', style: ts(12, FontWeight.w700)),
        ],
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final Goal goal;
  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final saved = app.goalSaved(goal.id);
    final progress = app.goalProgress(goal);
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => GoalDetailScreen(goalId: goal.id))),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        radius: 22,
        child: Row(
          children: [
            GoalImage(url: goal.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(goal.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, FontWeight.w700)),
                      ),
                      Text(
                        goal.isReached ? 'Ready!' : '${(progress * 100).round()}%',
                        style: ts(13, FontWeight.w800, AppColors.tosca),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(value: progress),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: rupiah(saved), style: ts(12, FontWeight.w600)),
                    TextSpan(text: ' / ${rupiah(goal.target)}', style: ts(12, FontWeight.w600, AppColors.muted)),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementMini extends StatelessWidget {
  final Goal goal;
  const _AchievementMini({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.putih, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          ClipOval(child: GoalImage(url: goal.imageUrl, size: 44, radius: 22)),
          const SizedBox(height: 8),
          Text(goal.name,
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: ts(12, FontWeight.w700)),
          const SizedBox(height: 2),
          Text(goal.packedAt == null ? '' : monthYear(goal.packedAt!).substring(0, 3) + ' ${goal.packedAt!.year}',
              style: ts(10, FontWeight.w500, AppColors.muted)),
        ],
      ),
    );
  }
}
