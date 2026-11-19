import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class Slice {
  final double value;
  final Color color;
  const Slice(this.value, this.color);
}

/// Donut chart untuk statistik pengeluaran per kategori.
class DonutPainter extends CustomPainter {
  final List<Slice> slices;
  DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.15;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (total <= 0) {
      paint.color = AppColors.muted.o(0.15);
      canvas.drawArc(rect, 0, 2 * pi, false, paint);
      return;
    }
    final gap = slices.length > 1 ? 0.05 : 0.0;
    var start = -pi / 2;
    for (final s in slices) {
      final sweep = s.value / total * 2 * pi;
      paint.color = s.color;
      canvas.drawArc(rect, start + gap / 2, max(0.0, sweep - gap), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) => true;
}

/// Confetti statis yang tersebar acak (seed tetap supaya tidak berubah tiap build).
class ConfettiPainter extends CustomPainter {
  final double progress; // 0..1 untuk animasi jatuh
  final int seed;
  ConfettiPainter({this.progress = 1, this.seed = 7});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    const colors = [AppColors.kuning, AppColors.ungu, AppColors.tosca, AppColors.sakura, AppColors.putih];
    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * size.width;
      final y0 = rnd.nextDouble() * size.height * 0.55;
      final y = -40 + (y0 + 40) * progress;
      final w = 6 + rnd.nextDouble() * 6;
      final h = w * (rnd.nextBool() ? 2.2 : 1);
      final angle = rnd.nextDouble() * pi;
      final paint = Paint()..color = colors[i % colors.length].o(0.9 * progress.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
