// features/auth/presentation/register_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController(text: '+233');
  final _passwordCtl = TextEditingController();

  bool _loading = false;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtl.text.trim().isNotEmpty &&
      _emailCtl.text.trim().isNotEmpty &&
      _phoneCtl.text.trim().length > 4 &&
      _passwordCtl.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _nameError = _nameCtl.text.trim().isEmpty ? 'Name is required' : null;
      _emailError = _validateEmail(_emailCtl.text.trim());
      _phoneError = _validatePhone(_phoneCtl.text.trim());
      _passwordError = _validatePassword(_passwordCtl.text);
      _generalError = null;
    });

    if (_nameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null) {
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(authNotifierProvider.notifier).register(
            fullName: _nameCtl.text.trim(),
            email: _emailCtl.text.trim(),
            password: _passwordCtl.text,
            phone: _phoneCtl.text.trim(),
          );

      if (!mounted) return;
      context.go(Routes.phoneOtp);
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final message = e.response?.data?['message'];
      setState(() {
        _loading = false;
        _generalError = switch (status) {
          409 => 'An account with this email already exists.',
          429 => 'Too many attempts. Please wait a moment.',
          _ => message is String
              ? message
              : 'Something went wrong. Please try again.',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generalError = 'Something went wrong. Please try again.';
      });
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String phone) {
    if (phone.isEmpty || phone == '+233') return 'Phone number is required';
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!RegExp(r'^\+233\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid Ghanaian number (+233XXXXXXXXX)';
    }
    return null;
  }

  String? _validatePassword(String pw) {
    if (pw.isEmpty) return 'Password is required';
    if (pw.length < 8) return 'At least 8 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Create Account',
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SNSpace.x6),
            Text(
              'Join the community of verified students.',
              style: SNText.body.copyWith(color: c.mutedForeground),
            ),
            const SizedBox(height: SNSpace.x8),

            // ── Fields ──
            SNInput(
              label: 'Full Name',
              hint: 'Ama Mensah',
              controller: _nameCtl,
              errorText: _nameError,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: SNSpace.x5),

            SNInput(
              label: 'University Email',
              hint: 'you@university.edu',
              controller: _emailCtl,
              errorText: _emailError,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => setState(() => _emailError = null),
            ),
            const SizedBox(height: SNSpace.x5),

            SNInput(
              label: 'Phone Number',
              hint: '+233 24 000 0000',
              controller: _phoneCtl,
              errorText: _phoneError,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              onChanged: (_) => setState(() => _phoneError = null),
            ),
            const SizedBox(height: SNSpace.x5),

            SNInput(
              label: 'Password',
              hint: 'At least 8 characters',
              controller: _passwordCtl,
              errorText: _passwordError,
              obscure: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() => _passwordError = null),
              onSubmitted: (_) => _submit(),
            ),

            // ── Error ──
            if (_generalError != null) ...[
              const SizedBox(height: SNSpace.x4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SNSpace.x4),
                decoration: BoxDecoration(
                  color: c.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SNRadius.sm),
                ),
                child: Text(
                  _generalError!,
                  style: SNText.caption.copyWith(color: c.destructive),
                ),
              ),
            ],

            const SizedBox(height: SNSpace.x8),

            // ── Submit ──
            SNButton(
              label: 'Create Account',
              onPressed: _canSubmit ? _submit : null,
              isLoading: _loading,
            ),

            const SizedBox(height: SNSpace.x6),

            // ── Divider ──
            Row(
              children: [
                Expanded(child: Divider(color: c.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4),
                  child: Text(
                    'or continue with',
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
                ),
                Expanded(child: Divider(color: c.border)),
              ],
            ),

            const SizedBox(height: SNSpace.x5),

            // ── Social ──
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    icon: Icons.g_mobiledata_rounded,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: SNSpace.x4),
                Expanded(
                  child: _SocialButton(
                    label: 'Apple',
                    icon: Icons.apple_rounded,
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: SNSpace.x8),

            // ── Login link ──
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: SNText.body.copyWith(color: c.mutedForeground),
                  ),
                  GestureDetector(
                    onTap: () => context.go(Routes.login),
                    child: Text(
                      'Sign In',
                      style: SNText.bodyBold.copyWith(color: c.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SNSpace.section),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(SNRadius.sm),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: c.foreground),
            const SizedBox(width: SNSpace.x2),
            Text(label, style: SNText.bodyBold.copyWith(color: c.foreground)),
          ],
        ),
      ),
    );
  }
}
