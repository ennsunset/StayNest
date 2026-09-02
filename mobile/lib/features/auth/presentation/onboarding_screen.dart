// features/auth/presentation/onboarding_screen.dart
//
// Screen 2 — Onboarding.
// Single value-proposition screen. No carousel — the zip doesn't have one
// and carousels cost conversion.
//
// "Find Your Perfect Home Near Campus" · Get Started · Sign In link.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Illustration placeholder ──
              // PHASE2: Replace with actual student illustration asset
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: SNRadius.card,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.home_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: SNSpace.x4),
                    Icon(
                      Icons.apartment_rounded,
                      size: 48,
                      color: c.primary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Headlines ──
              Text(
                'Find Your Perfect\nHome Near Campus',
                textAlign: TextAlign.center,
                style: SNText.displayMd.copyWith(color: c.foreground),
              ),
              const SizedBox(height: SNSpace.x4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4),
                child: Text(
                  'Discover verified hostels, compare prices, and book your stay in minutes with our AI assistant.',
                  textAlign: TextAlign.center,
                  style: SNText.body.copyWith(
                    color: c.mutedForeground,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(),

              // ── Actions ──
              SNButton(
                label: 'Get Started',
                onPressed: () => context.go(Routes.welcome),
              ),
              const SizedBox(height: SNSpace.x4),
              Row(
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

              const SizedBox(height: SNSpace.section),
            ],
          ),
        ),
      ),
    );
  }
}
