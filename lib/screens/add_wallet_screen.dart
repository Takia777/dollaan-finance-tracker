import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/wallet_card.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'setup_screen.dart' show ColorPicker;

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _name = TextEditingController();
  final _balance = TextEditingController();
  final _last4 = TextEditingController();
  WalletType _type = WalletType.bank;
  String _color = 'unguTua';
  bool _useLogo = false;
  Uint8List? _logo;
  String _logoExt = 'png';
  bool _isMain = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _last4.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _logo = bytes;
      _logoExt = file.name.contains('.') ? file.name.split('.').last : 'png';
      _useLogo = true;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showSnack(context, 'Beri nama wallet dulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      await app.addWallet(
        name: _name.text.trim(),
        type: _type,
        color: _color,
        last4: _last4.text.trim(),
        initialBalance: parseAmountInput(_balance.text) ?? 0,
        isMain: _isMain,
        logoBytes: _useLogo ? _logo : null,
        logoExt: _logoExt,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Wallet created!');
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
            const TopBar(title: 'Add wallet', backIcon: Icons.close_rounded),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Stack(
                    children: [
                      WalletCardView(
                        name: _name.text.isEmpty ? 'Wallet name' : _name.text,
                        type: _type,
                        colorKey: _color,
                        last4: _last4.text,
                        balance: parseAmountInput(_balance.text) ?? 0,
                        showLogoSlot: _useLogo && _logo == null,
                      ),
                      if (_useLogo && _logo != null)
                        Positioned(
                          right: 20,
                          bottom: 18,
                          child: SizedBox(width: 60, height: 38, child: Image.memory(_logo!, fit: BoxFit.contain)),
                        ),
                    ],
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
                  const FieldLabel('Logo (bottom-right)'),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChipX(
                          icon: Icons.image_rounded,
                          label: _logo == null ? 'Upload logo' : 'Change logo',
                          selected: _useLogo,
                          onTap: _pickLogo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChipX(
                          icon: Icons.block_rounded,
                          label: 'No logo',
                          selected: !_useLogo,
                          onTap: () => setState(() => _useLogo = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Use a PNG with a transparent background, e.g. your bank or card network logo.',
                      style: ts(11, FontWeight.w500, AppColors.muted)),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Wallet name',
                    controller: _name,
                    icon: Icons.account_balance_wallet_rounded,
                    hint: 'e.g. Shopping card',
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
                  const SizedBox(height: 14),
                  AppCard(
                    radius: 16,
                    padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.muted),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Set as main wallet', style: ts(14, FontWeight.w600))),
                        Switch(
                          value: _isMain,
                          activeTrackColor: AppColors.tosca,
                          onChanged: (v) => setState(() => _isMain = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: 'Create wallet',
                icon: Icons.check_rounded,
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
