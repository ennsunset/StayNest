// design/primitives/sn_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

/// The only text field in the app.
///
/// The label above the field uses the section-label style — the signature of
/// this design system. Errors appear beneath and the border turns destructive;
/// the field never silently rejects input.
class SNInput extends StatefulWidget {
  const SNInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  /// A currency field. Accepts digits only and is labelled in GH₵.
  ///
  /// The value it produces is **pesewas as an integer** — see decision D1.
  /// Never parse a money field into a double.
  const SNInput.currency({
    super.key,
    this.label,
    this.hint = '0.00',
    this.controller,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
  })  : prefixIcon = null,
        suffix = null,
        obscure = false,
        keyboardType = TextInputType.number,
        inputFormatters = const [],
        maxLines = 1,
        autofillHints = null;

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<SNInput> createState() => _SNInputState();
}

class _SNInputState extends State<SNInput> {
  late bool _obscured = widget.obscure;
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final hasError = widget.errorText != null;

    final borderColor = hasError
        ? c.destructive
        : _focused
            ? c.ring
            : c.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: SNText.sectionLabel.copyWith(color: c.mutedForeground),
          ),
          const SizedBox(height: SNSpace.x2),
        ],
        AnimatedContainer(
          duration: SNMotion.base,
          curve: SNMotion.curve,
          decoration: BoxDecoration(
            color: widget.enabled ? c.input : c.muted,
            borderRadius: SNRadius.control,
            border: Border.all(
              color: borderColor,
              width: (_focused || hasError) ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: SNSpace.x4),
                  child: Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: _focused ? c.primary : c.mutedForeground,
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  obscureText: _obscured,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: c.primary,
                  style: SNText.body.copyWith(color: c.foreground),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: SNText.body.copyWith(color: c.mutedForeground),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: SNSpace.x4,
                      vertical: SNSpace.x4,
                    ),
                  ),
                ),
              ),
              if (widget.obscure)
                _IconAction(
                  icon: _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  semanticLabel: _obscured ? 'Show password' : 'Hide password',
                  onTap: () => setState(() => _obscured = !_obscured),
                )
              else if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: SNSpace.x3),
                  child: widget.suffix,
                ),
            ],
          ),
        ),
        if (hasError || widget.helperText != null) ...[
          const SizedBox(height: SNSpace.x2),
          Text(
            widget.errorText ?? widget.helperText!,
            style: SNText.caption.copyWith(
              color: hasError ? c.destructive : c.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: SNSpace.minTapTarget,
          height: SNSpace.minTapTarget,
          child: Icon(icon, size: 20, color: context.sn.mutedForeground),
        ),
      ),
    );
  }
}
