// features/auth/presentation/welcome_screen.dart
//
// Screen 3 — Welcome / Role Select.
// Primary circle logo top-left, "Choose your account type" heading.
// Three cards: Student · Owner · University Admin.
// University Admin routes to a "coming soon" sheet in Phase 1.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: SNSpace.x10),

              // ── Logo circle with home icon ──
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.home_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: SNSpace.x5),

              // ── Header ──
              Text(
                'Choose your\naccount type',
                style: SNText.displayMd.copyWith(color: c.foreground),
              ),
              const SizedBox(height: SNSpace.x3),
              Text(
                'Tailoring the experience for your specific needs on campus.',
                style: SNText.body.copyWith(color: c.mutedForeground),
              ),

              const SizedBox(height: SNSpace.x8),

              // ── Role cards ──
              _RoleCard(
                icon: Icons.school_rounded,
                title: 'I am a Student',
                subtitle: 'Find and book verified hostels near campus',
                onTap: () => context.go(Routes.register),
              ),
              const SizedBox(height: SNSpace.x4),
              _RoleCard(
                icon: Icons.apartment_rounded,
                title: 'I am an Owner',
                subtitle: 'Manage properties and tenants',
                onTap: () => context.go(Routes.ownerLogin),
              ),
              const SizedBox(height: SNSpace.x4),
              _RoleCard(
                icon: Icons.account_balance_rounded,
                title: 'University Admin',
                subtitle: 'Oversight and verification',
                comingSoon: true,
                onTap: () => _showComingSoon(context),
              ),

              const Spacer(),

              // ── ToS footer ──
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: SNSpace.section),
                  child: Text.rich(
                    TextSpan(
                      style: SNText.caption.copyWith(color: c.mutedForeground),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our\n'),
                        TextSpan(
                          text: 'Terms of Service',
                          style: SNText.caption.copyWith(color: c.primary),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: SNText.caption.copyWith(color: c.primary),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    final c = context.sn;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, SNSpace.screenX),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SNSheetHandle(),
            const SizedBox(height: SNSpace.x2),
            Icon(Icons.account_balance_rounded, size: 48, color: c.primary),
            const SizedBox(height: SNSpace.x4),
            Text(
              'University Portal',
              style: SNText.headingLg.copyWith(color: c.foreground),
            ),
            const SizedBox(height: SNSpace.x2),
            Text(
              'The university admin portal is coming soon. Contact us at hello@staynest.app for early access.',
              textAlign: TextAlign.center,
              style: SNText.body.copyWith(color: c.mutedForeground),
            ),
            const SizedBox(height: SNSpace.x8),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return SNCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(
              color: comingSoon ? c.muted : c.accent,
              borderRadius: BorderRadius.circular(SNRadius.sm),
            ),
            child: Icon(
              icon,
              size: 28,
              color: comingSoon ? c.mutedForeground : c.primary,
            ),
          ),
          const SizedBox(width: SNSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: SNText.headingMd.copyWith(color: c.foreground),
                    ),
                    if (comingSoon) ...[
                      const SizedBox(width: SNSpace.x2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SNSpace.x2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.muted,
                          borderRadius: BorderRadius.circular(SNRadius.xs),
                        ),
                        child: Text(
                          'SOON',
                          style: SNText.microAction.copyWith(
                            color: c.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: SNSpace.x1),
                Text(
                  subtitle,
                  style: SNText.caption.copyWith(color: c.mutedForeground),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: c.mutedForeground,
          ),
        ],
      ),
    );
  }
}
