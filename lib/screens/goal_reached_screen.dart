import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/painters.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'new_goal_screen.dart';
import 'pack_screen.dart';

class GoalReachedScreen extends StatelessWidget {
  final Goal goal;
  const GoalReachedScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(goal.createdAt).inDays + 1;
    return Scaffold(
      backgroundColor: AppColors.unguTua,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConfettiPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CircleBtn(
                      icon: Icons.close_rounded,
                      bg: AppColors.putih.o(0.12),
                      fg: AppColors.putih,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(color: AppColors.ungu.o(0.3), shape: BoxShape.circle),
                        ),
                        Container(
                          width: 200,
                          height: 200,
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.kuning, shape: BoxShape.circle),
                          child: ClipOval(child: GoalImage(url: goal.imageUrl, size: 184, radius: 92)),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 16,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.tosca,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.unguTua, width: 4),
                            ),
                            child: const Icon(Icons.emoji_events_rounded, color: AppColors.kuning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Goal reached!', style: ts(30, FontWeight.w800, AppColors.putih)),
                  const SizedBox(height: 8),
                  Text(
                    '${goal.name} is fully funded.\nTime to pack it up!',
                    textAlign: TextAlign.center,
                    style: ts(15, FontWeight.w500, AppColors.putih.o(0.75)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _stat(Icons.inventory_2_rounded, rupiah(app.goalSaved(goal.id)), 'saved in $days days'),
                      const SizedBox(width: 10),
                      _stat(Icons.local_fire_department_rounded, '${app.streakDays} days', 'saving streak'),
                    ],
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Pack it!',
                    icon: Icons.inventory_2_rounded,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => PackScreen(goal: goal)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.putih.o(0.4), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => const NewGoalScreen()),
                      ),
                      child: Text('Set next goal', style: ts(15, FontWeight.w700, AppColors.putih)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.putih.o(0.1), borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.kuning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(value,
                        overflow: TextOverflow.ellipsis, style: ts(15, FontWeight.w700, AppColors.putih)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(label, style: ts(11, FontWeight.w500, AppColors.putih.o(0.65))),
            ],
          ),
        ),
      );
}
