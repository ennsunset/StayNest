// features/discovery/presentation/explore_placeholder.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/features/discovery/presentation/advanced_filters_sheet.dart';
import 'package:staynest_mobile/features/discovery/presentation/explore_map_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:staynest_mobile/features/discovery/presentation/saved_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/search_history_screen.dart';

/// Filter config per pill
class _FilterDef {
  const _FilterDef(this.label, {this.maxPrice, this.genderPolicy, this.radiusKm});
  final String label;
  final int? maxPrice;
  final String? genderPolicy;
  final double? radiusKm;
}

const _filters = [
  _FilterDef('All'),
  _FilterDef('Under GH₵3k', maxPrice: 300000),
  _FilterDef('Women Only', genderPolicy: 'FEMALE'),
  _FilterDef('Men Only', genderPolicy: 'MALE'),
  _FilterDef('Mixed', genderPolicy: 'MIXED'),
];

final _exploreFilterIndex = StateProvider<int>((ref) => 0);
final _advancedFiltersProvider = StateProvider<HostelFilters?>((ref) => null);
final _searchQueryProvider = StateProvider<String>((ref) => '');
final _userLocationProvider = StateProvider<Position?>((ref) => null);

final _exploreProvider = FutureProvider<List<Hostel>>((ref) async {
  final idx = ref.watch(_exploreFilterIndex);
  final filter = _filters[idx];
  final repo = ref.read(hostelsRepositoryProvider);
  final user = ref.watch(authNotifierProvider);
  final pos = ref.watch(_userLocationProvider);
  final adv = ref.watch(_advancedFiltersProvider);
  final q = ref.watch(_searchQueryProvider);
  return repo.searchFiltered(
    page: 1,
    limit: 50,
    query: q.isNotEmpty ? q : null,
    maxPricePesewas: adv?.maxPricePesewas ?? filter.maxPrice,
    minPricePesewas: adv?.minPricePesewas,
    roomType: adv?.roomType,
    amenities: adv?.amenities.isNotEmpty == true ? adv!.amenities.toList() : null,
    genderPolicy: filter.genderPolicy,
    university: user?.university,
    lat: filter.radiusKm != null ? pos?.latitude : null,
    lng: filter.radiusKm != null ? pos?.longitude : null,
    radiusKm: filter.radiusKm,
    sort: filter.radiusKm != null ? 'distance' : null,
  );
});

