import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/wallet_card.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'shell.dart';

/// Setup awal 3 langkah: profil → preferensi → wallet pertama.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pc = PageController();
  int _step = 0;
  bool _busy = false;

  final _fullName = TextEditingController(text: app.profile?.fullName ?? '');
  final _nickname = TextEditingController(text: app.profile?.nickname ?? '');
  final _budget = TextEditingController();
  final _walletName = TextEditingController(text: 'Main Wallet');
  final _balance = TextEditingController();
  final _last4 = TextEditingController();

  String _language = app.profile?.language ?? 'en';
  bool _reminder = true;
  WalletType _type = WalletType.bank;
  String _color = 'unguTua';

  @override
  void dispose() {
    for (final c in [_fullName, _nickname, _budget, _walletName, _balance, _last4]) {
      c.dispose();
    }
    _pc.dispose();
    super.dispose();
  }

  void _go(int step) {
    setState(() => _step = step);
    _pc.animateToPage(step, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (_fullName.text.trim().isEmpty) {
        showSnack(context, 'Isi nama lengkapmu dulu.');
        return;
      }
      _go(1);
    } else if (_step == 1) {
      _go(2);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_walletName.text.trim().isEmpty) {
      showSnack(context, 'Beri nama wallet pertamamu.');
      return;
    }
    setState(() => _busy = true);
    try {
      await app.saveProfile({
        'full_name': _fullName.text.trim(),
        'nickname': _nickname.text.trim(),
        'language': _language,
        'currency': 'IDR',
        'monthly_budget': parseAmountInput(_budget.text) ?? 0,
        'daily_reminder': _reminder,
        'setup_done': true,
      });
      if (app.wallets.isEmpty) {
        await app.addWallet(
          name: _walletName.text.trim(),
          type: _type,
          color: _color,
          last4: _last4.text.trim(),
          initialBalance: parseAmountInput(_balance.text) ?? 0,
          isMain: true,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const Shell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showSnack(context, friendlyError(e));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  CircleBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: _step == 0 ? null : () => _go(_step - 1),
                  ),
                  const SizedBox(width: 14),
                  for (var i = 0; i < 3; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.tosca : AppColors.muted.o(0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 6),
                  ],
                  const SizedBox(width: 14),
                  Text('${_step + 1}/3', style: ts(13, FontWeight.w700, AppColors.muted)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                physics: const NeverScrollableScrollPhysics(),
                children: [_profileStep(), _preferenceStep(), _walletStep()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: _step == 2 ? 'Finish setup' : 'Continue',
                icon: _step == 2 ? Icons.check_rounded : Icons.chevron_right_rounded,
                dark: _step < 2,
                loading: _busy,
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _head(String title, String desc) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ts(26, FontWeight.w800)),
          const SizedBox(height: 6),
          Text(desc, style: ts(14, FontWeight.w500, AppColors.muted)),
          const SizedBox(height: 20),
        ],
      );

  Widget _profileStep() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        children: [
          _head("Let's set up your profile", 'Tell us a bit about you so Dollaan feels like yours.'),
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(color: AppColors.putih, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 48, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(label: 'Full name', controller: _fullName, icon: Icons.person_rounded),
          const SizedBox(height: 14),
          AppTextField(
            label: 'What should we call you?',
            controller: _nickname,
            icon: Icons.star_rounded,
            hint: 'Nickname',
          ),
        ],
      );

  Widget _preferenceStep() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        children: [
          _head('Your preferences', 'Choose your language and budget. You can change these later in Settings.'),
          const FieldLabel('Language'),
          for (final opt in const [('en', 'English', 'English (US)'), ('id', 'Bahasa Indonesia', 'Indonesian')])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _language = opt.$1),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.putih,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _language == opt.$1 ? AppColors.tosca : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded,
                          color: _language == opt.$1 ? AppColors.tosca : AppColors.muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.$2, style: ts(14, FontWeight.w700)),
                            Text(opt.$3, style: ts(11, FontWeight.w500, AppColors.muted)),
                          ],
                        ),
                      ),
                      Icon(
                        _language == opt.$1 ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: _language == opt.$1 ? AppColors.tosca : AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const FieldLabel('Currency'),
          const AppCard(
            radius: 16,
            child: Row(
              children: [
                Icon(Icons.payments_rounded, color: AppColors.muted),
                SizedBox(width: 12),
                Expanded(child: Text('IDR · Indonesian Rupiah (Rp)')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Monthly budget (optional)',
            controller: _budget,
            icon: Icons.account_balance_wallet_rounded,
            keyboardType: TextInputType.number,
            hint: 'Rp 3.000.000',
          ),
          const SizedBox(height: 14),
          AppCard(
            radius: 16,
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded, color: AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily saving reminder', style: ts(14, FontWeight.w700)),
                      Text('Shown in your notifications', style: ts(11, FontWeight.w500, AppColors.muted)),
                    ],
                  ),
                ),
                Switch(
                  value: _reminder,
                  activeTrackColor: AppColors.tosca,
                  onChanged: (v) => setState(() => _reminder = v),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _walletStep() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        children: [
          _head('Create your first wallet', 'Pick a card template and set your starting balance.'),
          WalletCardView(
            name: _walletName.text.isEmpty ? 'Main Wallet' : _walletName.text,
            type: _type,
            colorKey: _color,
            last4: _last4.text,
            balance: parseAmountInput(_balance.text) ?? 0,
            height: 180,
          ),
          const SizedBox(height: 16),
          const FieldLabel('Card type'),
          Row(
            children: [
              for (final t in WalletType.values) ...[
                Expanded(
                  child: ChoiceChipX(
                    label: walletTypeLabel(t),
                    selected: _type == t,
                    onTap: () => setState(() => _type = t),
                  ),
                ),
                if (t != WalletType.values.last) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel('Card color'),
          ColorPicker(selected: _color, onChanged: (c) => setState(() => _color = c)),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Wallet name',
            controller: _walletName,
            icon: Icons.account_balance_wallet_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Starting balance',
                  controller: _balance,
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: AppTextField(
                  label: 'Last 4 digits',
                  controller: _last4,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      );
}

/// Pilihan warna kartu (dipakai di Setup & Add Wallet).
class ColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const ColorPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in AppColors.cardColors.entries)
          GestureDetector(
            onTap: () => onChanged(entry.key),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == entry.key ? AppColors.tosca : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),
              ),
            ),
          ),
      ],
    );
  }
}
