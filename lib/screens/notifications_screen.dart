import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'goal_detail_screen.dart';

class AppNotification {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? goalId;
  const AppNotification(this.icon, this.color, this.title, this.subtitle, {this.goalId});
}

/// Notifikasi dibuat dari data yang ada (tanpa server push).
List<AppNotification> buildNotifications() {
  final list = <AppNotification>[];
  final today = dayOnly(DateTime.now());

  for (final g in app.activeGoals) {
    final p = app.goalProgress(g);
    if (g.isReached) {
      list.add(AppNotification(Icons.emoji_events_rounded, AppColors.kuning, '${g.name} is ready to pack!',
          'Open the goal and tap "Pack it"', goalId: g.id));
    } else if (p >= 0.5) {
      list.add(AppNotification(Icons.track_changes_rounded, AppColors.tosca,
          '${g.name} is ${(p * 100).round()}% funded', 'Only ${rupiah(g.target - app.goalSaved(g.id))} to go',
          goalId: g.id));
    }
  }

  final savedToday = app.savingByDay().containsKey(today);
  final streak = app.streakDays;
  if ((app.profile?.dailyReminder ?? true) && !savedToday && app.activeGoals.isNotEmpty) {
    list.add(AppNotification(
      Icons.local_fire_department_rounded,
      AppColors.kuning,
      streak > 0 ? "Don't break your $streak-day streak!" : 'Time to save today',
      'Add any amount to one of your goals',
    ));
  }

  final recentTopUp = app.txns.where((t) => t.kind == TxnKind.topup).take(1);
  for (final t in recentTopUp) {
    if (dayOnly(t.occurredAt) == today) {
      list.add(AppNotification(Icons.download_rounded, AppColors.ungu, 'Top up recorded',
          '+${rupiah(t.amount)} to ${app.walletById(t.walletId)?.name ?? 'wallet'}'));
    }
  }

  final budget = app.profile?.monthlyBudget ?? 0;
  if (budget > 0) {
    final now = DateTime.now();
    final spent = app.expenseBetween(monthStart(now), DateTime(now.year, now.month + 1, 1));
    if (spent >= budget * 0.8) {
      list.add(AppNotification(Icons.warning_amber_rounded, AppColors.danger,
          'You have used ${(spent / budget * 100).round()}% of your budget',
          '${rupiah(spent)} of ${rupiah(budget)} this month'));
    }
  }
  return list;
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final items = buildNotifications();
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const TopBar(title: 'Notifications'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: items.isEmpty
                      ? const EmptyState(icon: Icons.notifications_none_rounded, text: "You're all caught up!")
                      : AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Column(
                            children: [
                              for (final n in items)
                                InkWell(
                                  onTap: n.goalId == null
                                      ? null
                                      : () => Navigator.of(context).push(MaterialPageRoute<void>(
                                            builder: (_) => GoalDetailScreen(goalId: n.goalId!),
                                          )),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        IconBubble(icon: n.icon, color: n.color),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(n.title, style: ts(14, FontWeight.w600)),
                                              Text(n.subtitle, style: ts(11, FontWeight.w500, AppColors.muted)),
                                            ],
                                          ),
                                        ),
                                        if (n.goalId != null)
                                          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
