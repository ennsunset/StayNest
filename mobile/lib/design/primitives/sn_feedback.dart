// design/primitives/sn_feedback.dart
//
// The four states that aren't the happy path, plus the moment-screen template
// they're built on. Part H requires all five states on every screen — these are
// what make that cheap instead of a chore.

import 'package:flutter/material.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'sn_button.dart';

/// Shimmering placeholder block. Skeletons, never spinners — a spinner tells
/// the user nothing about what's coming.
class SNSkeleton extends StatefulWidget {
  const SNSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = SNRadius.xs,
  });

  /// A full skeleton card matching HostelCard.list geometry.
  const SNSkeleton.listCard({super.key})
      : width = double.infinity,
        height = 120,
        radius = SNRadius.lg;

  final double? width;
  final double height;
  final double radius;

  @override
  State<SNSkeleton> createState() => _SNSkeletonState();
}

class _SNSkeletonState extends State<SNSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final t = _ctl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: [c.muted, c.accent, c.muted],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// The moment-screen template — success, pending, failure, empty, and every
/// full-page state in the app. One layout, tinted by meaning.
///
/// Direct from the design brief: 96px tinted circle, headline, one paragraph of
/// at most three lines, actions stacked with primary first.
class SNMoment extends StatelessWidget {
  const SNMoment({
    super.key,
    required this.icon,
    required this.headline,
    this.body,
    this.tone = SNStatusTone.neutral,
    this.primaryAction,
    this.secondaryAction,
    this.footer,
    this.pulse = false,
  });

  final IconData icon;
  final String headline;
  final String? body;
  final SNStatusTone tone;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  /// Extra content below the actions — a reference card, alternative beds.
  final Widget? footer;

  /// Slow 2s pulse, for waiting states only. Nothing fast: fast motion reads as
  /// urgency, and urgency reads as failure.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final s = c.styleFor(tone);

    Widget tile = Container(
      height: SNSize.momentIcon,
      width: SNSize.momentIcon,
      decoration: BoxDecoration(
        color: s.background,
        shape: BoxShape.circle,
        boxShadow: tone == SNStatusTone.neutral
            ? null
            : SNShadow.tinted(s.foreground),
      ),
      child: Icon(icon, size: 40, color: s.foreground),
    );

    if (pulse) tile = _SlowPulse(child: tile);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SNSpace.x8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: tile),
            const SizedBox(height: SNSpace.x6),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: SNText.displayMd.copyWith(color: c.foreground),
            ),
            if (body != null) ...[
              const SizedBox(height: SNSpace.x3),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: SNText.body.copyWith(color: c.mutedForeground),
              ),
            ],
            if (primaryAction != null || secondaryAction != null) ...[
              const SizedBox(height: SNSpace.x8),
              if (primaryAction != null) primaryAction!,
              if (primaryAction != null && secondaryAction != null)
                const SizedBox(height: SNSpace.x4),
              if (secondaryAction != null) secondaryAction!,
            ],
            if (footer != null) ...[
              const SizedBox(height: SNSpace.x8),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state. **Always carries a real action** — an empty screen is an
/// invitation to act, not a shrug. "No results" with nothing to tap is a bug.
class SNEmptyState extends StatelessWidget {
  const SNEmptyState({
    super.key,
    required this.headline,
    required this.actionLabel,
    required this.onAction,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.secondaryLine,
  });

  final String headline;
  final String? body;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;

  /// Optional informative line — e.g. the occupancy number on an owner's empty
  /// Booking Requests screen. Keeps an empty screen useful.
  final Widget? secondaryLine;

  @override
  Widget build(BuildContext context) {
    return SNMoment(
      icon: icon,
      headline: headline,
      body: body,
      primaryAction: SNButton(label: actionLabel, onPressed: onAction),
      footer: secondaryLine,
    );
  }
}

/// Error state. Plain language and a retry. Never a stack trace, never a
/// gateway code, never an apology.
class SNErrorState extends StatelessWidget {
  const SNErrorState({
    super.key,
    required this.onRetry,
    this.headline = 'Something went wrong',
    this.body = 'We couldn\'t load this. Check your connection and try again.',
  });

  final String headline;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SNMoment(
      icon: Icons.refresh_rounded,
      tone: SNStatusTone.danger,
      headline: headline,
      body: body,
      primaryAction: SNButton(label: 'Try again', onPressed: onRetry),
    );
  }
}

/// App-wide connectivity banner. Driven by a connectivity provider, not by any
/// individual request — offline is orthogonal to request state (decision D2).
class SNOfflineBanner extends StatelessWidget {
  const SNOfflineBanner({super.key, this.showingCached = false});

  /// When true the message says cached content is on screen, which is more
  /// useful than "you're offline" on its own.
  final bool showingCached;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Container(
      width: double.infinity,
      color: c.foreground,
      padding: const EdgeInsets.symmetric(
        horizontal: SNSpace.screenX,
        vertical: SNSpace.x3,
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: c.background),
          const SizedBox(width: SNSpace.x2),
          Expanded(
            child: Text(
              showingCached
                  ? 'No connection. Showing what we last loaded.'
                  : 'No connection.',
              style: SNText.caption.copyWith(color: c.background),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlowPulse extends StatefulWidget {
  const _SlowPulse({required this.child});

  final Widget child;

  @override
  State<_SlowPulse> createState() => _SlowPulseState();
}

class _SlowPulseState extends State<_SlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: SNMotion.slow,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect the OS reduce-motion setting — quality floor, not a nicety.
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return ScaleTransition(
      scale: Tween(begin: 0.94, end: 1.06)
          .animate(CurvedAnimation(parent: _ctl, curve: SNMotion.pulseCurve)),
      child: widget.child,
    );
  }
}
