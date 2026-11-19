import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import 'achievements_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context) async {
    final p = app.profile;
    final full = TextEditingController(text: p?.fullName ?? '');
    final nick = TextEditingController(text: p?.nickname ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: full, decoration: const InputDecoration(labelText: 'Full name')),
            TextField(controller: nick, decoration: const InputDecoration(labelText: 'Nickname')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await app.saveProfile({'full_name': full.text.trim(), 'nickname': nick.text.trim()});
    }
  }

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    await app.repo.signOut();
    app.clear();
    nav.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const AuthScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final p = app.profile;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                TopBar(
                  title: 'Profile',
                  trailing: CircleBtn(icon: Icons.edit_rounded, onTap: () => _editName(context)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.ungu,
                    child: Text(p?.initial ?? 'D', style: ts(38, FontWeight.w800, AppColors.putih)),
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: Text(p?.fullName.isNotEmpty == true ? p!.fullName : 'Dollaan user', style: ts(20, FontWeight.w800))),
                Center(child: Text(p?.email ?? '', style: ts(13, FontWeight.w500, AppColors.muted))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(color: AppColors.unguTua, borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stat('${app.wallets.length}', 'Wallets'),
                        _stat('${app.activeGoals.length}', 'Active goals'),
                        _stat('${app.streakDays}d', 'Streak'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        _row(Icons.account_balance_wallet_rounded, AppColors.ungu, 'My wallets',
                            '${app.wallets.length} wallets', () {
                          Navigator.pop(context);
                          app.tab.value = 0;
                        }),
                        _row(Icons.emoji_events_rounded, AppColors.kuning, 'Achievements',
                            '${app.packedGoals.length} goals completed', () {
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()));
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: AppColors.unguTua.o(0.25), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.unguTua),
                    label: Text('Log out', style: ts(14, FontWeight.w700)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String v, String l) => Column(
        children: [
          Text(v, style: ts(22, FontWeight.w800, AppColors.putih)),
          Text(l, style: ts(11, FontWeight.w500, AppColors.putih.o(0.7))),
        ],
      );

  Widget _row(IconData icon, Color color, String title, String sub, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              IconBubble(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ts(14, FontWeight.w600)),
                    Text(sub, style: ts(11, FontWeight.w500, AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      );
}
