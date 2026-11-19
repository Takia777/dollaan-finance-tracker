import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Kartu wallet sesuai template Figma: Bank card, E-money, E-toll, Wallet.
class WalletCardView extends StatelessWidget {
  final String name;
  final WalletType type;
  final String colorKey;
  final String last4;
  final double balance;
  final String? logoUrl;
  final bool showLogoSlot;
  final double height;

  const WalletCardView({
    super.key,
    required this.name,
    required this.type,
    required this.colorKey,
    required this.last4,
    required this.balance,
    this.logoUrl,
    this.showLogoSlot = false,
    this.height = 190,
  });

  factory WalletCardView.of(Wallet w, double balance) => WalletCardView(
        name: w.name,
        type: w.type,
        colorKey: w.color,
        last4: w.last4,
        balance: balance,
        logoUrl: w.logoUrl,
      );

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.card(colorKey);
    final fg = AppColors.onCard(colorKey);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.unguTua.o(0.14), blurRadius: 18, offset: const Offset(0, -4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ..._decorations(bg),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(14, FontWeight.w600, fg.o(0.9))),
                    ),
                    if (type == WalletType.emoney || type == WalletType.etoll)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: fg.o(0.6)),
                        ),
                        child: Text(type == WalletType.emoney ? 'E-MONEY' : 'E-TOLL',
                            style: ts(10, FontWeight.w800, fg)),
                      )
                    else
                      Icon(Icons.contactless, color: fg, size: 20),
                  ],
                ),
                _middle(fg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(last4.isEmpty ? walletTypeLabel(type) : '••••  $last4',
                              style: ts(12, FontWeight.w500, fg.o(0.7))),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(rupiah(balance, decimals: true), style: ts(22, FontWeight.w700, fg)),
                          ),
                        ],
                      ),
                    ),
                    _logo(fg),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _decorations(Color bg) => switch (type) {
        WalletType.bank => [
            Positioned(
              right: -70,
              top: -70,
              child: _circle(220, colorKey == 'ungu' ? AppColors.unguTua.o(0.35) : AppColors.ungu.o(0.35)),
            ),
            Positioned(right: -30, bottom: -60, child: _circle(140, AppColors.tosca.o(0.45))),
          ],
        WalletType.emoney => [
            for (var i = 0; i < 5; i++)
              Positioned(
                left: -60,
                top: 60.0 + i * 34,
                child: Transform.rotate(
                  angle: -0.31,
                  child: Container(width: 520, height: 12, color: AppColors.unguTua.o(0.07)),
                ),
              ),
          ],
        WalletType.etoll => [
            Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 12, color: AppColors.kuning)),
            Positioned(left: 0, right: 0, bottom: 12, child: Container(height: 5, color: AppColors.putih.o(0.5))),
          ],
        WalletType.wallet => [Positioned(right: -50, top: -40, child: _circle(240, AppColors.putih.o(0.12)))],
      };

  Widget _circle(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _middle(Color fg) => switch (type) {
        WalletType.bank => Container(
            width: 42,
            height: 32,
            decoration: BoxDecoration(color: AppColors.kuning, borderRadius: BorderRadius.circular(7)),
            child: CustomPaint(painter: _ChipLines()),
          ),
        WalletType.emoney || WalletType.etoll => Icon(Icons.contactless, color: fg, size: 28),
        WalletType.wallet => Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fg, width: 1.5)),
            child: Icon(Icons.savings_rounded, color: fg, size: 18),
          ),
      };

  Widget _logo(Color fg) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return SizedBox(
        width: 60,
        height: 38,
        child: Image.network(logoUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()),
      );
    }
    if (!showLogoSlot) return const SizedBox();
    return Container(
      width: 60,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.o(0.55), width: 1.2),
      ),
      child: Text('LOGO', style: ts(9, FontWeight.w800, fg.o(0.7))),
    );
  }
}

class _ChipLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.unguTua.o(0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
