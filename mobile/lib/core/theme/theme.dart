// core/theme/theme.dart
//
// Assembles ThemeData from the tokens. Two jobs:
//   1. Register SNColorTokens as a ThemeExtension so components can read it.
//   2. Bend Material's own defaults to the tokens, so any stock widget that
//      slips through (a Dialog, a Snackbar, a stray TextField) still looks like
//      StayNest rather than like Flutter.
//
// Adding dark mode later = add SNColorTokens.dark in tokens.dart, add
// `snDarkTheme` here, set themeMode on MaterialApp. No screen changes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';
import 'typography.dart';

/// Read tokens anywhere: `context.sn.primary`.
///
/// This is the ONLY approved way to get a colour. There are no colour literals
/// outside tokens.dart — enforce it with a lint rule on hex strings.
extension SNThemeContext on BuildContext {
  SNColorTokens get sn =>
      Theme.of(this).extension<SNColorTokens>() ?? SNColorTokens.light;

  /// Convenience for the two most-used derived values.
  TextTheme get text => Theme.of(this).textTheme;
}

ThemeData buildSNTheme(SNColorTokens c) {
  final scheme = ColorScheme(
    brightness:
        ThemeData.estimateBrightnessForColor(c.background) == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
    primary: c.primary,
    onPrimary: c.primaryForeground,
    secondary: c.secondary,
    onSecondary: c.secondaryForeground,
    error: c.destructive,
    onError: Colors.white,
    surface: c.card,
    onSurface: c.cardForeground,
    surfaceContainerHighest: c.muted,
    outline: c.border,
    outlineVariant: c.border,
    shadow: c.shadowTint,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    fontFamily: SNFont.sans,
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[c],

    textTheme: base.textTheme
        .copyWith(
          displayLarge: SNText.displayLg,
          displayMedium: SNText.displayMd,
          headlineMedium: SNText.headingLg,
          titleLarge: SNText.headingMd,
          bodyLarge: SNText.bodyLg,
          bodyMedium: SNText.body,
          bodySmall: SNText.caption,
          labelSmall: SNText.sectionLabel,
        )
        .apply(
          bodyColor: c.foreground,
          displayColor: c.foreground,
        ),

    // App bars are built by SNAppBar, not Material's. This exists only so a
    // stock AppBar in a debug route doesn't look alien.
    appBarTheme: AppBarTheme(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: SNText.appBarTitle.copyWith(color: c.foreground),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    cardTheme: CardThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: SNRadius.card,
        side: BorderSide(color: c.border),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: c.border,
      thickness: 1,
      space: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.input,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SNSpace.x4,
        vertical: SNSpace.x4,
      ),
      hintStyle: SNText.body.copyWith(color: c.mutedForeground),
      labelStyle: SNText.caption.copyWith(color: c.mutedForeground),
      errorStyle: SNText.caption.copyWith(color: c.destructive),
      border: OutlineInputBorder(
        borderRadius: SNRadius.control,
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SNRadius.control,
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SNRadius.control,
        borderSide: BorderSide(color: c.ring, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: SNRadius.control,
        borderSide: BorderSide(color: c.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: SNRadius.control,
        borderSide: BorderSide(color: c.destructive, width: 2),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.popover,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: SNRadius.sheet),
      showDragHandle: false,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: c.popover,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: SNRadius.card),
      titleTextStyle: SNText.headingMd.copyWith(color: c.foreground),
      contentTextStyle: SNText.body.copyWith(color: c.mutedForeground),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.foreground,
      contentTextStyle: SNText.body.copyWith(color: c.background),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: SNRadius.control),
      elevation: 0,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: c.card,
      selectedColor: c.primary,
      side: BorderSide(color: c.border),
      labelStyle: SNText.caption.copyWith(color: c.foreground),
      secondaryLabelStyle: SNText.caption.copyWith(color: c.primaryForeground),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(
        horizontal: SNSpace.x4,
        vertical: SNSpace.x2,
      ),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.primary,
      linearTrackColor: c.muted,
      circularTrackColor: c.muted,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : c.card,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.primary : c.muted,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(c.primaryForeground),
      side: BorderSide(color: c.border, width: 2),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(SNRadius.xs / 2)),
    ),

    // Tap targets are never below 44px anywhere in this app.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
}

final ThemeData snLightTheme = buildSNTheme(SNColorTokens.light);
