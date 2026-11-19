import 'dart:math';

import 'package:flutter/material.dart';

import '../categories.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/painters.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'chat_screen.dart';

enum StatPeriod { week, month, year }

enum TxnFilter { today, week, month, all }

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  StatPeriod _period = StatPeriod.month;
  TxnFilter _filter = TxnFilter.today;
  bool _donut = true;

  (DateTime, DateTime) _range(StatPeriod p) {
    final now = DateTime.now();
    final tomorrow = dayOnly(now).add(const Duration(days: 1));
    return switch (p) {
      StatPeriod.week => (dayOnly(now).subtract(const Duration(days: 6)), tomorrow),
      StatPeriod.month => (monthStart(now), DateTime(now.year, now.month + 1, 1)),
      StatPeriod.year => (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1)),
    };
  }

  List<Txn> _filtered() {
    final now = DateTime.now();
    final today = dayOnly(now);
    return switch (_filter) {
      TxnFilter.today => app.txnsBetween(today, today.add(const Duration(days: 1))),
      TxnFilter.week => app.txnsBetween(today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1))),
      TxnFilter.month => app.txnsBetween(monthStart(now), DateTime(now.year, now.month + 1, 1)),
      TxnFilter.all => app.txns,
    };
  }

  String _filterLabel(TxnFilter f) => switch (f) {
        TxnFilter.today => 'Today',
        TxnFilter.week => 'This week',
        TxnFilter.month => 'This month',
        TxnFilter.all => 'All',
      };

  String _periodLabel(StatPeriod p) => switch (p) {
        StatPeriod.week => 'Week',
        StatPeriod.month => 'Month',
        StatPeriod.year => 'Year',
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final (start, end) = _range(_period);
        final byCat = app.expenseByCategory(start, end);
        final counts = app.expenseCountByCategory(start, end);
        final income = app.incomeBetween(start, end);
        final expense = app.expenseBetween(start, end);
        final txns = _filtered();
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              Row(
                children: [
                  const SizedBox(width: 44),
                  Expanded(child: Text('Statistic', textAlign: TextAlign.center, style: ts(18, FontWeight.w700))),
                  PopupMenuButton<String>(
                    color: AppColors.putih,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    onSelected: (v) {
                      if (v == 'graph') setState(() => _donut = !_donut);
                      if (v == 'summary') {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const ChatScreen(initialMessage: 'rekap bulan ini'),
                        ));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'graph',
                        child: Row(children: [
                          Icon(_donut ? Icons.bar_chart_rounded : Icons.pie_chart_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(_donut ? 'Change to bar chart' : 'Change to donut chart'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'summary',
                        child: Row(children: [
                          Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.tosca),
                          SizedBox(width: 10),
                          Text('Summarize with chatbot'),
                        ]),
                      ),
                    ],
                    child: const CircleBtn(icon: Icons.more_vert_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Period segmented control
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.putih, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    for (final p in StatPeriod.values)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _period = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _period == p ? AppColors.unguTua : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _periodLabel(p),
                              style: ts(13, _period == p ? FontWeight.w700 : FontWeight.w600,
                                  _period == p ? AppColors.putih : AppColors.muted),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_donut) _donutChart(byCat, income, expense) else _barList(byCat, expense),
              const SizedBox(height: 16),
              if (byCat.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in byCat)
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                        decoration: BoxDecoration(color: AppColors.putih, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: categoryByName(e.key).color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('${e.key} ${(e.value / max(expense, 1) * 100).round()}%',
                                style: ts(11, FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              _topSpending(byCat, counts),
              const SizedBox(height: 20),
              // Transactions
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Transaction', style: ts(16, FontWeight.w700))),
                        PopupMenuButton<TxnFilter>(
                          color: AppColors.putih,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          onSelected: (f) => setState(() => _filter = f),
                          itemBuilder: (_) => [
                            for (final f in TxnFilter.values)
                              CheckedPopupMenuItem(value: f, checked: f == _filter, child: Text(_filterLabel(f))),
                          ],
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                            decoration: BoxDecoration(color: AppColors.sakura, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_filterLabel(_filter), style: ts(12, FontWeight.w600)),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (txns.isEmpty)
                      const EmptyState(icon: Icons.receipt_long_rounded, text: 'No transactions in this period.')
                    else
                      for (final t in txns.take(50))
                        Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: AppColors.danger.o(0.12),
                            child: const Icon(Icons.delete_rounded, color: AppColors.danger),
                          ),
                          confirmDismiss: (_) => showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete transaction?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                              ],
                            ),
                          ),
                          onDismissed: (_) => app.deleteTxn(t.id),
                          child: TxnTile(t),
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _donutChart(List<MapEntry<String, double>> byCat, double income, double expense) {
    final net = income - expense;
    return Center(
      child: SizedBox(
        width: 236,
        height: 236,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(236, 236),
              painter: DonutPainter([for (final e in byCat) Slice(e.value, categoryByName(e.key).color)]),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Balance this ${_periodLabel(_period).toLowerCase()}',
                    style: ts(11, FontWeight.w500, AppColors.muted)),
                const SizedBox(height: 2),
                Text(rupiah(net), style: ts(20, FontWeight.w800)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.tosca.o(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text('Income ${compactRp(income)}', style: ts(10, FontWeight.w700, AppColors.tosca)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _barList(List<MapEntry<String, double>> byCat, double expense) {
    if (byCat.isEmpty) {
      return const EmptyState(icon: Icons.bar_chart_rounded, text: 'No expenses in this period.');
    }
    final top = byCat.first.value;
    return AppCard(
      child: Column(
        children: [
          for (final e in byCat)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(e.key, style: ts(12, FontWeight.w600))),
                  Expanded(child: ProgressBar(value: e.value / top, color: categoryByName(e.key).color, height: 12)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: Text(compactRp(e.value), textAlign: TextAlign.right, style: ts(12, FontWeight.w700)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text('Total expense ${rupiah(expense)}', style: ts(12, FontWeight.w600, AppColors.muted)),
        ],
      ),
    );
  }

  Widget _topSpending(List<MapEntry<String, double>> byCat, Map<String, int> counts) {
    final top = byCat.take(4).toList();
    final maxV = top.isEmpty ? 1.0 : top.first.value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Spending', style: ts(15, FontWeight.w700)),
          const SizedBox(height: 14),
          if (top.isEmpty)
            const EmptyState(icon: Icons.shopping_bag_rounded, text: 'Record an expense to see your top spending.')
          else
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final e in top)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(compactRp(e.value), style: ts(11, FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          width: 52,
                          height: max(36.0, 90 * e.value / maxV),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: categoryByName(e.key).color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            categoryByName(e.key).icon,
                            size: 16,
                            color: categoryByName(e.key).color == AppColors.kuning ? AppColors.unguTua : AppColors.putih,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(e.key, style: ts(11, FontWeight.w600)),
                        Text('${counts[e.key] ?? 0} trx', style: ts(10, FontWeight.w500, AppColors.muted)),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
