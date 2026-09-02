// features/discovery/presentation/search_results_screen.dart
//
// Screen 12 — Search Results. Wired to real API.
// Result count, sort, vertical list of hostel cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';
import 'package:staynest_mobile/features/discovery/presentation/advanced_filters_sheet.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

/// Search results provider — fetches from API with sort param and filters.
final _searchResultsProvider = FutureProvider.family<List<Hostel>, String>((ref, sort) async {
  final repo = ref.read(hostelsRepositoryProvider);
  return repo.search(page: 1, limit: 50);
});

/// Maps UI sort labels to backend sort param values.
String? _sortKeyFromLabel(String label) {
  switch (label) {
    case 'Price: Low\u2013High':
      return 'price_asc';
    case 'Price: High\u2013Low':
      return 'price_desc';
    case 'Newest':
      return 'newest';
    default:
      return null;
  }
}

final _filteredSearchProvider = FutureProvider.family<List<Hostel>, ({String sort, String? query, HostelFilters? filters})>((ref, args) async {
  final repo = ref.read(hostelsRepositoryProvider);
  final sortKey = _sortKeyFromLabel(args.sort);
  final f = args.filters;
  if (f == null) {
    return repo.searchFiltered(page: 1, limit: 50, query: args.query, sort: sortKey);
  }
  return repo.searchFiltered(
    page: 1,
    limit: 50,
    query: args.query,
    sort: sortKey,
    minPricePesewas: f.minPricePesewas != HostelFilters.defaultMin ? f.minPricePesewas : null,
    maxPricePesewas: f.maxPricePesewas != HostelFilters.defaultMax ? f.maxPricePesewas : null,
    roomType: f.roomType,
    amenities: f.amenities.isNotEmpty ? f.amenities.toList() : null,
  );
});

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, this.query});

  final String? query;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  String _sortLabel = 'Price: Low–High';
  HostelFilters? _filters;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final resultsAsync = ref.watch(_filteredSearchProvider((
      sort: _sortLabel,
      query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : widget.query,
      filters: _filters,
    )));

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.foreground),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: widget.query == null || widget.query!.isEmpty,
          style: SNText.body.copyWith(color: c.foreground),
          decoration: InputDecoration(
            hintText: 'Search hostels, schools...',
            hintStyle: SNText.body.copyWith(color: c.mutedForeground),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: c.foreground),
            onPressed: () async {
            final filters = await showAdvancedFilters(context, current: _filters, repo: ref.read(hostelsRepositoryProvider));
            if (filters != null) {
              setState(() => _filters = filters);
            }
            },
          ),
        ],
      ),
      body: resultsAsync.when(
        loading: () => _buildSkeleton(c),
        error: (e, _) => Center(
          child: SNErrorState(
            headline: 'Something went wrong',
            onRetry: () => ref.invalidate(_searchResultsProvider(_sortLabel)),
          ),
        ),
        data: (results) {
          if (results.isEmpty) return _buildEmpty(c);
          return _buildList(c, results);
        },
      ),
    );
  }

  Widget _buildList(SNColorTokens c, List<Hostel> results) {
    return Column(
      children: [
        // Result count + sort
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SNSpace.screenX,
            vertical: SNSpace.x4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${results.length} Hostels Found',
                    style: SNText.headingMd.copyWith(color: c.foreground),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showSortSheet,
                child: Row(
                  children: [
                    Icon(Icons.swap_vert_rounded, size: 18, color: c.primary),
                    const SizedBox(width: SNSpace.x1),
                    Text(
                      _sortLabel,
                      style: SNText.caption.copyWith(color: c.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              SNSpace.screenX, 0, SNSpace.screenX, SNSpace.navClear,
            ),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x4),
            itemBuilder: (_, i) {
              final h = results[i];
              return HostelCard.list(
                name: h.name,
                location: h.address,
                imageUrl: h.imageUrls.isNotEmpty ? h.imageUrls.first : null,
                fromPricePesewas: h.fromPricePesewas,
                rating: h.averageRating,
                reviewCount: h.reviewCount,
                verified: h.verified,
                amenities: h.amenities
                    .take(3)
                    .map((a) => AmenityChip(
                          label: a.name,
                          icon: _amenityIcon(a.name),
                        ))
                    .toList(),
                onTap: () {
                  context.push('/home/hostel/${h.id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(SNColorTokens c) {
    return Center(
      child: SNEmptyState(
        icon: Icons.search_off_rounded,
        headline: 'No hostels found',
        actionLabel: 'Clear filters',
        onAction: () {
          ref.invalidate(_searchResultsProvider(_sortLabel));
        },
      ),
    );
  }

  Widget _buildSkeleton(SNColorTokens c) {
    return ListView.separated(
      padding: const EdgeInsets.all(SNSpace.screenX),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x4),
      itemBuilder: (_, __) => const SNSkeleton(
        height: 120,
        radius: SNRadius.lg,
      ),
    );
  }

  void _showSortSheet() {
    final options = [
      'Price: Low–High',
      'Price: High–Low',
      'Rating',
      'Distance',
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: context.sn.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SNRadius.lg),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SNSheetHandle(),
            const SizedBox(height: SNSpace.x4),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.sn.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: SNSpace.x5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
              child: Text(
                'SORT BY',
                style: SNText.sectionLabel.copyWith(
                  color: context.sn.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: SNSpace.x3),
            ...options.map((o) => ListTile(
                  title: Text(
                    o,
                    style: SNText.body.copyWith(
                      color: o == _sortLabel
                          ? context.sn.primary
                          : context.sn.foreground,
                      fontWeight:
                          o == _sortLabel ? SNWeight.bold : SNWeight.regular,
                    ),
                  ),
                  trailing: o == _sortLabel
                      ? Icon(Icons.check_rounded,
                          color: context.sn.primary, size: 20)
                      : null,
                  onTap: () {
                    setState(() => _sortLabel = o);
                    Navigator.pop(context);
                    ref.invalidate(_searchResultsProvider(_sortLabel));
                  },
                )),
            const SizedBox(height: SNSpace.x4),
          ],
        ),
      ),
    );
  }

  IconData _amenityIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('power') || lower.contains('generator') || lower.contains('backup')) return Icons.bolt_rounded;
    if (lower.contains('security')) return Icons.shield_outlined;
    if (lower.contains('laundry')) return Icons.local_laundry_service_outlined;
    if (lower.contains('ac') || lower.contains('air conditioning')) return Icons.ac_unit_rounded;
    if (lower.contains('water')) return Icons.water_drop_outlined;
    return Icons.check_circle_outline;
  }
}
