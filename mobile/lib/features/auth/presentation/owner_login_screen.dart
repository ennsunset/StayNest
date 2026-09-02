// features/owner/presentation/owner_login_screen.dart
//
// Screen 10 — Owner Login. Wired to POST /auth/login.

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
import 'package:staynest_mobile/features/auth/data/auth_repository.dart';

class OwnerLoginScreen extends ConsumerStatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  ConsumerState<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends ConsumerState<OwnerLoginScreen> {
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailCtl.text.trim().isNotEmpty && _passwordCtl.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _emailError = _emailCtl.text.trim().isEmpty ? 'Email is required' : null;
      _passwordError = _passwordCtl.text.isEmpty ? 'Password is required' : null;
      _generalError = null;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _loading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(
        email: _emailCtl.text.trim(),
        password: _passwordCtl.text,
      );
      if (!mounted) return;

      final role = user.role;
      if (role == 'OWNER') {
        context.go(Routes.ownerDashboard);
      } else {
        // Student used the wrong door — send them to student shell
        context.go(Routes.home);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message'];
      setState(() {
        _loading = false;
        _generalError = msg is String ? msg : 'Invalid email or password.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generalError = 'Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        onBack: () => context.go(Routes.welcome),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SNSpace.x6),

            Container(
              padding: const EdgeInsets.all(SNSpace.x4),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(SNRadius.sm),
              ),
              child: Icon(Icons.apartment_rounded, size: 32, color: c.primary),
            ),

            const SizedBox(height: SNSpace.x6),

            Text(
              'Owner Portal',
              style: SNText.displayMd.copyWith(color: c.foreground),
            ),
            const SizedBox(height: SNSpace.x2),
            Text(
              'Manage your properties, track bookings, and grow your hostel business.',
              style: SNText.body.copyWith(color: c.mutedForeground),
            ),

            const SizedBox(height: SNSpace.x8),

            SNInput(
              label: 'Work Email',
              hint: 'you@yourhostel.com',
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
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordCtl,
              errorText: _passwordError,
              obscure: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => setState(() => _passwordError = null),
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: SNSpace.x3),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push(Routes.forgotPassword),
                child: Text(
                  'Forgot password?',
                  style: SNText.bodyBold.copyWith(color: c.primary),
                ),
              ),
            ),

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

            SNButton(
              label: 'Access Dashboard',
              onPressed: _canSubmit ? _submit : null,
              isLoading: _loading,
            ),
            const SizedBox(height: SNSpace.x4),
            SNButton.secondary(
              label: 'Register your property',
              onPressed: () {},
            ),

            const SizedBox(height: SNSpace.x8),

            Center(
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  'Contact Sales',
                  style: SNText.bodyBold.copyWith(color: c.primary),
                ),
              ),
            ),

            const SizedBox(height: SNSpace.section),
          ],
        ),
      ),
    );
  }
}
