import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';

/// Pindah dana antar wallet milik sendiri.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Wallet? _from = app.mainWallet;
  Wallet? _to;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final w in app.wallets) {
      if (w.id != _from?.id) {
        _to = w;
        break;
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmountInput(_amount.text);
    if (_from == null || _to == null) {
      showSnack(context, 'Kamu butuh minimal 2 wallet untuk transfer.');
      return;
    }
    if (_from!.id == _to!.id) {
      showSnack(context, 'Wallet asal dan tujuan harus berbeda.');
      return;
    }
    if (amount == null || amount <= 0) {
      showSnack(context, 'Masukkan nominal yang valid.');
      return;
    }
    setState(() => _busy = true);
    try {
      await app.addTxn(
        walletId: _from!.id,
        toWalletId: _to!.id,
        kind: TxnKind.transfer,
        amount: amount,
        category: 'Transfer',
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Moved ${rupiah(amount)} to ${_to!.name}');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, friendlyError(e));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = parseAmountInput(_amount.text) ?? 0;
    final fromAfter = _from == null ? 0.0 : app.balanceOf(_from!.id) - amount;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Transfer'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Text('Move money between your own wallets.', style: ts(14, FontWeight.w500, AppColors.muted)),
                  const SizedBox(height: 14),
                  WalletSelector(
                    label: 'From',
                    wallet: _from,
                    onTap: () async {
                      final w = await pickWallet(context, title: 'Move from');
                      if (w != null) setState(() => _from = w);
                    },
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: CircleBtn(
                        icon: Icons.swap_vert_rounded,
                        bg: AppColors.kuning,
                        size: 40,
                        onTap: () => setState(() {
                          final t = _from;
                          _from = _to;
                          _to = t;
                        }),
                      ),
                    ),
                  ),
                  WalletSelector(
                    label: 'To',
                    wallet: _to,
                    onTap: () async {
                      final w = await pickWallet(context, title: 'Move to', excludeId: _from?.id);
                      if (w != null) setState(() => _to = w);
                    },
                  ),
                  const SizedBox(height: 14),
                  AmountInput(
                    label: 'Amount to move',
                    controller: _amount,
                    quick: const [50000.0, 100000.0, 200000.0, 500000.0],
                    helper: _from == null ? null : '${_from!.name} after: ${rupiah(fromAfter)}',
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Note (optional)',
                    controller: _note,
                    icon: Icons.edit_rounded,
                    hint: 'Saving for Sneakers #2',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: amount > 0 ? 'Transfer ${rupiah(amount)}' : 'Transfer',
                icon: Icons.swap_horiz_rounded,
                dark: true,
                loading: _busy,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
