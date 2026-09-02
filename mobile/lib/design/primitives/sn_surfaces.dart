// design/primitives/sn_surfaces.dart
//
// Card, badge, chip, avatar, section label. The small pieces every screen is
// assembled from.

import 'package:flutter/material.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

/// `bg-card border border-border rounded-[1.5rem] shadow-sm`
///
/// [tinted] gives the `bg-primary/5 border-primary/10` treatment used for
/// informational cards — the AI strip, the MoMo hint on Payment Pending.
class SNCard extends StatelessWidget {
  const SNCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SNSpace.x5),
    this.onTap,
    this.tinted = false,
    this.tint,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool tinted;

  /// Defaults to primary when [tinted]. Pass warning/success/destructive for
  /// state cards.
  final Color? tint;

  /// Selected state for pickable cards — payment method, room type.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final t = tint ?? c.primary;

    final body = AnimatedContainer(
      duration: SNMotion.base,
      curve: SNMotion.curve,
      padding: padding,
      decoration: BoxDecoration(
        color: (tinted || selected) ? t.withValues(alpha: 0.05) : c.card,
        borderRadius: SNRadius.card,
        border: Border.all(
          color: selected
              ? t
              : tinted
                  ? t.withValues(alpha: 0.1)
                  : c.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: (tinted || selected) ? null : SNShadow.card(c.shadowTint),
      ),
      child: child,
    );

    if (onTap == null) return body;

    return _Pressable(onTap: onTap!, child: body);
  }
}

/// Small status pill. Colour comes from the status palette, never from a call
/// site — see core/theme/status_palette.dart.
class SNBadge extends StatelessWidget {
  const SNBadge({
    super.key,
    required this.label,
    this.tone = SNStatusTone.neutral,
    this.icon,
  });

  SNBadge.bed(BedState state, {super.key, this.icon})
      : label = state.label,
        tone = state.tone;

  SNBadge.booking(BookingState state, {super.key, this.icon})
      : label = state.label,
        tone = state.tone;

  SNBadge.payment(PaymentState state, {super.key, this.icon})
      : label = state.label,
        tone = state.tone;

  final String label;
  final SNStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = context.sn.styleFor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SNSpace.x3,
        vertical: SNSpace.x1 + 2,
      ),
      decoration: BoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(SNRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: s.foreground),
            const SizedBox(width: SNSpace.x1),
          ],
          Text(
            label.toUpperCase(),
            style: SNText.microAction.copyWith(color: s.foreground),
          ),
        ],
      ),
    );
  }
}

/// Filter pill. Horizontal scrollers on Home, Saved, Search Results.
/// Active = filled primary. Inactive = bordered card.
class SNChip extends StatelessWidget {
  const SNChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final fg = selected ? c.primaryForeground : c.foreground;

    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SNMotion.base,
        curve: SNMotion.curve,
        constraints: const BoxConstraints(minHeight: SNSpace.minTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: SNSpace.x4,
          vertical: SNSpace.x3,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.card,
          borderRadius: BorderRadius.circular(SNRadius.pill),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: SNSpace.x2),
            ],
            Text(label, style: SNText.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class SNAvatar extends StatelessWidget {
  const SNAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = SNSize.avatarSm,
    this.showPresence = false,
    this.isOnline = false,
  });

  final String? imageUrl;
  final String? initials;
  final double size;
  final bool showPresence;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    // Anonymised roommate display (decision D4) passes neither url nor
    // initials and lands on the generic glyph — that is intended, not a gap.
    final Widget inner = imageUrl != null
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(c),
          )
        : _fallback(c);

    final avatar = ClipOval(
      child: SizedBox(width: size, height: size, child: inner),
    );

    if (!showPresence) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            height: size * 0.28,
            width: size * 0.28,
            decoration: BoxDecoration(
              color: isOnline ? c.success : c.mutedForeground,
              shape: BoxShape.circle,
              border: Border.all(color: c.background, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(SNColorTokens c) {
    return Container(
      color: c.muted,
      alignment: Alignment.center,
      child: initials != null
          ? Text(
              initials!.toUpperCase(),
              style: SNText.bodyBold.copyWith(
                color: c.mutedForeground,
                fontSize: size * 0.36,
              ),
            )
          : Icon(
              Icons.person_outline,
              size: size * 0.5,
              color: c.mutedForeground,
            ),
    );
  }
}

/// `text-[10px] font-black uppercase tracking-[0.2em]` — used above every
/// section on every screen. If a screen has a heading that isn't a real
/// heading, it's this.
class SNSectionLabel extends StatelessWidget {
  const SNSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text.toUpperCase(),
          style: SNText.sectionLabel.copyWith(color: c.mutedForeground),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Shared press behaviour: scale to 0.95, matching `active:scale-95`.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: SNMotion.fast,
        curve: SNMotion.curve,
        child: widget.child,
      ),
    );
  }
}
