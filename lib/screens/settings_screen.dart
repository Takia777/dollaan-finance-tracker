import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _chooseLanguage(BuildContext context) async {
    final current = app.profile?.language ?? 'en';
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Language'),
        children: [
          for (final opt in const [('en', 'English'), ('id', 'Bahasa Indonesia')])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, opt.$1),
              child: Row(
                children: [
                  Icon(current == opt.$1 ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: AppColors.tosca),
                  const SizedBox(width: 12),
                  Text(opt.$2),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null && picked != current) {
      await app.saveProfile({'language': picked});
      if (context.mounted) {
        showSnack(context, 'Language saved. Full translation is coming in the next version.');
      }
    }
  }

  Future<void> _editBudget(BuildContext context) async {
    final c = TextEditingController(
        text: (app.profile?.monthlyBudget ?? 0) > 0 ? app.profile!.monthlyBudget.round().toString() : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'Rp ', hintText: '3000000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await app.saveProfile({'monthly_budget': parseAmountInput(c.text) ?? 0});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final p = app.profile;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Text('Settings', style: ts(24, FontWeight.w800)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.ungu,
                        child: Text(p?.initial ?? 'D', style: ts(20, FontWeight.w700, AppColors.putih)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p?.fullName.isNotEmpty == true ? p!.fullName : 'Your profile',
                                style: ts(15, FontWeight.w700)),
                            Text('View profile', style: ts(12, FontWeight.w600, AppColors.tosca)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _label('Preferences'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _row(Icons.language_rounded, AppColors.tosca, 'Language',
                        trailing: (p?.language ?? 'en') == 'id' ? 'Indonesia' : 'English',
                        onTap: () => _chooseLanguage(context)),
                    _row(Icons.payments_rounded, AppColors.kuning, 'Currency', trailing: 'IDR (Rp)'),
                    _row(Icons.account_balance_wallet_rounded, AppColors.ungu, 'Monthly budget',
                        trailing: (p?.monthlyBudget ?? 0) > 0 ? compactRp(p!.monthlyBudget) : 'Not set',
                        onTap: () => _editBudget(context)),
                    _switchRow(Icons.notifications_rounded, AppColors.unguTua, 'Daily saving reminder',
                        p?.dailyReminder ?? true, (v) => app.saveProfile({'daily_reminder': v})),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _label('Other'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _row(Icons.help_rounded, AppColors.kuning, 'Help center',
                        onTap: () => showSnack(context, 'Tip: tekan lama kartu wallet untuk opsi lainnya.')),
                    _row(Icons.star_rounded, AppColors.unguTua, 'About Dollaan',
                        trailing: 'v1.0',
                        onTap: () => showAboutDialog(
                              context: context,
                              applicationName: 'Dollaan',
                              applicationVersion: '1.0.0',
                              applicationLegalese: 'From dollar to dolan.',
                            )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t, style: ts(13, FontWeight.w700, AppColors.muted)),
      );

  Widget _row(IconData icon, Color color, String title, {String? trailing, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              IconBubble(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: ts(14, FontWeight.w600))),
              if (trailing != null) Text(trailing, style: ts(13, FontWeight.w600, AppColors.muted)),
              if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      );

  Widget _switchRow(IconData icon, Color color, String title, bool value, ValueChanged<bool> onChanged) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            IconBubble(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: ts(14, FontWeight.w600))),
            Switch(value: value, activeTrackColor: AppColors.tosca, onChanged: onChanged),
          ],
        ),
      );
}
