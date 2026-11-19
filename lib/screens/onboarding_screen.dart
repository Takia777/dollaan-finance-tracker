import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../ui/widgets.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    ('All your wallets in one place',
        'Track every card, e-wallet and cash pocket with one clear balance.', Icons.credit_card_rounded),
    ('Save for what you love',
        'Set a goal, add a picture, and watch it fill up. Keep your streak alive!', Icons.savings_rounded),
    ('Meet your money chatbot',
        'Just type "beli kopi 20rb" and Dollaan records it for you.', Icons.chat_bubble_rounded),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${_page + 1} / ${_pages.length}', style: ts(13, FontWeight.w700, AppColors.muted)),
                  const Spacer(),
                  if (!last)
                    TextButton(onPressed: _finish, child: Text('Skip', style: ts(13, FontWeight.w700))),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Center(child: _Illustration(index: i, icon: p.$3))),
                        Row(
                          children: [
                            for (var d = 0; d < _pages.length; d++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 6),
                                width: d == i ? 26 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: d == i ? AppColors.unguTua : AppColors.muted.o(0.35),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(p.$1, style: ts(28, FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(p.$2, style: ts(15, FontWeight.w500, AppColors.muted)),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
              PrimaryButton(
                label: last ? 'Get started' : 'Next',
                icon: Icons.chevron_right_rounded,
                dark: !last,
                onTap: () {
                  if (last) {
                    _finish();
                  } else {
                    _pc.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final int index;
  final IconData icon;
  const _Illustration({required this.index, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.ungu, AppColors.tosca, AppColors.unguTua];
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 290,
            height: 290,
            decoration: const BoxDecoration(color: AppColors.putih, shape: BoxShape.circle),
          ),
          if (index == 0) ...[
            for (var i = 0; i < 3; i++)
              Positioned(
                top: 70.0 + i * 50,
                child: Transform.rotate(
                  angle: (i - 1) * 0.12,
                  child: Container(
                    width: 220,
                    height: 128,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.unguTua.o(0.2), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.topRight,
                    child: const Icon(Icons.contactless, color: AppColors.putih),
                  ),
                ),
              ),
          ] else
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(color: AppColors.kuning, borderRadius: BorderRadius.circular(44)),
              child: Icon(icon, size: 72, color: AppColors.unguTua),
            ),
        ],
      ),
    );
  }
}
