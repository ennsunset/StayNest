// design/domain/sn_domain_bits.dart
//
// The small domain pieces. Each appears on several screens and must look
// identical on all of them.

import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';

/// "Starts from / GH₵3,200 / Per Academic Year" — the sticky bar on Hostel
/// Details, and the price line on every card.
class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.amountPesewas,
    this.prefix,
    this.period = 'per semester',
    this.large = false,
  });

  const PriceTag.startsFrom({
    super.key,
    required this.amountPesewas,
    this.period = 'per semester',
  })  : prefix = 'Starts from',
        large = false;

  final int amountPesewas;
  final String? prefix;
  final String? period;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null)
          Text(
            prefix!.toUpperCase(),
            style: SNText.sectionLabel.copyWith(color: c.mutedForeground),
          ),
        Text(
          Money.formatCompact(amountPesewas),
          style: (large ? SNText.displayLg : SNText.headingLg)
              .copyWith(color: c.foreground),
        ),
        if (period != null)
          Text(
            period!,
            style: SNText.caption.copyWith(color: c.mutedForeground),
          ),
      ],
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.compact = true,
  });

  final double rating;
  final int? reviewCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: c.warning),
          const SizedBox(width: SNSpace.x1),
          Text(
            rating.toStringAsFixed(1),
            style: SNText.bodyBold.copyWith(color: c.foreground),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: SNSpace.x1),
            Text(
              '($reviewCount)',
              style: SNText.caption.copyWith(color: c.mutedForeground),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: 18,
            color: rating >= i - 0.5 ? c.warning : c.muted,
          ),
      ],
    );
  }
}

/// White 90% + backdrop blur, sits top-right on imagery. The visual promise
/// that an admin approved this listing — never render it speculatively.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.label = 'Verified', this.iconOnly = false});

  final String label;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return ClipRRect(
      borderRadius: BorderRadius.circular(SNRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SNSpace.x3,
            vertical: SNSpace.x1 + 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(SNRadius.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, size: 12, color: c.primary),
              if (!iconOnly) ...[
                const SizedBox(width: SNSpace.x1),
                Text(
                  label.toUpperCase(),
                  style: SNText.microAction.copyWith(color: c.foreground),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AmenityChip extends StatelessWidget {
  const AmenityChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SNSpace.x3,
        vertical: SNSpace.x2,
      ),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(SNRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.mutedForeground),
          const SizedBox(width: SNSpace.x2),
          Text(
            label.toUpperCase(),
            style: SNText.microAction.copyWith(color: c.secondaryForeground),
          ),
        ],
      ),
    );
  }
}

/// Owner dashboard and Manage Hostels. Colour shifts with load: healthy
/// occupancy is success, near-full is warning territory for the owner's
/// planning, not a failure.
class OccupancyBar extends StatelessWidget {
  const OccupancyBar({
    super.key,
    required this.occupied,
    required this.total,
    this.showLabel = true,
  });

  final int occupied;
  final int total;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final ratio = total == 0 ? 0.0 : (occupied / total).clamp(0.0, 1.0);
    final fill = ratio >= 0.9
        ? c.warning
        : ratio >= 0.5
            ? c.success
            : c.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OCCUPANCY',
                style: SNText.sectionLabel.copyWith(color: c.mutedForeground),
              ),
              Text(
                '$occupied of $total beds',
                style: SNText.caption.copyWith(color: c.foreground),
              ),
            ],
          ),
          const SizedBox(height: SNSpace.x2),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(SNRadius.pill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: c.muted,
            valueColor: AlwaysStoppedAnimation(fill),
          ),
        ),
      ],
    );
  }
}

/// One line in a price breakdown or a payment list. Amount is always pesewas.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.label,
    required this.amountPesewas,
    this.sublabel,
    this.leadingIcon,
    this.status,
    this.emphasised = false,
    this.onTap,
  });

  /// The bold total beneath a hairline rule. Amount renders in primary.
  const TransactionRow.total({
    super.key,
    required this.amountPesewas,
    this.label = 'Total',
  })  : sublabel = null,
        leadingIcon = null,
        status = null,
        emphasised = true,
        onTap = null;

  final String label;
  final int amountPesewas;
  final String? sublabel;
  final IconData? leadingIcon;
  final SNStatusTone? status;
  final bool emphasised;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: SNSpace.x3),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(SNSpace.x3),
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: BorderRadius.circular(SNRadius.xs),
              ),
              child: Icon(leadingIcon, size: 18, color: c.secondaryForeground),
            ),
            const SizedBox(width: SNSpace.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: (emphasised ? SNText.headingLg : SNText.body)
                      .copyWith(color: c.foreground),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
              ],
            ),
          ),
          const SizedBox(width: SNSpace.x3),
          Text(
            Money.format(amountPesewas),
            style: (emphasised ? SNText.headingLg : SNText.bodyBold).copyWith(
              color: emphasised ? c.primary : c.foreground,
            ),
          ),
        ],
      ),
    );

    if (!emphasised) {
      return onTap == null
          ? row
          : GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onTap, child: row);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.only(top: SNSpace.x1),
      child: row,
    );
  }
}

/// The hold countdown. Rides above every screen from Booking Review through
/// Payment.
///
/// **Driven by the server's `held_until`, never a local timer.** It recomputes
/// against the wall clock each tick and again on app resume — a phone that
/// slept for ten minutes must not still be showing 14:32.
class CountdownPill extends StatefulWidget {
  const CountdownPill({
    super.key,
    required this.heldUntil,
    required this.onExpired,
    this.labelSuffix = 'left to complete payment',
  });

  /// Server timestamp, in UTC.
  final DateTime heldUntil;

  /// Fired once, at zero. Routes to Bed Just Taken.
  final VoidCallback onExpired;

  final String labelSuffix;

  @override
  State<CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<CountdownPill>
    with WidgetsBindingObserver {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recompute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recompute();
  }

  void _recompute() {
    final left = widget.heldUntil.difference(DateTime.now().toUtc());
    final clamped = left.isNegative ? Duration.zero : left;
    if (mounted) setState(() => _remaining = clamped);

    if (clamped == Duration.zero && !_fired) {
      _fired = true;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpired());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    // Under two minutes the pill turns destructive. That's the only urgency
    // signal — no flashing, no sound.
    final urgent = _remaining.inSeconds <= 120;
    final tint = urgent ? c.destructive : c.warning;

    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    final digits = '$m:${s.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SNSpace.screenX,
        vertical: SNSpace.x3,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: tint.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: tint),
          const SizedBox(width: SNSpace.x2),
          Text(digits, style: SNText.monoDigits.copyWith(color: tint)),
          const SizedBox(width: SNSpace.x1),
          Text(
            widget.labelSuffix,
            style: SNText.caption.copyWith(color: c.foreground),
          ),
        ],
      ),
    );
  }
}
