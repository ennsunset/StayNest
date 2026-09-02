// features/discovery/presentation/advanced_filters_sheet.dart
//
// Screen 13 — Advanced Filters.
// Bottom sheet: price range slider, room type, amenities, distance to campus,
// Reset, "Show N Results" with live count on debounce.
//
// Called via showAdvancedFilters(context) — not a route.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

/// Show the filter sheet. Returns the applied filters, or null if dismissed.
Future<HostelFilters?> showAdvancedFilters(
  BuildContext context, {
  HostelFilters? current,
  HostelsRepository? repo,
  String? university,
}) {
  return showModalBottomSheet<HostelFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _AdvancedFiltersSheet(initial: current, repo: repo, university: university),
  );
}

// ── Filter data model ───────────────────────────────

class HostelFilters {
  const HostelFilters({
    this.minPricePesewas = 100000,
    this.maxPricePesewas = 800000,
    this.roomType,
    this.amenities = const {},
    this.distance,
  });

  final int minPricePesewas;
  final int maxPricePesewas;
  final String? roomType;
  final Set<String> amenities;
  final String? distance;

  static const defaultMin = 100000; // GH₵1,000
  static const defaultMax = 800000; // GH₵8,000

  HostelFilters copyWith({
    int? minPricePesewas,
    int? maxPricePesewas,
    String? roomType,
    Set<String>? amenities,
    String? distance,
  }) {
    return HostelFilters(
      minPricePesewas: minPricePesewas ?? this.minPricePesewas,
      maxPricePesewas: maxPricePesewas ?? this.maxPricePesewas,
      roomType: roomType ?? this.roomType,
      amenities: amenities ?? this.amenities,
      distance: distance ?? this.distance,
    );
  }

  bool get isDefault =>
      minPricePesewas == defaultMin &&
      maxPricePesewas == defaultMax &&
      roomType == null &&
      amenities.isEmpty &&
      distance == null;
}

// ── Sheet widget ────────────────────────────────────

class _AdvancedFiltersSheet extends StatefulWidget {
  const _AdvancedFiltersSheet({this.initial, this.repo, this.university});
  final HostelFilters? initial;
  final HostelsRepository? repo;
  final String? university;

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late HostelFilters _filters;
  int _resultCount = 0;
  bool _counting = false;
  Timer? _debounce;

  static const _roomTypes = [
    '1-in-a-room',
    '2-in-a-room',
    '3-in-a-room',
    '4-in-a-room',
  ];

  static const _amenities = [
    'WiFi',
    'Backup Power',
    'AC',
    'Security',
    'Laundry',
    'Water Supply',
    'Study Room',
    'Kitchen',
  ];