void _openFullMap(BuildContext context, WidgetRef ref, List<Hostel> hostels) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => ExploreMapScreen(hostels: hostels)));
}

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _searchQuery = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final c = context.sn;
    final selectedFilter = ref.watch(_exploreFilterIndex);
    final hostelsAsync = ref.watch(_exploreProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + search + filter buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x4, SNSpace.screenX, 0),
              child: Text('Explore', style: SNText.headingLg.copyWith(color: c.foreground)),
            ),

            const SizedBox(height: SNSpace.x4),

            // Inline search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: c.muted,
                        borderRadius: BorderRadius.circular(SNRadius.md),
                        border: Border.all(color: c.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: SNText.body.copyWith(color: c.foreground),
                        decoration: InputDecoration(
                          hintText: 'Search hostels...',
                          hintStyle: SNText.body.copyWith(color: c.mutedForeground),
                          prefixIcon: Icon(Icons.search_rounded, color: c.mutedForeground, size: 20),
                          suffixIcon: ValueListenableBuilder<String>(
                            valueListenable: _searchQuery,
                            builder: (_, q, __) => q.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded, color: c.mutedForeground, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchQuery.value = '';
                                      ref.read(_searchQueryProvider.notifier).state = '';
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (q) {
                          _searchQuery.value = q;
                          ref.read(_searchQueryProvider.notifier).state = q.trim();
                        },
                        onSubmitted: (q) { if (q.trim().isNotEmpty) SearchHistoryManager.add(q.trim()); },
                      ),
                    ),
                  ),
                  const SizedBox(width: SNSpace.x3),
                  SNCircleButton(
                    icon: Icons.tune_rounded,
                    onTap: () async {
                      final user = ref.read(authNotifierProvider);
                      final repo = ref.read(hostelsRepositoryProvider);
                      final result = await showAdvancedFilters(context, repo: repo, university: user?.university);
                      if (result != null) {
                        ref.read(_advancedFiltersProvider.notifier).state = result;
                      }
                    },
                    filled: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: SNSpace.x4),

            // Filter pills
            SizedBox(
              height: SNSpace.minTapTarget,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: SNSpace.x2),
                itemBuilder: (_, i) => SNChip(
                  label: _filters[i].label,
                  selected: selectedFilter == i,
                  onTap: () async {
                    if (_filters[i].radiusKm != null) {
                      try {
                        LocationPermission perm = await Geolocator.checkPermission();
                        if (perm == LocationPermission.denied) {
                          perm = await Geolocator.requestPermission();
                        }
                        if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location permission needed for "Near Me" search')),
                            );
                          }
                          return;
                        }
                        final pos = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
                        );
                        ref.read(_userLocationProvider.notifier).state = pos;
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not get location: \$e')),
                          );
                        }
                        return;
                      }
                    }
                    ref.read(_exploreFilterIndex.notifier).state = i;
                  },
                ),
              ),
            ),

            const SizedBox(height: SNSpace.x4),

            // Map placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
              child: hostelsAsync.when(
                loading: () => Container(
                  height: 160,
                  decoration: BoxDecoration(color: c.muted, borderRadius: SNRadius.card),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(height: 160),
                data: (hostels) {
                  final mapped = hostels.where((h) => h.latitude != null && h.longitude != null).toList();
                  if (mapped.isEmpty) {
                    return Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(color: c.muted, borderRadius: SNRadius.card, border: Border.all(color: c.border)),
                      child: Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined, size: 48, color: c.mutedForeground.withValues(alpha: 0.3)),
                          const SizedBox(height: SNSpace.x2),
                          Text('Map pins available soon', style: SNText.caption.copyWith(color: c.mutedForeground)),
                        ],
                      )),
                    );
                  }
                  // Center on first hostel with coords
                  final center = LatLng(mapped.first.latitude!, mapped.first.longitude!);
                  return GestureDetector(
                    onTap: () => _openFullMap(context, ref, hostels),
                    child: Container(
                      height: 160,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(borderRadius: SNRadius.card, border: Border.all(color: c.border)),
                      child: IgnorePointer(
                        child: FlutterMap(
                          options: MapOptions(initialCenter: center, initialZoom: 15.5),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.staynest.mobile',
                            ),
                            MarkerLayer(
                              markers: mapped.map((h) => Marker(
                                point: LatLng(h.latitude!, h.longitude!),
                                width: 36, height: 36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: c.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 16),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: SNSpace.x4),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
              child: hostelsAsync.when(
                data: (h) => Text('${h.length} hostels found', style: SNText.bodyBold.copyWith(color: c.foreground)),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),

            const SizedBox(height: SNSpace.x3),

            // Hostel list
            Expanded(
              child: hostelsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: SNErrorState(
                    headline: 'Could not load hostels',
                    onRetry: () => ref.invalidate(_exploreProvider),
                  ),
                ),
                data: (hostels) {
                  if (hostels.isEmpty) {
                    return Center(
                      child: SNEmptyState(
                        icon: Icons.search_off_rounded,
                        headline: 'No hostels match this filter',
                        actionLabel: 'Show all',
                        onAction: () => ref.read(_exploreFilterIndex.notifier).state = 0,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(_exploreProvider),
                    child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, SNSpace.navClear),
                    itemCount: hostels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x3),
                    itemBuilder: (_, i) {
                      final h = hostels[i];
                      return HostelCard.list(
                        name: h.name,
                        location: h.address,
                        imageUrl: hostels[i].imageUrls.isNotEmpty ? hostels[i].imageUrls.first : null,
                        fromPricePesewas: h.fromPricePesewas,
                        rating: (h.averageRating ?? 0) > 0 ? h.averageRating : null,
                        reviewCount: (h.reviewCount ?? 0) > 0 ? h.reviewCount : null,
                        verified: h.verified,
                        amenities: h.amenities.take(3).map((a) => AmenityChip(label: a.name, icon: _amenityIcon(a.name))).toList(),
                        onTap: () => context.push('/home/hostel/${h.id}'),
                      );
                    },
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _amenityIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('wifi')) return Icons.wifi_rounded;
    if (l.contains('power') || l.contains('generator')) return Icons.bolt_rounded;
    if (l.contains('security')) return Icons.shield_outlined;
    if (l.contains('laundry')) return Icons.local_laundry_service_outlined;
    if (l.contains('ac')) return Icons.ac_unit_rounded;
    if (l.contains('water')) return Icons.water_drop_outlined;
    return Icons.check_circle_outline;
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({required this.label, required this.selected, required this.c});
  final String label;
  final bool selected;
  final SNColorTokens c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.primary : c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.primary : c.border, width: 2),
            boxShadow: [BoxShadow(color: c.foreground.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Text(label, style: SNText.bodyBold.copyWith(color: selected ? c.primaryForeground : c.foreground, fontSize: 11)),
        ),
        CustomPaint(size: const Size(12, 8), painter: _PinArrowPainter(color: selected ? c.primary : c.card)),
      ],
    );
  }
}

class _PinArrowPainter extends CustomPainter {
  _PinArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, 0)..lineTo(size.width / 2, size.height)..lineTo(size.width, 0)..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
