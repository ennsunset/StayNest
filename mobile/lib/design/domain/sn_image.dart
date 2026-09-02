// design/domain/sn_image.dart
//
// Every network image in this app goes through here. Not a call site, a
// component. There are hundreds of images in this product and half your users
// are on 3G.
//
// Three jobs:
//   1. Request the right size variant. The media pipeline produces small /
//      medium / large WebP on upload — a grid thumbnail must never pull a 4MB
//      original.
//   2. Skeleton while loading, muted block on failure. Never a broken-image
//      glyph, never a layout jump.
//   3. Bounded memory cache, so a gallery scroll doesn't OOM a mid-range phone.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';

enum SNImageVariant {
  /// ~200px wide. Grid thumbnails, list rows, avatars in cards.
  small,

  /// ~600px wide. Featured cards, hero strips on detail screens.
  medium,

  /// Full width. Full-screen gallery pager only.
  large,
}

class SNImage extends StatelessWidget {
  const SNImage({
    super.key,
    required this.url,
    this.variant = SNImageVariant.medium,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  /// Square thumbnail — the 64×64 summary card image in Booking Review, the
  /// 120px hero strip in Booking Detail.
  const SNImage.thumb({
    super.key,
    required this.url,
    double size = 64,
    this.borderRadius = SNRadius.control,
  })  : variant = SNImageVariant.small,
        width = size,
        height = size,
        fit = BoxFit.cover;

  final String? url;
  final SNImageVariant variant;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  /// The media pipeline stores variants as a suffix. Keep this in one place so
  /// changing the convention is a one-line change, not a search-and-replace.
  String _resolve(String base) {
    final suffix = switch (variant) {
      SNImageVariant.small => '_sm',
      SNImageVariant.medium => '_md',
      SNImageVariant.large => '_lg',
    };
    final dot = base.lastIndexOf('.');
    if (dot <= 0) return base;
    return '${base.substring(0, dot)}$suffix.webp';
  }

  int? _cacheWidth(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logical = (width != null && width!.isFinite)
        ? width!
        : switch (variant) {
            SNImageVariant.small => 200.0,
            SNImageVariant.medium => 600.0,
            SNImageVariant.large => MediaQuery.sizeOf(context).width,
          };
    return (logical * dpr).round();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final radius = borderRadius ?? BorderRadius.zero;

    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: _Placeholder(width: width, height: height, color: c.muted),
      );
    }

    final resolved = _resolve(url!);
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: _cacheWidth(context),
        fadeInDuration: SNMotion.base,
        placeholder: (_, __) => SNSkeleton(
          width: width ?? double.infinity,
          height: height ?? 160,
          radius: 0,
        ),
        errorWidget: (_, __, ___) =>
            _Placeholder(width: width, height: height, color: c.muted),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height, required this.color});

  final double? width;
  final double? height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 24,
        color: context.sn.mutedForeground.withValues(alpha: 0.5),
      ),
    );
  }
}
