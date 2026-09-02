// design/domain/sn_domain_cards.dart

import 'package:flutter/material.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'sn_domain_bits.dart';
import 'sn_image.dart';

/// Two variants, one widget. Featured is the 288px horizontal scroller card on
/// Home; list is the horizontal row used in Search Results and Saved.
class HostelCard extends StatelessWidget {
  const HostelCard.featured({
    super.key,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.fromPricePesewas,
    required this.onTap,
    this.rating,
    this.reviewCount,
    this.verified = false,
    this.amenities = const [],
    this.saved,
    this.onToggleSave,
  }) : _list = false;

  const HostelCard.list({
    super.key,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.fromPricePesewas,
    required this.onTap,
    this.rating,
    this.reviewCount,
    this.verified = false,
    this.amenities = const [],
    this.saved,
    this.onToggleSave,
  }) : _list = true;

  final bool _list;
  final String name;

  /// Distance line — "Near North Campus", not a street address.
  final String location;
  final String? imageUrl;
  final int fromPricePesewas;
  final double? rating;
  final int? reviewCount;
  final bool verified;
  final List<AmenityChip> amenities;
  final bool? saved;
  final VoidCallback? onToggleSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _list ? _buildList(context) : _buildFeatured(context);
  }

  Widget _buildFeatured(BuildContext context) {
    final c = context.sn;
    return SizedBox(
      width: SNSize.featuredCardW,
      child: SNCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SNImage(
                  url: imageUrl,
                  height: SNSize.featuredCardImageH,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SNRadius.lg),
                  ),
                ),
                if (verified)
                  const Positioned(
                    top: SNSpace.x3,
                    right: SNSpace.x3,
                    child: VerifiedBadge(),
                  ),
                if (onToggleSave != null)
                  Positioned(
                    bottom: SNSpace.x3,
                    right: SNSpace.x3,
                    child: _SaveButton(
                      saved: saved ?? false,
                      onTap: onToggleSave!,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(SNSpace.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SNText.headingMd.copyWith(color: c.foreground),
                        ),
                      ),
                      if (rating != null)
                        RatingStars(rating: rating!, reviewCount: reviewCount),
                    ],
                  ),
                  const SizedBox(height: SNSpace.x1),
                  _locationLine(c),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: SNSpace.x3),
                    child: Divider(height: 1, color: c.border.withValues(alpha: 0.5)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STARTS FROM', style: SNText.microAction.copyWith(color: c.mutedForeground, fontSize: 9, letterSpacing: 1.5)),
                          const SizedBox(height: 2),
                          Text(
                            Money.formatCompact(fromPricePesewas),
                            style: SNText.headingMd.copyWith(color: c.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final c = context.sn;
    return SNCard(
      padding: const EdgeInsets.all(SNSpace.x3),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SNImage(
                url: imageUrl,
                variant: SNImageVariant.small,
                width: 104,
                height: 104,
                borderRadius: SNRadius.control,
              ),
              if (verified)
                const Positioned(
                  top: SNSpace.x1 + 2,
                  right: SNSpace.x1 + 2,
                  child: VerifiedBadge(iconOnly: true),
                ),
            ],
          ),
          const SizedBox(width: SNSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SNText.headingMd.copyWith(color: c.foreground),
                      ),
                    ),
                    if (onToggleSave != null)
                      _SaveButton(
                        saved: saved ?? false,
                        onTap: onToggleSave!,
                        plain: true,
                      ),
                  ],
                ),
                const SizedBox(height: SNSpace.x1),
                _locationLine(c),
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: SNSpace.x2),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < amenities.take(3).length; i++) ...[
                          if (i > 0) const SizedBox(width: SNSpace.x2),
                          amenities.take(3).toList()[i],
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: SNSpace.x2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Money.formatCompact(fromPricePesewas),
                      style: SNText.headingMd.copyWith(color: c.foreground),
                    ),
                    if (rating != null)
                      RatingStars(rating: rating!, reviewCount: reviewCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationLine(SNColorTokens c) {
    return Row(
      children: [
        Icon(Icons.place_outlined, size: 12, color: c.mutedForeground),
        const SizedBox(width: SNSpace.x1),
        Expanded(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SNText.caption.copyWith(color: c.mutedForeground),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saved,
    required this.onTap,
    this.plain = false,
  });

  final bool saved;
  final VoidCallback onTap;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final icon = Icon(
      saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      size: 18,
      color: saved ? c.destructive : (plain ? c.mutedForeground : c.foreground),
    );

    return Semantics(
      button: true,
      label: saved ? 'Remove from saved' : 'Save hostel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: SNSpace.minTapTarget,
          height: SNSpace.minTapTarget,
          child: Center(
            child: plain
                ? icon
                : Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: c.card.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: icon),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Room type card on Hostel Details, and the room row in owner Room Management.
///
/// **`slotsLeft` is cached marketing, not truth.** It comes from a search cache
/// and may be stale. Availability is established at hold time under a row lock.
/// If the number is wrong, Bed Just Taken handles it gracefully.
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.title,
    required this.pricePesewas,
    required this.onTap,
    this.imageUrl,
    this.slotsLeft,
    this.tag,
    this.subtitle,
  });

  final String title;
  final int pricePesewas;
  final String? imageUrl;
  final int? slotsLeft;

  /// "PREMIUM UNIT", "VIRTUAL TOUR" — the small uppercase tag on imagery.
  final String? tag;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final scarce = slotsLeft != null && slotsLeft! <= 3;

    return SNCard(
      onTap: onTap,
      padding: const EdgeInsets.all(SNSpace.x4),
      child: Row(
        children: [
          if (imageUrl != null) ...[
            SNImage.thumb(url: imageUrl, size: 56),
            const SizedBox(width: SNSpace.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag != null) ...[
                  Text(
                    tag!.toUpperCase(),
                    style: SNText.microAction.copyWith(color: c.primary),
                  ),
                  const SizedBox(height: SNSpace.x1),
                ],
                Text(
                  title,
                  style: SNText.headingMd.copyWith(color: c.foreground),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
              ],
            ),
          ),
          const SizedBox(width: SNSpace.x3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.formatCompact(pricePesewas),
                style: SNText.headingMd.copyWith(color: c.foreground),
              ),
              if (slotsLeft != null) ...[
                const SizedBox(height: SNSpace.x1),
                SNBadge(
                  label: '$slotsLeft ${slotsLeft == 1 ? 'slot' : 'slots'} left',
                  tone: scarce ? SNStatusTone.warning : SNStatusTone.neutral,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One bed in the Select Bed grid, and the same geometry owner-side in Bed
/// Management.
///
/// Student side sees three visual states: available, selected, occupied.
/// Owner side sees the full [BedState] set via [showFullState].
class BedTile extends StatelessWidget {
  const BedTile({
    super.key,
    required this.label,
    required this.state,
    this.selected = false,
    this.onTap,
    this.showFullState = false,
  });

  /// "Bed A", "Bed 2".
  final String label;
  final BedState state;
  final bool selected;
  final VoidCallback? onTap;

  /// Owner-side: show the precise state badge rather than collapsing
  /// held/booked/occupied into a single "occupied" appearance.
  final bool showFullState;

  bool get _tappable => state == BedState.available && onTap != null;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    final Color fill;
    final Color content;
    final Color borderColor;

    if (selected) {
      fill = c.primary;
      content = c.primaryForeground;
      borderColor = c.primary;
    } else if (state == BedState.available) {
      fill = c.card;
      content = c.foreground;
      borderColor = c.border;
    } else {
      fill = c.muted;
      content = c.mutedForeground;
      borderColor = c.muted;
    }

    final statusText = showFullState
        ? state.label
        : state == BedState.available
            ? 'Available'
            : 'Occupied';

    return Semantics(
      button: _tappable,
      enabled: _tappable,
      selected: selected,
      label: '$label, $statusText',
      child: GestureDetector(
        onTap: _tappable || (showFullState && onTap != null) ? onTap : null,
        child: AnimatedContainer(
          duration: SNMotion.base,
          curve: SNMotion.curve,
          padding: const EdgeInsets.all(SNSpace.x4),
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: SNRadius.control,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: selected ? SNShadow.tinted(c.primary) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.bed_outlined, size: 22, color: content),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SNText.bodyBold.copyWith(color: content),
                  ),
                  const SizedBox(height: SNSpace.x1),
                  if (showFullState)
                    SNBadge.bed(state)
                  else
                    Text(
                      selected ? 'SELECTED' : statusText.toUpperCase(),
                      style: SNText.microAction.copyWith(
                        color: selected ? content : c.mutedForeground,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
