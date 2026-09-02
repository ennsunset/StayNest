// features/account/presentation/student_id_verification_screen.dart
// Screen 34 — Student ID Verification [NEW].
// Trap: ID images are sensitive. Private R2, signed URLs, documented deletion.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class StudentIdVerificationScreen extends StatefulWidget {
  const StudentIdVerificationScreen({super.key});

  @override
  State<StudentIdVerificationScreen> createState() => _StudentIdVerificationScreenState();
}

class _StudentIdVerificationScreenState extends State<StudentIdVerificationScreen> {
  _VerifyStep _step = _VerifyStep.explainer;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Verify ID',
        onBack: () => context.pop(),
      ),
      body: switch (_step) {
        _VerifyStep.explainer => _buildExplainer(c),
        _VerifyStep.capture => _buildCapture(c),
        _VerifyStep.review => _buildReview(c),
        _VerifyStep.pending => _buildPending(c),
      },
    );
  }

  Widget _buildExplainer(SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.all(SNSpace.screenX),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify your student ID', style: SNText.headingLg.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x4),
          Text(
            'A verified ID unlocks the Verified Student badge and builds trust with hostel owners.',
            style: SNText.body.copyWith(color: c.mutedForeground, height: 1.6),
          ),
          const SizedBox(height: SNSpace.section),
          _checkItem(c, Icons.badge_outlined, 'Have your student ID ready'),
          const SizedBox(height: SNSpace.x4),
          _checkItem(c, Icons.light_mode_outlined, 'Find good lighting'),
          const SizedBox(height: SNSpace.x4),
          _checkItem(c, Icons.crop_free_rounded, 'Fit the card inside the frame'),
          const Spacer(),
          SafeArea(
            top: false,
            child: SNButton(
              label: 'Take Photo',
              icon: Icons.camera_alt_rounded,
              onPressed: () => setState(() => _step = _VerifyStep.capture),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(SNColorTokens c, IconData icon, String text) {
    return Row(
      children: [
        Container(
          height: 40, width: 40,
          decoration: BoxDecoration(
            color: c.muted,
            borderRadius: BorderRadius.circular(SNRadius.sm),
          ),
          child: Icon(icon, size: 20, color: c.primary),
        ),
        const SizedBox(width: SNSpace.x4),
        Text(text, style: SNText.body.copyWith(color: c.foreground)),
      ],
    );
  }

  Widget _buildCapture(SNColorTokens c) {
    // Placeholder — real implementation uses camera
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black87,
            child: Center(
              child: Container(
                width: 300, height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SNRadius.sm),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    'Camera preview\nFit your ID inside the frame',
                    style: SNText.body.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: SafeArea(
            top: false,
            child: SNButton(
              label: 'Capture',
              onPressed: () => setState(() => _step = _VerifyStep.review),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.all(SNSpace.screenX),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: SNRadius.card,
              ),
              child: Center(
                child: Icon(Icons.badge_outlined, size: 64, color: c.mutedForeground),
              ),
            ),
          ),
          const SizedBox(height: SNSpace.x5),
          Row(
            children: [
              Expanded(
                child: SNButton(
                  label: 'Retake',
                  variant: SNButtonVariant.secondary,
                  onPressed: () => setState(() => _step = _VerifyStep.capture),
                ),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(
                child: SNButton(
                  label: 'Submit',
                  isLoading: _submitting,
                  onPressed: () async {
                    setState(() => _submitting = true);
                    await Future.delayed(const Duration(milliseconds: 800));
                    if (!mounted) return;
                    setState(() {
                      _submitting = false;
                      _step = _VerifyStep.pending;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPending(SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.all(SNSpace.screenX),
      child: SNMoment(
        icon: Icons.schedule_rounded,
        headline: "We're reviewing your ID",
        body: 'Usually within 24 hours. We\'ll notify you once verified.',
        tone: SNStatusTone.warning,
        primaryAction: SNButton(
          label: 'Back to Profile',
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

enum _VerifyStep { explainer, capture, review, pending }
