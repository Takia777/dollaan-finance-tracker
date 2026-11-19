import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'setup_screen.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    Widget next;
    if (!onboarded) {
      next = const OnboardingScreen();
    } else if (app.repo.currentUser == null) {
      next = const AuthScreen();
    } else {
      try {
        await app.loadAll();
        next = (app.profile?.setupDone ?? false) ? const Shell() : const SetupScreen();
      } catch (_) {
        next = const AuthScreen();
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.unguTua, body: SplashArt());
  }
}

/// Tampilan splash (dipakai juga sebagai header di layar login).
class SplashArt extends StatelessWidget {
  final bool compact;
  const SplashArt({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(left: -120, top: -80, child: _circle(300, AppColors.ungu.o(0.35))),
        Positioned(right: -40, top: 140, child: _circle(90, AppColors.kuning.o(0.9))),
        Positioned(right: -60, bottom: -40, child: _circle(220, AppColors.tosca.o(0.5))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: AppColors.kuning, borderRadius: BorderRadius.circular(30)),
                child: const Icon(Icons.savings_rounded, size: 52, color: AppColors.unguTua),
              ),
              const SizedBox(height: 16),
              Text('Dollaan', style: ts(32, FontWeight.w800, AppColors.putih)),
              const SizedBox(height: 6),
              Text('From dollar to dolan', style: ts(14, FontWeight.w500, AppColors.putih.o(0.7))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circle(double s, Color c) =>
      Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
