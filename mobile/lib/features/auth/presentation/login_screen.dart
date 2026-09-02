// features/auth/presentation/login_screen.dart
//
// Screen 8 — Login.
// Updated to match prototype: "Welcome Back" heading, uppercase labels,
// email/password icons, FORGOT? link, social login buttons, "Sign Up" link.
// Wired to real API via AuthNotifier.

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/features/auth/data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _googleSignIn() async {
    try {
      setState(() { _loading = true; _error = null; });
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) { setState(() => _loading = false); return; }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) { setState(() { _loading = false; _error = 'Google sign-in failed'; }); return; }
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.socialLogin(provider: 'google', idToken: idToken);
      if (mounted) context.go('/student');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Google sign-in failed');
    } catch (e) {
      setState(() => _error = 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignIn() async {
    try {
      setState(() { _loading = true; _error = null; });
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final idToken = credential.identityToken;
      if (idToken == null) { setState(() { _loading = false; _error = 'Apple sign-in failed'; }); return; }
      final fullName = [credential.givenName, credential.familyName].where((e) => e != null).join(' ');
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.socialLogin(provider: 'apple', idToken: idToken, fullName: fullName.isEmpty ? null : fullName);
      if (mounted) context.go('/student');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Apple sign-in failed');
    } catch (e) {
      setState(() => _error = 'Apple sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).login(
            email: email,
            password: password,
          );

      if (!mounted) return;
      context.go(Routes.home);
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      setState(() {
        _loading = false;
        _error = switch (status) {
          401 => 'Invalid email or password',
          429 => 'Too many attempts. Please wait a moment.',
          _ => 'Something went wrong. Please try again.',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: SNSpace.x10),

              // ── Header ──
              Text(
                'Welcome Back',
                style: SNText.displayMd.copyWith(color: c.foreground),
              ),
              const SizedBox(height: SNSpace.x2),
              Text(
                'Log in to manage your stays and bookings.',
                style: SNText.body.copyWith(color: c.mutedForeground),
              ),
              const SizedBox(height: SNSpace.section),

              // ── Email ──
              Text(
                'EMAIL ADDRESS',
                style: SNText.microAction.copyWith(
                  color: c.mutedForeground,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: SNSpace.x2),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: SNText.body.copyWith(color: c.foreground),
                decoration: _inputDecoration(
                  c,
                  'name@university.edu',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: c.mutedForeground),
                ),
              ),
              const SizedBox(height: SNSpace.x5),

              // ── Password ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PASSWORD',
                    style: SNText.microAction.copyWith(
                      color: c.mutedForeground,
                      letterSpacing: 1.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.forgotPassword),
                    child: Text(
                      'Forgot password?',
                      style: SNText.microAction.copyWith(
                        color: c.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SNSpace.x2),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: SNText.body.copyWith(color: c.foreground),
                decoration: _inputDecoration(
                  c,
                  '••••••••',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: c.mutedForeground),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: c.mutedForeground,
                    ),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),

              // ── Error ──
              if (_error != null) ...[
                const SizedBox(height: SNSpace.x4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SNSpace.x4),
                  decoration: BoxDecoration(
                    color: c.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SNRadius.sm),
                  ),
                  child: Text(_error!, style: SNText.caption.copyWith(color: c.destructive)),
                ),
              ],

              const SizedBox(height: SNSpace.x6),

              // ── Sign In button ──
              SNButton(
                label: 'Sign In',
                isLoading: _loading,
                onPressed: _login,
              ),

              const SizedBox(height: SNSpace.x6),

              // ── OR CONTINUE WITH divider ──
              Row(
                children: [
                  Expanded(child: Divider(color: c.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: SNText.microAction.copyWith(
                        color: c.mutedForeground,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: c.border)),
                ],
              ),

              const SizedBox(height: SNSpace.x5),

              // ── Social buttons (stubs) ──
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                      onTap: () async {
                _googleSignIn();
                      },
                    ),
                  ),
                  const SizedBox(width: SNSpace.x4),
                  Expanded(
                    child: _SocialButton(
                      label: 'Apple',
                      icon: Icons.apple_rounded,
                      onTap: () async {
                _appleSignIn();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: SNSpace.x10),

              // ── Register link ──
              Center(
                child: GestureDetector(
                  onTap: () => context.push(Routes.register),
                  child: Text.rich(
                    TextSpan(
                      style: SNText.body.copyWith(color: c.mutedForeground),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: SNText.bodyBold.copyWith(color: c.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    SNColorTokens c,
    String hint, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: SNText.body.copyWith(color: c.mutedForeground),
      filled: true,
      fillColor: c.card,
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: prefixIcon,
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 16),
              child: suffixIcon,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SNRadius.sm),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SNRadius.sm),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SNRadius.sm),
        borderSide: BorderSide(color: c.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SNSpace.x5,
        vertical: SNSpace.x4,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SNSpace.x4),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(SNRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: c.foreground),
            const SizedBox(width: SNSpace.x2),
            Text(
              label,
              style: SNText.bodyBold.copyWith(color: c.foreground),
            ),
          ],
        ),
      ),
    );
  }
}
