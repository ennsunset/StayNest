// design/layout/sn_scaffold.dart
//
// The page shell. Every screen is either:
//   1. SNScaffold with a bottom nav (tabbed shells)
//   2. A plain Scaffold with SNAppBar (pushed routes)
//
// SNAppBar matches the mockups exactly: circular 40px back button on muted,
// centred uppercase title, optional trailing action.

import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

/// The app bar from `advanced-filters`, `room-details`, `select-bed`.
///
/// On imagery (hostel hero, gallery): pass [onImage] = true for the
/// `bg-white/20 backdrop-blur` glass treatment.
class SNAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SNAppBar({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.onImage = false,
    this.bottom,
  });

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool onImage;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        72 + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Container(
      decoration: onImage
          ? null
          : BoxDecoration(
              color: c.card,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SNSpace.screenX,
                vertical: SNSpace.x3,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SNSize.circleButton + SNSpace.x3),
                      child: Text(
                        title!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SNText.appBarTitle.copyWith(color: c.foreground),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (onBack != null)
                        _CircleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: onBack!,
                          glass: onImage,
                        )
                      else
                        const SizedBox(width: SNSize.circleButton),
                      if (trailing != null)
                        trailing!
                      else
                        const SizedBox(width: SNSize.circleButton),
                    ],
                  ),
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

/// The 40×40 circular button used in app bars and the Home header.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.glass = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: SNSize.circleButton,
        width: SNSize.circleButton,
        decoration: BoxDecoration(
          color: glass ? c.glassFill : c.muted,
          shape: BoxShape.circle,
          border: glass ? Border.all(color: c.glassBorder) : null,
        ),
        child: Icon(icon, size: 20, color: glass ? Colors.white : c.foreground),
      ),
    );
  }
}

/// Exposes _CircleButton for the Home header's notification + AI buttons.
class SNCircleButton extends StatelessWidget {
  const SNCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: SNSize.circleButton,
            width: SNSize.circleButton,
            decoration: BoxDecoration(
              color: filled ? c.primary : c.card,
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: c.border),
            ),
            child: Icon(
              icon,
              size: 20,
              color: filled ? c.primaryForeground : c.foreground,
            ),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                height: 18,
                width: 18,
                decoration: BoxDecoration(
                  color: c.destructive,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 2),
                ),
                child: Center(
                  child: Text(
                    badge! > 9 ? '9+' : '$badge',
                    style: SNText.microAction.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bold title + "See all" in primary. The section divider on every scroll page.
class SNSectionHeader extends StatelessWidget {
  const SNSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: SNText.headingLg.copyWith(color: c.foreground)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: SNText.bodyBold.copyWith(color: c.primary),
              ),
            ),
        ],
      ),
    );
  }
}
