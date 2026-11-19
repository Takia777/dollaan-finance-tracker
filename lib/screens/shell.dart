import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'statistic_screen.dart';

/// Kerangka utama dengan bottom nav: Home, Goals, (AI), Statistic, Settings.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: app.tab,
      builder: (context, index, _) => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: index,
          children: const [HomeScreen(), GoalsScreen(), StatisticScreen(), SettingsScreen()],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _BottomNav(index: index),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  const _BottomNav({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.putih,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: AppColors.unguTua.o(0.12), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item(Icons.home_rounded, 'Home', 0),
          _item(Icons.track_changes_rounded, 'Goals', 1),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChatScreen())),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.tosca,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kuning, width: 3),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.putih),
            ),
          ),
          _item(Icons.pie_chart_rounded, 'Statistic', 2),
          _item(Icons.settings_rounded, 'Settings', 3),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, int i) {
    final selected = index == i;
    return GestureDetector(
      onTap: () => app.tab.value = i,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.unguTua : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.putih : AppColors.muted),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(label, style: ts(13, FontWeight.w700, AppColors.putih)),
            ],
          ],
        ),
      ),
    );
  }
}
