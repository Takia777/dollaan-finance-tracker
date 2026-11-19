import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import 'setup_screen.dart';
import 'shell.dart';
import 'splash_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  bool _busy = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || password.length < 6) {
      showSnack(context, 'Masukkan email yang valid dan password minimal 6 karakter.');
      return;
    }
    if (_register && _name.text.trim().isEmpty) {
      showSnack(context, 'Isi nama lengkapmu dulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_register) {
        final needsConfirm = await app.repo.signUp(email, password, _name.text.trim());
        if (needsConfirm) {
          if (!mounted) return;
          showSnack(context, 'Cek email untuk konfirmasi akun, lalu login.');
          setState(() {
            _register = false;
            _busy = false;
          });
          return;
        }
      } else {
        await app.repo.signIn(email, password);
      }
      await app.loadAll();
      if (!mounted) return;
      final done = app.profile?.setupDone ?? false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => done ? const Shell() : const SetupScreen()),
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
      backgroundColor: AppColors.unguTua,
      body: Column(
        children: [
          const SizedBox(height: 260, child: SplashArt()),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.sakura,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  children: [
                    Text(_register ? 'Create your account' : 'Welcome back', style: ts(24, FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      _register ? 'Start tracking your money in a minute.' : 'Log in to continue to Dollaan.',
                      style: ts(14, FontWeight.w500, AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    if (_register) ...[
                      AppTextField(label: 'Full name', controller: _name, icon: Icons.person_rounded),
                      const SizedBox(height: 14),
                    ],
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      icon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      icon: Icons.lock_rounded,
                      obscure: true,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _register ? 'Sign up' : 'Log in',
                      dark: true,
                      loading: _busy,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : () => setState(() => _register = !_register),
                        child: Text(
                          _register ? 'Already have an account? Log in' : 'New here? Create an account',
                          style: ts(13, FontWeight.w700, AppColors.tosca),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
