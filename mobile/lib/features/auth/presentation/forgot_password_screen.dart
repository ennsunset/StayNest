// features/auth/presentation/forgot_password_screen.dart
//
// Screen 8 — Forgot Password + Reset Password.
// 3 steps: email → code → new password.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/core/theme/status_palette.dart';

enum _Step { email, code, newPassword, done }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtl.dispose();
    _codeCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/password/forgot', data: {'email': email});
    } catch (_) {
      // Always advance — never reveal if email exists
    }

    if (!mounted) return;
    setState(() { _loading = false; _step = _Step.code; });
  }

  Future<void> _verifyAndReset() async {
    final code = _codeCtl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    final password = _passwordCtl.text;
    final confirm = _confirmCtl.text;
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/password/reset', data: {
        'email': _emailCtl.text.trim(),
        'code': code,
        'newPassword': password,
      });
      if (!mounted) return;
      setState(() { _loading = false; _step = _Step.done; });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] as String?) ?? 'Invalid or expired code'
          : 'Invalid or expired code';
      setState(() { _loading = false; _error = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    if (_step == _Step.done) {
      return Scaffold(
        backgroundColor: c.background,
        body: SNMoment(
          icon: Icons.check_circle_outline_rounded,
          headline: 'Password reset!',
          body: 'Your password has been updated. You can now sign in with your new password.',
          tone: SNStatusTone.success,
          primaryAction: SNButton(
            label: 'Sign In',
            onPressed: () => context.go(Routes.login),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Reset Password',
        onBack: () {
          if (_step == _Step.code) {
            setState(() { _step = _Step.email; _error = null; });
          } else {
            context.pop();
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
        child: _step == _Step.email ? _buildEmailStep(c) : _buildCodeStep(c),
      ),
    );
  }

  Widget _buildEmailStep(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SNSpace.x6),
        Text('Forgot your\npassword?', style: SNText.displayMd.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x3),
        Text(
          "Enter the email you registered with and we'll send you a 6-digit reset code.",
          style: SNText.body.copyWith(color: c.mutedForeground),
        ),
        const SizedBox(height: SNSpace.x8),
        SNInput(
          label: 'Email',
          hint: 'you@university.edu.gh',
          controller: _emailCtl,
          errorText: _error,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _sendCode(),
        ),
        const Spacer(),
        SNButton(
          label: 'Send Reset Code',
          onPressed: _emailCtl.text.trim().isNotEmpty ? _sendCode : null,
          isLoading: _loading,
        ),
        const SizedBox(height: SNSpace.section),
      ],
    );
  }

  Widget _buildCodeStep(SNColorTokens c) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SNSpace.x6),
          Text('Enter reset code', style: SNText.displayMd.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x3),
          Text(
            'We sent a 6-digit code to ${_emailCtl.text.trim()}. Enter it below with your new password.',
            style: SNText.body.copyWith(color: c.mutedForeground),
          ),
          const SizedBox(height: SNSpace.x8),
          SNInput(
            label: 'Reset Code',
            hint: '000000',
            controller: _codeCtl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: SNSpace.x5),
          SNInput(
            label: 'New Password',
            hint: 'At least 8 characters',
            controller: _passwordCtl,
            obscure: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: SNSpace.x5),
          SNInput(
            label: 'Confirm Password',
            hint: 'Re-enter your new password',
            controller: _confirmCtl,
            obscure: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _verifyAndReset(),
          ),
          if (_error != null) ...[
            const SizedBox(height: SNSpace.x4),
            Text(_error!, style: SNText.caption.copyWith(color: c.destructive)),
          ],
          const SizedBox(height: SNSpace.x8),
          SNButton(
            label: 'Reset Password',
            onPressed: _verifyAndReset,
            isLoading: _loading,
          ),
          const SizedBox(height: SNSpace.x5),
          Center(
            child: GestureDetector(
              onTap: _loading ? null : _sendCode,
              child: Text('Resend code', style: SNText.bodyBold.copyWith(color: c.primary)),
            ),
          ),
          const SizedBox(height: SNSpace.section),
        ],
      ),
    );
  }
}
