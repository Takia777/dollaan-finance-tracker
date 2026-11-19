import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/painters.dart';
import '../ui/widgets.dart';
import 'achievements_screen.dart';

/// Animasi "Pack it!": barang masuk ke kotak → tutup menutup → pita & confetti.
class PackScreen extends StatefulWidget {
  final Goal goal;
  const PackScreen({super.key, required this.goal});

  @override
  State<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends State<PackScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  bool _saved = false;

  late final Animation<double> _drop = CurvedAnimation(parent: _c, curve: const Interval(0.1, 0.45, curve: Curves.easeInCubic));
  late final Animation<double> _lid = CurvedAnimation(parent: _c, curve: const Interval(0.5, 0.75, curve: Curves.easeOutBack));
  late final Animation<double> _party = CurvedAnimation(parent: _c, curve: const Interval(0.75, 1.0, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _c.forward();
    app.packGoal(widget.goal).then((_) {
      if (mounted) setState(() => _saved = true);
    }).catchError((Object e) {
      if (mounted) showSnack(context, friendlyError(e));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.unguTua,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final drop = _drop.value;
          final lid = _lid.value;
          final party = _party.value;
          final done = _c.isCompleted;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: ConfettiPainter(progress: party, seed: 11))),
              SafeArea(
                child: LayoutBuilder(builder: (context, c) {
                  final cx = c.maxWidth / 2;
                  const boxTop = 300.0;
                  final itemSize = 170 - 60 * drop;
                  final itemTop = 70 + (boxTop - 40 - 70) * drop;
                  // Tutup: dari miring terbuka (kiri) ke menutup rapat.
                  final lidAngle = 0.5 * (1 - lid);
                  final lidLeft = cx - 105 - 60 * (1 - lid);
                  final lidTop = boxTop - 42 - 20 * (1 - lid);
                  return Stack(
                    children: [
                      Positioned(
                        left: cx - 160,
                        top: boxTop - 140,
                        child: Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(color: AppColors.ungu.o(0.28), shape: BoxShape.circle),
                        ),
                      ),
                      // Barang (di belakang kotak)
                      Positioned(
                        left: cx - itemSize / 2,
                        top: itemTop,
                        child: Opacity(
                          opacity: lid > 0.6 ? (1 - (lid - 0.6) * 2.5).clamp(0.0, 1.0) : 1.0,
                          child: Container(
                            width: itemSize,
                            height: itemSize,
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(color: AppColors.kuning, shape: BoxShape.circle),
                            child: ClipOval(
                              child: GoalImage(url: widget.goal.imageUrl, size: itemSize - 10, radius: itemSize),
                            ),
                          ),
                        ),
                      ),
                      // Badan kotak
                      Positioned(
                        left: cx - 95,
                        top: boxTop,
                        child: Container(
                          width: 190,
                          height: 140,
                          decoration: BoxDecoration(color: AppColors.kuning, borderRadius: BorderRadius.circular(16)),
                          child: Stack(
                            children: [
                              Positioned(left: 81, top: 0, bottom: 0, child: Container(width: 28, color: AppColors.tosca)),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                child: Container(height: 18, color: AppColors.unguTua.o(0.12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Tutup kotak
                      Positioned(
                        left: lidLeft,
                        top: lidTop,
                        child: Transform.rotate(
                          angle: -lidAngle,
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 210,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.kuning,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.unguTua.o(0.15), width: 2),
                            ),
                            child: Center(child: Container(width: 28, color: AppColors.tosca)),
                          ),
                        ),
                      ),
                      // Pita
                      Positioned(
                        left: cx - 40,
                        top: boxTop - 74,
                        child: Opacity(
                          opacity: party,
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * party,
                            child: SizedBox(
                              width: 80,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(left: 2, child: _bowLoop(-0.26)),
                                  Positioned(right: 2, child: _bowLoop(0.26)),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.kuning,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.tosca, width: 3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Teks
                      Positioned(
                        left: 24,
                        right: 24,
                        top: boxTop + 170,
                        child: Column(
                          children: [
                            Text(
                              done ? 'Packed & ready!' : (drop < 1 ? 'Packing your goal' : 'Into the box...'),
                              textAlign: TextAlign.center,
                              style: ts(28, FontWeight.w800, AppColors.putih),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              done ? '${widget.goal.name} moved to your achievements' : widget.goal.name,
                              textAlign: TextAlign.center,
                              style: ts(14, FontWeight.w500, AppColors.putih.o(0.7)),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 24,
                        child: AnimatedOpacity(
                          opacity: done ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: PrimaryButton(
                            label: 'See my achievements',
                            loading: done && !_saved,
                            onTap: done
                                ? () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
                                    )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bowLoop(double angle) => Transform.rotate(
        angle: angle,
        child: Container(
          width: 38,
          height: 26,
          decoration: BoxDecoration(color: AppColors.tosca, borderRadius: BorderRadius.circular(13)),
        ),
      );
}
