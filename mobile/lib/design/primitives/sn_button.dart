// design/primitives/sn_button.dart

import 'package:flutter/material.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

enum SNButtonVariant {
  /// Full-width, primary fill, tinted shadow. One per screen — the thing you
  /// want the user to do.
  primary,

  /// Muted fill. The alternative action.
  secondary,

  /// No fill, primary text. Tertiary actions and inline links.
  ghost,

  /// Ghost with destructive text. Cancel booking, delete, decline.
  destructive,
}

enum SNButtonSize { regular, compact }

/// The only button in the app.
///
/// Loading is a first-class state, not something a caller wraps. While loading
/// the button keeps its exact width — no layout jump — and blocks taps.
class SNButton extends StatefulWidget {
  const SNButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SNButtonVariant.primary,
    this.size = SNButtonSize.regular,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.fullWidth = true,
  });

  const SNButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SNButtonSize.regular,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.fullWidth = true,
  }) : variant = SNButtonVariant.secondary;

  const SNButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SNButtonSize.compact,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.fullWidth = false,
  }) : variant = SNButtonVariant.ghost;

  const SNButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SNButtonSize.compact,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.fullWidth = false,
  }) : variant = SNButtonVariant.destructive;

  final String label;

  /// Null disables the button. There is no separate `enabled` flag — a button
  /// with nothing to do is disabled by construction.
  final VoidCallback? onPressed;

  final SNButtonVariant variant;
  final SNButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool fullWidth;

  @override
  State<SNButton> createState() => _SNButtonState();
}

class _SNButtonState extends State<SNButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final v = widget.variant;

    final Color fill = switch (v) {
      SNButtonVariant.primary => c.primary,
      SNButtonVariant.secondary => c.muted,
      SNButtonVariant.ghost || SNButtonVariant.destructive => Colors.transparent,
    };

    final Color content = switch (v) {
      SNButtonVariant.primary => c.primaryForeground,
      SNButtonVariant.secondary => c.foreground,
      SNButtonVariant.ghost => c.primary,
      SNButtonVariant.destructive => c.destructive,
    };

    final style = switch (widget.size) {
      SNButtonSize.regular => v == SNButtonVariant.primary
          ? SNText.bodyLg.copyWith(fontWeight: SNWeight.bold)
          : SNText.bodyBold,
      SNButtonSize.compact => SNText.bodyBold,
    };

    final verticalPad =
        widget.size == SNButtonSize.regular ? SNSpace.x4 : SNSpace.x3;

    // Disabled reads as reduced opacity rather than a different colour, so the
    // button's identity stays legible.
    final opacity = _disabled && !widget.isLoading ? 0.4 : 1.0;

    Widget child = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(content),
            ),
          )
        : Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: content),
                const SizedBox(width: SNSpace.x2),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: style.copyWith(color: content),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: SNSpace.x2),
                Icon(widget.trailingIcon, size: 20, color: content),
              ],
            ],
          );

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
        onTap: _disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: SNMotion.fast,
          curve: SNMotion.curve,
          child: Opacity(
            opacity: opacity,
            child: AnimatedContainer(
              duration: SNMotion.base,
              width: widget.fullWidth ? double.infinity : null,
              constraints: const BoxConstraints(
                minHeight: SNSpace.minTapTarget,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: SNSpace.x6,
                vertical: verticalPad,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: SNRadius.control,
                boxShadow: v == SNButtonVariant.primary && !_disabled
                    ? SNShadow.tinted(c.primary)
                    : null,
              ),
              child: Center(
                widthFactor: widget.fullWidth ? null : 1,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
