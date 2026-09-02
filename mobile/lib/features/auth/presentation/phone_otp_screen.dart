// features/auth/presentation/phone_otp_screen.dart

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/auth/data/auth_repository.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _codes = List.generate(6, (_) => TextEditingController());
  final _focuses = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _hasError = false;
  String? _errorText;
  int _resendSeconds = 42;
  Timer? _resendTimer;
  String _phoneDisplay = '+233 •• ••• ••••';
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _loadStatusAndSendOtp();
  }

  Future<void> _loadStatusAndSendOtp() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final status = await repo.getVerificationStatus();
      if (!mounted) return;

      if (status.phone != null && status.phone!.isNotEmpty) {
        final p = status.phone!;
        setState(() {
          _phoneDisplay = '${p.substring(0, 4)} •• ••• ${p.substring(p.length - 4)}';
        });
      }

      // Send OTP automatically
      await repo.sendOtp(type: 'PHONE');
      if (!mounted) return;
      setState(() => _otpSent = true);
      _startResendTimer();
      _focuses[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to send code. Tap Resend.');
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 42);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _codes) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  String get _fullCode => _codes.map((c) => c.text).join();
  bool get _codeComplete => _fullCode.length == 6;

  void _onDigitChanged(int index, String value) {
    setState(() {
      _hasError = false;
      _errorText = null;
    });

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 6) {
        for (var i = 0; i < 6; i++) {
          _codes[i].text = digits[i];
        }
        _focuses[5].requestFocus();
        _submit();
        return;
      }
      _codes[index].text = value[value.length - 1];
    }

    if (value.isNotEmpty && index < 5) {
      _focuses[index + 1].requestFocus();
    }

    if (_codeComplete) _submit();
  }

  void _onBackspace(int index) {
    if (_codes[index].text.isEmpty && index > 0) {
      _focuses[index - 1].requestFocus();
      _codes[index - 1].clear();
    }
  }

  Future<void> _submit() async {
    if (!_codeComplete || _verifying) return;
    setState(() => _verifying = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyOtp(type: 'PHONE', code: _fullCode);
      if (!mounted) return;
      context.go(Routes.emailVerification);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message'];
      setState(() {
        _verifying = false;
        _hasError = true;
        _errorText = msg is String ? msg : 'Invalid code. Try again.';
      });
      // Clear boxes
      for (final c in _codes) {
        c.clear();
      }
      _focuses[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _hasError = true;
        _errorText = 'Something went wrong. Try again.';
      });
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendOtp(type: 'PHONE');
      if (!mounted) return;
      _startResendTimer();
      setState(() => _errorText = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to resend. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SNSpace.x4),
            Text(
              'Verify your number',
              style: SNText.displayMd.copyWith(color: c.foreground),
            ),
            const SizedBox(height: SNSpace.x3),
            Text.rich(
              TextSpan(
                style: SNText.body.copyWith(color: c.mutedForeground),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to '),
                  TextSpan(
                    text: _phoneDisplay,
                    style: SNText.bodyBold.copyWith(color: c.foreground),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SNSpace.x1),
            GestureDetector(
              onTap: () => context.pop(),
              child: Text(
                'Change',
                style: SNText.bodyBold.copyWith(color: c.primary),
              ),
            ),

            const SizedBox(height: SNSpace.x8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (i) => _OtpBox(
                  controller: _codes[i],
                  focusNode: _focuses[i],
                  hasError: _hasError,
                  onChanged: (v) => _onDigitChanged(i, v),
                  onBackspace: () => _onBackspace(i),
                ),
              ),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: SNSpace.x3),
              Text(
                _errorText!,
                style: SNText.caption.copyWith(color: c.destructive),
              ),
            ],

            const SizedBox(height: SNSpace.x6),

            Center(
              child: _resendSeconds > 0
                  ? Text(
                      'Resend code in 0:${_resendSeconds.toString().padLeft(2, '0')}',
                      style: SNText.caption.copyWith(color: c.mutedForeground),
                    )
                  : GestureDetector(
                      onTap: _resend,
                      child: Text(
                        'Resend',
                        style: SNText.bodyBold.copyWith(color: c.primary),
                      ),
                    ),
            ),

            const Spacer(),

            SNButton(
              label: 'Verify',
              onPressed: _codeComplete ? _submit : null,
              isLoading: _verifying,
            ),
            const SizedBox(height: SNSpace.section),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final filled = controller.text.isNotEmpty;
    final focused = focusNode.hasFocus;

    return SizedBox(
      width: SNSize.otpBoxW,
      height: SNSize.otpBoxH,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: SNText.otpDigit.copyWith(color: c.foreground),
          maxLength: 6,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: filled ? c.accent : c.card,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: SNRadius.control,
              borderSide: BorderSide(
                color: hasError ? c.destructive : focused ? c.primary : c.border,
                width: focused || hasError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: SNRadius.control,
              borderSide: BorderSide(
                color: hasError ? c.destructive : c.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: SNRadius.control,
              borderSide: BorderSide(
                color: hasError ? c.destructive : c.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