  static const _distances = [
    'Under 0.5 km',
    'Under 1 km',
    'Under 1.5 km',
    'Any distance',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initial ?? const HostelFilters();
    _fetchCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetchCount);
  }

  Future<void> _fetchCount() async {
    setState(() => _counting = true);
    try {
      final repo = widget.repo;
      if (repo == null) {
        // Fallback: just show "Show Results" without count
        if (mounted) setState(() { _resultCount = 0; _counting = false; });
        return;
      }
      final count = await repo.searchCount(
        minPricePesewas: _filters.minPricePesewas != HostelFilters.defaultMin ? _filters.minPricePesewas : null,
        maxPricePesewas: _filters.maxPricePesewas != HostelFilters.defaultMax ? _filters.maxPricePesewas : null,
        roomType: _filters.roomType,
        amenities: _filters.amenities.isNotEmpty ? _filters.amenities.toList() : null,
        university: widget.university,
      );
      if (mounted) setState(() { _resultCount = count; _counting = false; });
    } catch (_) {
      if (mounted) setState(() { _resultCount = 0; _counting = false; });
    }
  }

  void _reset() {
    setState(() => _filters = const HostelFilters());
    _onFilterChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SNRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle + header ──────────────────────
          _buildHeader(c),

          // ── Scrollable filters ───────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                SNSpace.screenX, 0, SNSpace.screenX, SNSpace.x4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRange(c),
                  const SizedBox(height: SNSpace.section),
                  _buildRoomType(c),
                  const SizedBox(height: SNSpace.section),
                  _buildAmenities(c),
                  const SizedBox(height: SNSpace.section),
                  _buildDistance(c),
                  const SizedBox(height: SNSpace.section),
                ],
              ),
            ),
          ),

          // ── Sticky footer ───────────────────────
          _buildFooter(c),
        ],
      ),
    );
  }

  Widget _buildHeader(SNColorTokens c) {
    return Column(
      children: [
        const SNSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SNSpace.screenX, SNSpace.x2, SNSpace.screenX, SNSpace.x3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FILTERS',
                style: SNText.appBarTitle.copyWith(color: c.foreground),
              ),
              if (!_filters.isDefault)
                GestureDetector(
                  onTap: _reset,
                  child: Text(
                    'RESET',
                    style: SNText.microAction.copyWith(color: c.primary),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: c.border),
      ],
    );
  }

  // ── Price range ───────────────────────────────────

  Widget _buildPriceRange(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SNSpace.x5),
        SNSectionLabel('Price Range'),
        const SizedBox(height: SNSpace.x4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Money.format(_filters.minPricePesewas),
              style: SNText.bodyBold.copyWith(color: c.foreground),
            ),
            Text(
              Money.format(_filters.maxPricePesewas),
              style: SNText.bodyBold.copyWith(color: c.foreground),
            ),
          ],
        ),
        const SizedBox(height: SNSpace.x2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: c.primary,
            inactiveTrackColor: c.muted,
            thumbColor: c.primary,
            overlayColor: c.primary.withValues(alpha: 0.1),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: RangeSlider(
            min: HostelFilters.defaultMin.toDouble(),
            max: HostelFilters.defaultMax.toDouble(),
            divisions: 14,
            values: RangeValues(
              _filters.minPricePesewas.toDouble(),
              _filters.maxPricePesewas.toDouble(),
            ),
            onChanged: (v) {
              setState(() {
                _filters = _filters.copyWith(
                  minPricePesewas: v.start.round(),
                  maxPricePesewas: v.end.round(),
                );
              });
              _onFilterChanged();
            },
          ),
        ),
      ],
    );
  }

  // ── Room type ─────────────────────────────────────

  Widget _buildRoomType(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SNSectionLabel('Room Type'),
        const SizedBox(height: SNSpace.x4),
        Wrap(
          spacing: SNSpace.x3,
          runSpacing: SNSpace.x3,
          children: _roomTypes.map((t) {
            final selected = _filters.roomType == t;
            return SNChip(
              label: t,
              selected: selected,
              onTap: () {
                setState(() {
                  _filters = _filters.copyWith(
                    roomType: selected ? null : t,
                  );
                });
                _onFilterChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Amenities ─────────────────────────────────────

  Widget _buildAmenities(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SNSectionLabel('Essential Amenities'),
        const SizedBox(height: SNSpace.x4),
        Wrap(
          spacing: SNSpace.x3,
          runSpacing: SNSpace.x3,
          children: _amenities.map((a) {
            final selected = _filters.amenities.contains(a);
            return SNChip(
              label: a,
              selected: selected,
              onTap: () {
                final updated = Set<String>.from(_filters.amenities);
                selected ? updated.remove(a) : updated.add(a);
                setState(() {
                  _filters = _filters.copyWith(amenities: updated);
                });
                _onFilterChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Distance ──────────────────────────────────────

  Widget _buildDistance(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SNSectionLabel('Distance to Campus'),
        const SizedBox(height: SNSpace.x4),
        Wrap(
          spacing: SNSpace.x3,
          runSpacing: SNSpace.x3,
          children: _distances.map((d) {
            final selected = _filters.distance == d;
            return SNChip(
              label: d,
              selected: selected,
              onTap: () {
                setState(() {
                  _filters = _filters.copyWith(
                    distance: selected ? null : d,
                  );
                });
                _onFilterChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Footer with live count ────────────────────────

  Widget _buildFooter(SNColorTokens c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x4,
      ),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SNButton(
          label: _counting
              ? 'Counting...'
              : 'Show $_resultCount Results',
          onPressed: _resultCount > 0
              ? () => Navigator.pop(context, _filters)
              : null,
          isLoading: _counting,
        ),
      ),
    );
  }
}
