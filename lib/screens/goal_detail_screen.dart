import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'goal_reached_screen.dart';
import 'goals_screen.dart' show StreakChip;

class GoalDetailScreen extends StatefulWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late String _goalId = widget.goalId;

  Future<void> _addMoney(Goal goal) async {
    final result = await showModalBottomSheet<(Wallet, double)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sakura,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AddMoneySheet(goal: goal),
    );
    if (result == null) return;
    try {
      final reached = await app.depositToGoal(goal, result.$1.id, result.$2);
      if (!mounted) return;
      if (reached) {
        final updated = app.goalById(goal.id) ?? goal;
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GoalReachedScreen(goal: updated)));
      } else {
        showSnack(context, 'Saved ${rupiah(result.$2)} to ${goal.name} 🎉');
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  Future<void> _delete(Goal goal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: const Text('Saved money will return to the original wallets.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await app.deleteGoal(goal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final goal = app.goalById(_goalId);
          if (goal == null) return const Center(child: Text('Goal not found'));
          final saved = app.goalSaved(goal.id);
          final progress = app.goalProgress(goal);
          final remaining = (goal.target - saved).clamp(0, double.infinity);
          final others = app.activeGoals;
          final deposits = app.goalDeposits(goal.id);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              children: [
                TopBar(
                  title: 'My Goal',
                  trailing: PopupMenuButton<String>(
                    color: AppColors.putih,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    onSelected: (v) {
                      if (v == 'delete') _delete(goal);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_rounded, size: 18, color: AppColors.danger),
                          SizedBox(width: 10),
                          Text('Delete goal', style: TextStyle(color: AppColors.danger)),
                        ]),
                      ),
                    ],
                    child: const CircleBtn(icon: Icons.more_vert_rounded),
                  ),
                ),
                // Goal switcher
                if (others.length > 1)
                  SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        for (final g in others)
                          GestureDetector(
                            onTap: () => setState(() => _goalId = g.id),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: g.id == goal.id ? AppColors.tosca : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipOval(child: GoalImage(url: g.imageUrl, size: 50, radius: 25)),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    radius: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoalImage(url: goal.imageUrl, size: double.infinity, height: 160, radius: 20),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(goal.name, style: ts(20, FontWeight.w800))),
                                  if (goal.targetDate != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.sakura,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('Target · ${shortDate(goal.targetDate!)}',
                                          style: ts(11, FontWeight.w600)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text.rich(TextSpan(children: [
                                TextSpan(text: rupiah(saved), style: ts(22, FontWeight.w800)),
                                TextSpan(
                                  text: ' / ${rupiah(goal.target)}',
                                  style: ts(14, FontWeight.w600, AppColors.muted),
                                ),
                              ])),
                              const SizedBox(height: 10),
                              ProgressBar(value: progress, height: 10),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('${(progress * 100).round()}% reached',
                                      style: ts(12, FontWeight.w700, AppColors.tosca)),
                                  const Spacer(),
                                  Text('${rupiah(remaining)} to go',
                                      style: ts(12, FontWeight.w600, AppColors.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (goal.isReached)
                          PrimaryButton(
                            label: 'Goal reached — Pack it!',
                            icon: Icons.inventory_2_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => GoalReachedScreen(goal: goal)),
                            ),
                          )
                        else
                          PrimaryButton(label: 'Add money', icon: Icons.add_rounded, onTap: () => _addMoney(goal)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Saving activity', style: ts(15, FontWeight.w700))),
                            StreakChip(days: app.streakDays, light: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SavingHeatmap(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History', style: ts(16, FontWeight.w700)),
                        if (deposits.isEmpty)
                          const EmptyState(icon: Icons.savings_rounded, text: 'No deposits yet.')
                        else
                          for (final t in deposits) TxnTile(t),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Heatmap aktivitas menabung ala GitHub: 17 minggu terakhir, hari ini = kuning.
class SavingHeatmap extends StatelessWidget {
  const SavingHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final byDay = app.savingByDay();
    final today = dayOnly(DateTime.now());
    const weeks = 17;
    // Mulai dari Senin 16 minggu yang lalu.
    final start = today.subtract(Duration(days: today.weekday - 1 + (weeks - 1) * 7));
    final values = byDay.values.toList()..sort();
    double level(double v) {
      if (v <= 0 || values.isEmpty) return 0;
      final rank = values.indexWhere((x) => x >= v) / values.length;
      return rank < 0.33 ? 0.3 : (rank < 0.66 ? 0.6 : 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, c) {
          final cell = ((c.maxWidth - (weeks - 1) * 4) / weeks).clamp(8.0, 16.0);
          return Row(
            children: [
              for (var w = 0; w < weeks; w++)
                Padding(
                  padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : 4),
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Builder(builder: (_) {
                          final day = start.add(Duration(days: w * 7 + d));
                          final isToday = day == today;
                          final future = day.isAfter(today);
                          final lv = level(byDay[day] ?? 0);
                          Color color;
                          if (future) {
                            color = Colors.transparent;
                          } else if (isToday && lv > 0) {
                            color = AppColors.kuning;
                          } else if (lv == 0) {
                            color = AppColors.muted.o(0.14);
                          } else {
                            color = AppColors.tosca.o(lv);
                          }
                          return Container(
                            width: cell,
                            height: cell,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                          );
                        }),
                    ],
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('Less', style: ts(10, FontWeight.w500, AppColors.muted)),
            const SizedBox(width: 4),
            for (final c in [AppColors.muted.o(0.14), AppColors.tosca.o(0.3), AppColors.tosca.o(0.6), AppColors.tosca])
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
              ),
            const SizedBox(width: 2),
            Text('More', style: ts(10, FontWeight.w500, AppColors.muted)),
          ],
        ),
      ],
    );
  }
}

class _AddMoneySheet extends StatefulWidget {
  final Goal goal;
  const _AddMoneySheet({required this.goal});

  @override
  State<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<_AddMoneySheet> {
  final _amount = TextEditingController();
  Wallet? _wallet = app.mainWallet;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.target - app.goalSaved(widget.goal.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add money to ${widget.goal.name}', style: ts(17, FontWeight.w800)),
          const SizedBox(height: 14),
          WalletSelector(
            label: 'From wallet',
            wallet: _wallet,
            onTap: () async {
              final w = await pickWallet(context);
              if (w != null) setState(() => _wallet = w);
            },
          ),
          const SizedBox(height: 12),
          AmountInput(
            label: 'Amount',
            controller: _amount,
            quick: [10000.0, 25000.0, 50000.0, if (remaining > 0) remaining],
            helper: 'Remaining ${rupiah(remaining < 0 ? 0 : remaining)}',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save to goal',
            icon: Icons.savings_rounded,
            onTap: () {
              final a = parseAmountInput(_amount.text);
              if (_wallet == null || a == null || a <= 0) {
                showSnack(context, 'Pilih wallet dan isi nominal.');
                return;
              }
              Navigator.pop(context, (_wallet!, a));
            },
          ),
        ],
      ),
    );
  }
}
