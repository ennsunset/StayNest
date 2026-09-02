// core/theme/tokens.dart
//
// Single source of truth for every colour, radius and spacing value in StayNest.
// Derived once from globals.css. Never look at the CSS again.
//
// Colours live in a ThemeExtension, NOT as bare statics. This is deliberate:
// adding dark mode later means writing one more SNColorTokens instance in this
// file, not touching 50 screens. Read them via `context.sn` (see context_ext.dart).

import 'package:flutter/material.dart';

@immutable
class SNColorTokens extends ThemeExtension<SNColorTokens> {
  const SNColorTokens({
    required this.background,
    required this.foreground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.border,
    required this.input,
    required this.ring,
    required this.chart,
    required this.glassFill,
    required this.glassBorder,
    required this.shadowTint,
  });

  final Color background;
  final Color foreground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;

  /// Absent from globals.css. Defined by us — booking states need them.
  final Color success;
  final Color warning;

  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color border;
  final Color input;
  final Color ring;

  /// Chart series, in order. Never reorder — reports depend on stable colours.
  final List<Color> chart;

  /// The `bg-white/20 backdrop-blur-md border-white/20` treatment used for
  /// controls sitting on imagery (hostel hero, gallery). Tokenised because it
  /// inverts under a dark theme and must not be hardcoded at call sites.
  final Color glassFill;
  final Color glassBorder;

  /// Base colour for elevation shadows. Shadows are subtle throughout — keep
  /// them that way.
  final Color shadowTint;

  // ── Light (the only theme in Phase 1) ───────────────────────────────────

  static const light = SNColorTokens(
    background: Color(0xFFF8FAFC),
    foreground: Color(0xFF1C2B41),
    primary: Color(0xFF4F46E5),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFE8DFD5),
    secondaryForeground: Color(0xFF3D4C63),
    muted: Color(0xFFE6EBF2),
    mutedForeground: Color(0xFF637388),
    accent: Color(0xFFE4E7F5),
    accentForeground: Color(0xFF1C2B41),
    destructive: Color(0xFFE97B86),
    success: Color(0xFF3FB68B),
    warning: Color(0xFFE8A33D),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF1C2B41),
    popover: Color(0xFFFFFFFF),
    border: Color(0xFFE8EEF5),
    input: Color(0xFFFFFFFF),
    ring: Color(0xFF4F46E5),
    chart: [
      Color(0xFF8496E6),
      Color(0xFFE8DFD5),
      Color(0xFFA8C4F9),
      Color(0xFFD1BBE0),
      Color(0xFFFAD3C3),
    ],
    glassFill: Color(0x33FFFFFF), // white/20
    glassBorder: Color(0x33FFFFFF),
    shadowTint: Color(0xFF1C2B41),
  );

  // When dark mode arrives: add `static const dark = SNColorTokens(...)` here
  // and one line in theme.dart. Nothing else in the app changes.

  @override
  SNColorTokens copyWith({
    Color? background,
    Color? foreground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? success,
    Color? warning,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? border,
    Color? input,
    Color? ring,
    List<Color>? chart,
    Color? glassFill,
    Color? glassBorder,
    Color? shadowTint,
  }) {
    return SNColorTokens(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      chart: chart ?? this.chart,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      shadowTint: shadowTint ?? this.shadowTint,
    );
  }

  @override
  SNColorTokens lerp(ThemeExtension<SNColorTokens>? other, double t) {
    if (other is! SNColorTokens) return this;
    List<Color> lerpChart() {
      return [
        for (var i = 0; i < chart.length; i++)
          Color.lerp(chart[i], other.chart[i], t)!,
      ];
    }

    return SNColorTokens(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground:
          Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      chart: lerpChart(),
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      shadowTint: Color.lerp(shadowTint, other.shadowTint, t)!,
    );
  }
}

/// Corner radii. Base is 1.25rem (20px); the scale runs base-8 to base+24.
abstract final class SNRadius {
  static const double xs = 12; // rounded-xl
  static const double sm = 16; // rounded-2xl — inputs, OTP boxes, method cards
  static const double md = 18;
  static const double base = 20; // 1.25rem
  static const double lg = 24; // rounded-3xl / rounded-[1.5rem] — cards
  static const double xl = 28;
  static const double xxl = 44; // base + 24
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius control = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// Spacing. Tailwind's 4px step, with the named values the mockups actually use.
abstract final class SNSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;

  static const double screenX = 24; // px-6 — every screen gutter
  static const double section = 32; // mb-8 — between scroll sections
  static const double formSection = 40; // space-y-10 — between form sections
  static const double cardGap = 20; // gap-5 — horizontal scrollers
  static const double navClear = 128; // pb-32 — bottom nav clearance
  static const double appBarTop = 48; // pt-12
  static const double minTapTarget = 44;
}

/// Named sizes that recur across the mockups and must not drift per screen.
abstract final class SNSize {
  static const double avatarSm = 40;
  static const double avatarMd = 48; // home header
  static const double circleButton = 40; // h-10 w-10 app bar / header actions
  static const double sendButton = 44; // h-11 w-11 chat composer
  static const double momentIcon = 96; // h-24 w-24 moment-screen tile
  static const double iconTile = 56; // bg-muted p-4 rounded-2xl
  static const double otpBoxW = 48;
  static const double otpBoxH = 56;
  static const double featuredCardW = 288;
  static const double featuredCardImageH = 192;
}

/// Elevation. Subtle everywhere; the only strong shadow is on primary buttons
/// and the splash logo, and it is tinted with the primary colour.
abstract final class SNShadow {
  static List<BoxShadow> card(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// shadow-xl shadow-primary/20 — primary buttons, moment-screen icon tiles.
  static List<BoxShadow> tinted(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Motion. One place, so nothing improvises a duration.
abstract final class SNMotion {
  static const fast = Duration(milliseconds: 120); // active:scale-95
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 2000); // payment-pending pulse
  static const curve = Curves.easeOutCubic;
  static const pulseCurve = Curves.easeInOut;
}
