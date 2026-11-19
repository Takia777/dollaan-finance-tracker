import 'package:flutter/material.dart';

import '../categories.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Pesan error Supabase yang lebih ramah.
String friendlyError(Object e) {
  final text = e.toString();
  if (text.contains('Invalid login credentials')) return 'Email atau password salah.';
  if (text.contains('User already registered')) return 'Email ini sudah terdaftar. Silakan login.';
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'Tidak ada koneksi internet.';
  }
  return text.replaceAll('Exception: ', '');
}

class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final double size;
  final bool badge;
  const CircleBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.bg = AppColors.putih,
    this.fg = AppColors.unguTua,
    this.size = 44,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: fg, size: size * 0.46),
              if (badge)
                Positioned(
                  top: size * 0.22,
                  right: size * 0.24,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.kuning,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.putih, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showBack;
  final IconData backIcon;
  const TopBar({
    super.key,
    required this.title,
    this.trailing,
    this.showBack = true,
    this.backIcon = Icons.chevron_left_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          showBack
              ? CircleBtn(icon: backIcon, onTap: () => Navigator.of(context).maybePop())
              : const SizedBox(width: 44),
          Expanded(
            child: Text(title, textAlign: TextAlign.center, style: ts(18, FontWeight.w700)),
          ),
          trailing ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool dark;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.dark = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.unguTua : AppColors.kuning;
    final fg = dark ? AppColors.putih : AppColors.unguTua;
    final disabled = onTap == null || loading;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: disabled ? null : onTap,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: ts(15, FontWeight.w700, fg)),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, color: fg, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.putih,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double size;
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: ts(size, FontWeight.w700))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: ts(12, FontWeight.w700, AppColors.tosca)),
          ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: ts(12, FontWeight.w600, AppColors.muted)),
      );
}

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          onChanged: onChanged,
          maxLength: maxLength,
          style: ts(15, FontWeight.w600),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: ts(15, FontWeight.w500, AppColors.muted.o(0.8)),
            prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted, size: 20),
            filled: true,
            fillColor: AppColors.putih,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.ungu, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class ChoiceChipX extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const ChoiceChipX({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.putih : AppColors.unguTua;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.unguTua : AppColors.putih,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis, style: ts(12, FontWeight.w700, fg)),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const ProgressBar({super.key, required this.value, this.color = AppColors.tosca, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.muted.o(0.18),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBubble({super.key, required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.o(0.16), borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: color == AppColors.kuning ? const Color(0xFFB8860B) : color, size: size * 0.46),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.muted.o(0.6)),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: ts(13, FontWeight.w500, AppColors.muted)),
        ],
      ),
    );
  }
}

/// Satu baris transaksi (dipakai di Statistic & detail).
class TxnTile extends StatelessWidget {
  final Txn txn;
  const TxnTile(this.txn, {super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = app.walletById(txn.walletId);
    late final IconData icon;
    late final Color color;
    late final String title;
    late final String amountText;
    late final Color amountColor;
    switch (txn.kind) {
      case TxnKind.topup:
        {
          final c = categoryByName(txn.category, income: true);
          icon = c.icon;
          color = c.color;
          title = txn.note ?? c.name;
          amountText = rupiah(txn.amount, sign: true);
          amountColor = AppColors.tosca;
        }
      case TxnKind.expense:
        {
          final c = categoryByName(txn.category);
          icon = c.icon;
          color = c.color;
          title = txn.note ?? c.name;
          amountText = '-${rupiah(txn.amount)}';
          amountColor = AppColors.unguTua;
        }
      case TxnKind.transfer:
        icon = Icons.swap_horiz_rounded;
        color = AppColors.ungu;
        title = 'To ${app.walletById(txn.toWalletId)?.name ?? 'wallet'}';
        amountText = rupiah(txn.amount);
        amountColor = AppColors.muted;
      case TxnKind.goal:
        icon = Icons.savings_rounded;
        color = AppColors.tosca;
        title = 'Saved to ${txn.note ?? 'goal'}';
        amountText = '-${rupiah(txn.amount)}';
        amountColor = AppColors.unguTua;
    }
    final sub = [
      if (txn.kind == TxnKind.expense || txn.kind == TxnKind.topup) txn.category ?? '',
      wallet?.name ?? '',
      friendlyTime(txn.occurredAt),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14, FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, FontWeight.w500, AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amountText, style: ts(14, FontWeight.w700, amountColor)),
        ],
      ),
    );
  }
}

