import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/wallet_card.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'add_wallet_screen.dart';
import 'more_sheet.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'transaction_screen.dart';
import 'transfer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final p = app.profile;
        final growth = app.monthGrowthPct;
        final net = app.thisMonthNet;
        return SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: app.loadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _push(context, const ProfileScreen()),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.ungu,
                        child: Text(p?.initial ?? 'D', style: ts(18, FontWeight.w700, AppColors.putih)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back', style: ts(12, FontWeight.w500, AppColors.muted)),
                          Text('Hello, ${p?.displayName ?? 'there'}', style: ts(18, FontWeight.w700)),
                        ],
                      ),
                    ),
                    CircleBtn(
                      icon: Icons.notifications_none_rounded,
                      badge: buildNotifications().isNotEmpty,
                      onTap: () => _push(context, const NotificationsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Balance
                Text('Your Available Balance', style: ts(13, FontWeight.w500, AppColors.muted)),
                const SizedBox(height: 4),
                BalanceText(app.totalBalance),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('This month', style: ts(12, FontWeight.w500, AppColors.muted)),
                    const SizedBox(width: 8),
                    Text(rupiah(net, sign: true), style: ts(13, FontWeight.w700, AppColors.tosca)),
                    if (growth != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (growth >= 0 ? AppColors.tosca : AppColors.danger).o(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              growth >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 14,
                              color: growth >= 0 ? AppColors.tosca : AppColors.danger,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${growth.abs().toStringAsFixed(0)}%',
                              style: ts(11, FontWeight.w700, growth >= 0 ? AppColors.tosca : AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                // Quick actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickAction(
                      icon: Icons.download_rounded,
                      label: 'Top Up',
                      onTap: () => _push(context, const TransactionScreen(kind: TxnKind.topup)),
                    ),
                    _QuickAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Transfer',
                      onTap: () => _push(context, const TransferScreen()),
                    ),
                    _QuickAction(
                      icon: Icons.north_east_rounded,
                      label: 'Expense',
                      onTap: () => _push(context, const TransactionScreen(kind: TxnKind.expense)),
                    ),
                    _QuickAction(
                      icon: Icons.more_horiz_rounded,
                      label: 'More',
                      onTap: () => showMoreSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Wallets
                Row(
                  children: [
                    Expanded(child: Text('Wallets', style: ts(17, FontWeight.w700))),
                    CircleBtn(
                      icon: Icons.add_rounded,
                      size: 32,
                      bg: AppColors.unguTua,
                      fg: AppColors.putih,
                      onTap: () => _push(context, const AddWalletScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (app.wallets.isEmpty)
                  const EmptyState(icon: Icons.credit_card_rounded, text: 'No wallet yet. Tap + to add one.')
                else
                  // Sengaja tidak `const` agar ikut diperbarui saat saldo berubah.
                  // ignore: prefer_const_constructors
                  WalletStack(),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.putih,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.unguTua.o(0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: AppColors.unguTua),
          ),
          const SizedBox(height: 8),
          Text(label, style: ts(12, FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Tumpukan kartu wallet. Tap kartu belakang → kartu itu terbuka penuh, kartu lain merapat.
/// Tap kartu yang terbuka (atau kartu utama) → kembali ke posisi awal.
class WalletStack extends StatefulWidget {
  const WalletStack({super.key});

  @override
  State<WalletStack> createState() => _WalletStackState();
}

class _WalletStackState extends State<WalletStack> {
  String? _selectedId;
  static const _peek = 46.0;
  static const _cardH = 190.0;

  @override
  Widget build(BuildContext context) {
    final ws = [...app.wallets]..sort((a, b) => (a.isMain ? 1 : 0) - (b.isMain ? 1 : 0));
    final n = ws.length;
    var sel = _selectedId == null ? -1 : ws.indexWhere((w) => w.id == _selectedId);
    if (sel == n - 1) sel = -1;

    double topOf(int i) {
      if (sel < 0) {
        if (i < n - 1) return i * _peek;
        return n == 1 ? 0 : max(_peek, (n - 1) * _peek - 28);
      }
      if (i <= sel) return i * _peek;
      return sel * _peek + _cardH + 10 + (i - sel - 1) * _peek;
    }

    var height = 0.0;
    for (var i = 0; i < n; i++) {
      height = max(height, topOf(i) + _cardH);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            AnimatedPositioned(
              key: ValueKey(ws[i].id),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              top: topOf(i),
              left: 0,
              right: 0,
              height: _cardH,
              child: GestureDetector(
                onTap: () => setState(() {
                  final isOpen = ws[i].id == _selectedId;
                  _selectedId = (i == n - 1 || isOpen) ? null : ws[i].id;
                }),
                onLongPress: () => showWalletActions(context, ws[i]),
                child: WalletCardView.of(ws[i], app.balanceOf(ws[i].id)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Aksi tekan-lama kartu: jadikan utama atau hapus.
void showWalletActions(BuildContext context, Wallet w) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.putih,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.name, style: ts(16, FontWeight.w700)),
            const SizedBox(height: 8),
            if (!w.isMain)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_rounded, color: AppColors.kuning),
                title: const Text('Set as main wallet'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await app.setMainWallet(w.id);
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_rounded, color: AppColors.danger),
              title: const Text('Delete wallet'),
              subtitle: const Text('All transactions in this wallet will be deleted'),
              onTap: () async {
                Navigator.pop(ctx);
                await app.deleteWallet(w.id);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
