import 'package:flutter/material.dart';

import '../categories.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';

/// Satu layar untuk Top Up (pemasukan) dan Expense (pengeluaran).
class TransactionScreen extends StatefulWidget {
  final TxnKind kind; // topup atau expense
  const TransactionScreen({super.key, required this.kind});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Wallet? _wallet = app.mainWallet;
  late String _category = widget.kind == TxnKind.topup ? 'Falling from heaven' : 'Food';
  DateTime _when = DateTime.now();
  bool _busy = false;

  bool get _isTopUp => widget.kind == TxnKind.topup;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d == null) return;
    final now = DateTime.now();
    setState(() => _when = DateTime(d.year, d.month, d.day, now.hour, now.minute));
  }

  Future<void> _save() async {
    final amount = parseAmountInput(_amount.text);
    if (_wallet == null) {
      showSnack(context, 'Buat wallet dulu di Home.');
      return;
    }
    if (amount == null || amount <= 0) {
      showSnack(context, 'Masukkan nominal yang valid.');
      return;
    }
    setState(() => _busy = true);
    try {
      await app.addTxn(
        walletId: _wallet!.id,
        kind: widget.kind,
        amount: amount,
        category: _category,
        note: _note.text,
        occurredAt: _when,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, _isTopUp ? 'Top up recorded!' : 'Expense saved!');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, friendlyError(e));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = _isTopUp ? incomeSources : expenseCategories;
    final amount = parseAmountInput(_amount.text) ?? 0;
    final balance = _wallet == null ? 0.0 : app.balanceOf(_wallet!.id);
    final after = _isTopUp ? balance + amount : balance - amount;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(title: _isTopUp ? 'Top Up' : 'Expense'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  if (!_isTopUp) ...[
                    Text('Record what you spent so your balance stays accurate.',
                        style: ts(14, FontWeight.w500, AppColors.muted)),
                    const SizedBox(height: 14),
                  ],
                  WalletSelector(
                    label: _isTopUp ? 'To wallet' : 'Paid from',
                    wallet: _wallet,
                    onTap: () async {
                      final w = await pickWallet(context);
                      if (w != null) setState(() => _wallet = w);
                    },
                  ),
                  const SizedBox(height: 14),
                  AmountInput(
                    label: _isTopUp ? 'Enter amount' : 'Amount spent',
                    controller: _amount,
                    quick: _isTopUp ? const [50000.0, 100000.0, 250000.0, 500000.0] : const [10000.0, 25000.0, 50000.0, 100000.0],
                    helper: _wallet == null ? null : '${_wallet!.name} after: ${rupiah(after)}',
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  Text(_isTopUp ? "Where's the money from?" : 'Category',
                      style: ts(13, FontWeight.w700, AppColors.muted)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: _isTopUp ? 3 : 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: _isTopUp ? 1.1 : 0.95,
                    children: [
                      for (final c in cats)
                        _CategoryTile(
                          category: c,
                          selected: _category == c.name,
                          onTap: () => setState(() => _category = c.name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Note',
                          controller: _note,
                          icon: Icons.edit_rounded,
                          hint: _isTopUp ? 'Uang saku' : 'Nasi Padang',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('When'),
                            GestureDetector(
                              onTap: _pickDate,
                              child: AppCard(
                                radius: 16,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.muted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dayOnly(_when) == dayOnly(DateTime.now()) ? 'Today, ${hhmm(_when)}' : shortDate(_when),
                                        overflow: TextOverflow.ellipsis,
                                        style: ts(14, FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: _isTopUp
                    ? (amount > 0 ? 'Top up ${rupiah(amount)}' : 'Top up')
                    : 'Save expense',
                icon: _isTopUp ? null : Icons.check_rounded,
                dark: !_isTopUp,
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

class _CategoryTile extends StatelessWidget {
  final MoneyCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.unguTua : AppColors.putih,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.kuning : category.color.o(0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, size: 18, color: selected ? AppColors.unguTua : category.color),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ts(11, FontWeight.w700, selected ? AppColors.putih : AppColors.unguTua),
            ),
          ],
        ),
      ),
    );
  }
}
