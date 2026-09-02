// core/theme/typography.dart
//
// Plus Jakarta Sans for everything. JetBrains Mono for machine strings only —
// booking references, payment references, countdown digits. Nothing else.
//
// Both are bundled as app assets. Never a network font: a font pop on splash
// reads as a broken app on a slow connection.
//
// pubspec.yaml:
//   fonts:
//     - family: PlusJakartaSans
//       fonts:
//         - asset: assets/fonts/PlusJakartaSans-Regular.ttf   # 400
//         - asset: assets/fonts/PlusJakartaSans-Medium.ttf    # 500
//         - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf  # 600
//         - asset: assets/fonts/PlusJakartaSans-Bold.ttf      # 700
//         - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf # 800
//     - family: JetBrainsMono
//       fonts:
//         - asset: assets/fonts/JetBrainsMono-Regular.ttf     # 400
//         - asset: assets/fonts/JetBrainsMono-Medium.ttf      # 500

import 'package:flutter/widgets.dart';

abstract final class SNFont {
  static const sans = 'PlusJakartaSans';
  static const mono = 'JetBrainsMono';
}

/// Weight names match the Tailwind classes in the mockups so a spec that says
/// `font-black` maps to exactly one thing here.
abstract final class SNWeight {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const black = FontWeight.w800; // font-black — the heading weight
}

/// The type scale, named by role rather than by size. A screen spec never picks
/// a font size; it picks a role.
abstract final class SNText {
  static const _sans = SNFont.sans;

  /// text-4xl — amount heroes, splash. One per screen, at most.
  static const displayLg = TextStyle(
    fontFamily: _sans,
    fontSize: 36,
    height: 1.1,
    fontWeight: SNWeight.black,
    letterSpacing: -0.8,
  );

  /// text-3xl — moment-screen headlines, auth headlines.
  static const displayMd = TextStyle(
    fontFamily: _sans,
    fontSize: 30,
    height: 1.15,
    fontWeight: SNWeight.bold,
    letterSpacing: -0.6,
  );

  /// text-xl — section headings, totals.
  static const headingLg = TextStyle(
    fontFamily: _sans,
    fontSize: 20,
    height: 1.25,
    fontWeight: SNWeight.bold,
    letterSpacing: -0.3,
  );

  /// text-lg — card titles, app bar titles.
  static const headingMd = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    height: 1.3,
    fontWeight: SNWeight.bold,
    letterSpacing: -0.2,
  );

  /// text-base — primary button labels.
  static const bodyLg = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.4,
    fontWeight: SNWeight.medium,
  );

  /// text-sm — the workhorse. Body copy, list rows, secondary buttons.
  static const body = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.5,
    fontWeight: SNWeight.regular,
  );

  static const bodyBold = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.5,
    fontWeight: SNWeight.semibold,
  );

  /// text-xs — labels, captions, helper text.
  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    height: 1.4,
    fontWeight: SNWeight.medium,
  );

  /// text-[10px] font-black uppercase tracking-[0.2em]
  /// The signature of this design system. Used for every section label.
  static const sectionLabel = TextStyle(
    fontFamily: _sans,
    fontSize: 10,
    height: 1.2,
    fontWeight: SNWeight.black,
    letterSpacing: 2.0, // 0.2em at 10px
  );

  /// text-[10px] font-black uppercase tracking-widest — the primary-coloured
  /// twin of sectionLabel, used for values, trailing actions and links.
  static const microAction = TextStyle(
    fontFamily: _sans,
    fontSize: 10,
    height: 1.2,
    fontWeight: SNWeight.black,
    letterSpacing: 1.2,
  );

  /// App bar title: text-lg font-black uppercase tracking-wider.
  static const appBarTitle = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    height: 1.2,
    fontWeight: SNWeight.black,
    letterSpacing: 1.0,
  );

  // ── Mono: machine strings only ────────────────────────────────────────

  /// Booking and payment references. STN-2026-X8R2.
  static const mono = TextStyle(
    fontFamily: SNFont.mono,
    fontSize: 14,
    height: 1.4,
    fontWeight: SNWeight.medium,
    letterSpacing: 0.5,
  );

  /// Countdown digits — tabular so the pill doesn't jitter each second.
  static const monoDigits = TextStyle(
    fontFamily: SNFont.mono,
    fontSize: 13,
    height: 1.2,
    fontWeight: SNWeight.medium,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// OTP boxes: text-2xl font-black.
  static const otpDigit = TextStyle(
    fontFamily: _sans,
    fontSize: 24,
    height: 1.0,
    fontWeight: SNWeight.black,
  );
}