/// Teks saldo besar dengan "Rp" kecil dan desimal transparan.
class BalanceText extends StatelessWidget {
  final double value;
  final double size;
  final Color color;
  const BalanceText(this.value, {super.key, this.size = 34, this.color = AppColors.unguTua});

  @override
  Widget build(BuildContext context) {
    final full = rupiah(value.abs(), decimals: true); // "Rp 8.776.000,55"
    final comma = full.lastIndexOf(',');
    final main = full.substring(3, comma); // "8.776.000"
    final dec = full.substring(comma); // ",55"
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: value < 0 ? '-Rp ' : 'Rp ', style: ts(size * 0.58, FontWeight.w800, color)),
        TextSpan(text: main, style: ts(size, FontWeight.w800, color)),
        TextSpan(text: dec, style: ts(size, FontWeight.w800, color.o(0.3))),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Gambar goal dari URL, atau ikon kalau belum ada gambar.
class GoalImage extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  final double? height;
  const GoalImage({super.key, required this.url, this.size = 84, this.radius = 16, this.height});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(color: AppColors.ungu.o(0.15), borderRadius: BorderRadius.circular(radius)),
      child: Icon(Icons.image_rounded, color: AppColors.ungu, size: (height ?? size) * 0.35),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url!,
        width: size,
        height: height ?? size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// Bottom sheet pilih wallet sederhana.
Future<Wallet?> pickWallet(BuildContext context, {String title = 'Choose wallet', String? excludeId}) {
  final options = app.wallets.where((w) => w.id != excludeId).toList();
  return showModalBottomSheet<Wallet>(
    context: context,
    backgroundColor: AppColors.putih,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ts(16, FontWeight.w700)),
            const SizedBox(height: 8),
            for (final w in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 30,
                  decoration: BoxDecoration(color: AppColors.card(w.color), borderRadius: BorderRadius.circular(8)),
                ),
                title: Text(w.name, style: ts(14, FontWeight.w700)),
                subtitle: Text(
                  '${w.last4.isEmpty ? walletTypeLabel(w.type) : '•••• ${w.last4}'} · ${rupiah(app.balanceOf(w.id))}',
                  style: ts(11, FontWeight.w500, AppColors.muted),
                ),
                onTap: () => Navigator.pop(ctx, w),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Baris pemilih wallet (dipakai di Top Up, Expense, Transfer).
class WalletSelector extends StatelessWidget {
  final String label;
  final Wallet? wallet;
  final VoidCallback onTap;
  const WalletSelector({super.key, required this.label, required this.wallet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = wallet;
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        radius: 20,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 36,
              decoration: BoxDecoration(
                color: w == null ? AppColors.muted.o(0.2) : AppColors.card(w.color),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(5),
              child: Icon(Icons.contactless, size: 12, color: w == null ? AppColors.muted : AppColors.onCard(w.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ts(11, FontWeight.w600, AppColors.muted)),
                  Text(w?.name ?? 'Choose wallet', style: ts(15, FontWeight.w700)),
                  if (w != null)
                    Text(
                      '${w.last4.isEmpty ? walletTypeLabel(w.type) : '•••• ${w.last4}'} · ${rupiah(app.balanceOf(w.id))}',
                      style: ts(11, FontWeight.w500, AppColors.muted),
                    ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Kartu input nominal besar + tombol cepat.
class AmountInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<double> quick;
  final String? helper;
  final VoidCallback? onChanged;
  const AmountInput({
    super.key,
    required this.label,
    required this.controller,
    this.quick = const [],
    this.helper,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = parseAmountInput(controller.text);
    return AppCard(
      child: Column(
        children: [
          Text(label, style: ts(12, FontWeight.w600, AppColors.muted)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Rp ', style: ts(20, FontWeight.w800)),
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => onChanged?.call(),
                  style: ts(32, FontWeight.w800),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: ts(32, FontWeight.w800, AppColors.muted.o(0.4)),
                  ),
                ),
              ),
            ],
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: ts(11, FontWeight.w500, AppColors.muted)),
          ],
          if (quick.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < quick.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.text = quick[i].round().toString();
                        onChanged?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: current == quick[i] ? AppColors.unguTua : AppColors.sakura,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          compactRp(quick[i]),
                          style: ts(12, FontWeight.w700, current == quick[i] ? AppColors.putih : AppColors.unguTua),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
