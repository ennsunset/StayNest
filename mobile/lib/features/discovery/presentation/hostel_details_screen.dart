// features/discovery/presentation/hostel_details_screen.dart
//
// Screen 15 — Hostel Details. Wired to real API.
// Hero image, glass nav, amenities, room types from API, sticky bottom bar.

import 'package:flutter/material.dart';
import 'package:staynest_mobile/features/messaging/data/messaging_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';
import 'package:staynest_mobile/features/discovery/presentation/saved_screen.dart';
import 'package:staynest_mobile/core/utils/recently_viewed_manager.dart';

/// Provider for hostel detail + rooms.
final hostelDetailProvider = FutureProvider.family<Hostel, String>((ref, id) {
  return ref.read(hostelsRepositoryProvider).fetchById(id);
});

class HostelDetailsScreen extends ConsumerStatefulWidget {
  const HostelDetailsScreen({super.key, required this.hostelId});

  final String hostelId;

  @override
  ConsumerState<HostelDetailsScreen> createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends ConsumerState<HostelDetailsScreen> {
  // _saved is now driven by savedHostelIdsProvider

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final hostelAsync = ref.watch(hostelDetailProvider(widget.hostelId));

    return hostelAsync.when(
      loading: () => Scaffold(
        backgroundColor: c.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: SNErrorState(
            headline: 'Could not load hostel',
            onRetry: () => ref.invalidate(hostelDetailProvider(widget.hostelId)),
          ),
        ),
      ),
      data: (hostel) => _buildContent(c, hostel),
    );
  }

  Widget _buildContent(SNColorTokens c, Hostel hostel) {
    // Track this view
    final minPrice = hostel.rooms.isEmpty ? 0 : hostel.rooms.map((r) => r.pricePesewas).reduce((a, b) => a < b ? a : b);
    RecentlyViewedManager.add(RecentlyViewedItem(
      hostelId: hostel.id,
      name: hostel.name,
      imageUrl: hostel.imageUrls.isNotEmpty ? hostel.imageUrls.first : null,
      pricePesewas: minPrice,
      rating: hostel.averageRating ?? 0.0,
      viewedAt: DateTime.now(),
    ));

    // Extract rooms from the nested building > floor > room structure



    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(hostelDetailProvider(widget.hostelId)),
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero(c, hostel)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  SNSpace.screenX, SNSpace.x5, SNSpace.screenX, 120,
                ),
                sliver: SliverList.list(
                  children: [
                    _buildTitle(c, hostel),
                    const SizedBox(height: SNSpace.x4),
                    _buildInfoRow(c, hostel),
                    const SizedBox(height: SNSpace.x5),
                    _buildAmenities(c, hostel),
                    const SizedBox(height: SNSpace.section),
                    _buildRoomTypes(c, hostel),
                    const SizedBox(height: SNSpace.section),
                    _buildAbout(c, hostel),
                    const SizedBox(height: SNSpace.section),
                    _buildPolicies(c, hostel),
                    const SizedBox(height: SNSpace.section),
                    _buildReviews(c, hostel),
                    const SizedBox(height: SNSpace.section),
                    _buildMapLink(c, hostel),
                  ],
                ),
              ),
            ],
          ),
          ),
          _buildNavOverlay(c),
          _buildBottomBar(c, hostel),
        ],
      ),
    );
  }

  Widget _buildHero(SNColorTokens c, Hostel hostel) {
    return GestureDetector(
      onTap: () => context.push('/home/hostel/${widget.hostelId}/gallery', extra: hostel.imageUrls),
      child: Stack(
        children: [
          SNImage(url: hostel.imageUrls.isNotEmpty ? hostel.imageUrls.first : null, height: 300, width: double.infinity, variant: SNImageVariant.large),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          if (hostel.verified)
            const Positioned(
              bottom: SNSpace.x4,
              left: SNSpace.screenX,
              child: VerifiedBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildNavOverlay(SNColorTokens c) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassCircle(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
              Row(
                children: [
                  _GlassCircle(icon: Icons.share_outlined, onTap: () {}),
                  const SizedBox(width: SNSpace.x3),
                  _GlassCircle(
                    icon: ref.watch(savedHostelIdsProvider).contains(widget.hostelId) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    onTap: () {
                      ref.read(savedHostelIdsProvider.notifier).toggle(widget.hostelId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(SNColorTokens c, Hostel hostel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hostel.name, style: SNText.headingLg.copyWith(color: c.foreground, fontSize: 24)),
        const SizedBox(height: SNSpace.x2),

      ],
    );
  }

  Widget _buildInfoRow(SNColorTokens c, Hostel hostel) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: c.mutedForeground),
        const SizedBox(width: SNSpace.x1),
        Text(hostel.address, style: SNText.body.copyWith(color: c.mutedForeground)),
      ],
    );
  }

  Widget _buildAmenities(SNColorTokens c, Hostel hostel) {
    if (hostel.amenities.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hostel.amenities.length,
        separatorBuilder: (_, __) => const SizedBox(width: SNSpace.x3),
        itemBuilder: (_, i) {
          final a = hostel.amenities[i];
          return AmenityChip(label: a.name, icon: _amenityIcon(a.name));
        },
      ),
    );
  }

  IconData _amenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('power') || lower.contains('generator')) return Icons.bolt_rounded;
    if (lower.contains('security')) return Icons.shield_outlined;
    if (lower.contains('water')) return Icons.water_drop_outlined;
    if (lower.contains('laundry')) return Icons.local_laundry_service_outlined;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit_rounded;
    return Icons.check_circle_outline;
  }

  Widget _buildRoomTypes(SNColorTokens c, Hostel hostel) {
    if (hostel.rooms.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group rooms by type, show cheapest price per type
    final typeMap = <String, List<RoomSummary>>{};
    for (final r in hostel.rooms) {
      typeMap.putIfAbsent(r.type, () => []).add(r);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Room Types', style: SNText.headingMd.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x4),
        ...typeMap.entries.map((entry) {
          final type = entry.key;
          final rooms = entry.value;
          final cheapest = rooms.reduce((a, b) => a.pricePesewas < b.pricePesewas ? a : b);
          final totalAvailable = rooms.fold<int>(0, (sum, r) => sum + r.availableBeds);

          return Padding(
            padding: const EdgeInsets.only(bottom: SNSpace.x3),
            child: RoomCard(
              title: type,
              pricePesewas: cheapest.pricePesewas,
              imageUrl: cheapest.imageUrls.isNotEmpty ? cheapest.imageUrls.first : null,
              slotsLeft: totalAvailable,
              tag: cheapest.hasPremiumTag ? 'PREMIUM' : null,
              onTap: () {
                // Navigate to first room with available beds, fallback to cheapest
                final avail = rooms.where((r) => r.availableBeds > 0).toList();
                final target = avail.isNotEmpty ? avail.first : cheapest;
                context.push('/home/room/${target.id}');
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAbout(SNColorTokens c, Hostel hostel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: SNText.headingMd.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x3),
        Text(
          hostel.description ?? 'A modern student hostel offering comfortable living spaces with excellent amenities.',
          style: SNText.body.copyWith(color: c.mutedForeground, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildReviews(SNColorTokens c, Hostel hostel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reviews', style: SNText.headingMd.copyWith(color: c.foreground)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(Routes.reviews, extra: {
                'hostelId': hostel.id,
                'hostelName': hostel.name,
              }),
              child: Text('See All', style: SNText.bodyBold.copyWith(color: c.primary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: SNSpace.x4),
        FutureBuilder<dynamic>(
          future: ref.read(dioProvider).get('/reviews/hostel/${hostel.id}?limit=3'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData) {
              return Center(child: Text('No reviews yet', style: SNText.body.copyWith(color: c.mutedForeground)));
            }
            final data = (snapshot.data as dynamic).data as Map<String, dynamic>;
            final reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
            final stats = data['stats'] as Map<String, dynamic>?;
            final avg = stats?['average'] ?? 0;
            final count = stats?['count'] ?? 0;

            if (count == 0) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 32, color: c.mutedForeground),
                    const SizedBox(height: 8),
                    Text('No reviews yet', style: SNText.body.copyWith(color: c.mutedForeground)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Rating summary row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        avg is double ? avg.toStringAsFixed(1) : avg.toString(),
                        style: SNText.headingMd.copyWith(color: c.foreground, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < (avg is double ? avg.round() : (avg as num).toInt())
                                  ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: const Color(0xFFE8A33D), size: 18,
                            )),
                          ),
                          const SizedBox(height: 2),
                          Text('\$count \${count == 1 ? "review" : "reviews"}',
                            style: SNText.caption.copyWith(color: c.mutedForeground)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Recent reviews
                ...reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14, backgroundColor: c.muted,
                              child: Icon(Icons.person, size: 14, color: c.mutedForeground),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r['author_name'] ?? 'Student',
                              style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 12))),
                            ...List.generate(5, (i) => Icon(
                              i < (r['rating'] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: const Color(0xFFE8A33D), size: 14,
                            )),
                          ],
                        ),
                        if (r['body'] != null && (r['body'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(r['body'], style: SNText.body.copyWith(color: c.mutedForeground, fontSize: 12),
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ],
    );
  }

    Widget _buildPolicies(SNColorTokens c, Hostel hostel) {
    final hasGateHours = hostel.gateOpeningTime != null || hostel.gateClosingTime != null;
    final hasRules = hostel.houseRules.isNotEmpty;
    final hasPolicy = hostel.cancellationPolicy != null;
    if (!hasGateHours && !hasRules && !hasPolicy) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Policies & Rules', style: SNText.headingMd.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x4),
        if (hasGateHours) ...[
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.schedule_rounded, color: c.primary, size: 20),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gate Hours', style: SNText.bodyBold.copyWith(color: c.foreground)),
                  const SizedBox(height: 2),
                  Text(
                    'Opens ${hostel.gateOpeningTime ?? "—"} • Closes ${hostel.gateClosingTime ?? "—"}',
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
                ],
              )),
            ]),
          ),
          const SizedBox(height: SNSpace.x3),
        ],
        if (hasPolicy) ...[
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.gavel_rounded, color: c.warning, size: 20),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cancellation Policy', style: SNText.bodyBold.copyWith(color: c.foreground)),
                  const SizedBox(height: 2),
                  Text(
                    _cancellationDescription(hostel.cancellationPolicy ?? 'FLEXIBLE'),
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
                ],
              )),
            ]),
          ),
          const SizedBox(height: SNSpace.x3),
        ],
        if (hasRules) ...[
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: c.destructive.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.rule_rounded, color: c.destructive, size: 20),
                  ),
                  const SizedBox(width: SNSpace.x3),
                  Text('House Rules', style: SNText.bodyBold.copyWith(color: c.foreground)),
                ]),
                const SizedBox(height: SNSpace.x3),
                ...hostel.houseRules.map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: SNSpace.x2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(width: 5, height: 5, decoration: BoxDecoration(color: c.mutedForeground, shape: BoxShape.circle)),
                      ),
                      const SizedBox(width: SNSpace.x3),
                      Expanded(child: Text(rule, style: SNText.body.copyWith(color: c.mutedForeground))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _cancellationDescription(String policy) {
    return switch (policy) {
      'FLEXIBLE' => 'Free cancellation up to 24 hours before check-in',
      'MODERATE' => 'Free cancellation up to 3 days before check-in',
      'STRICT' => 'No refund after booking confirmation',
      _ => policy,
    };
  }

  Widget _buildMapLink(SNColorTokens c, Hostel hostel) {
    return GestureDetector(
      onTap: () async {
        final query = Uri.encodeComponent('${hostel.name}, ${hostel.address}, ${hostel.city}');
        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(SNSpace.x4),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.map_rounded, color: c.success, size: 20),
          ),
          const SizedBox(width: SNSpace.x3),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('View on Google Maps', style: SNText.bodyBold.copyWith(color: c.foreground)),
              const SizedBox(height: 2),
              Text('${hostel.address}, ${hostel.city}', style: SNText.caption.copyWith(color: c.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          Icon(Icons.open_in_new_rounded, size: 18, color: c.mutedForeground),
        ]),
      ),
    );
  }

    Widget _buildBottomBar(SNColorTokens c, Hostel hostel) {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x4),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.border)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(child: PriceTag.startsFrom(amountPesewas: hostel.fromPricePesewas)),
              const SizedBox(width: SNSpace.x4),
              Expanded(
                child: SNButton(
                  label: 'Book Now',
                  onPressed: () {
                    // Navigate to first room with available beds
                    final available = hostel.rooms.where((r) => r.availableBeds > 0).toList();
                    if (available.isEmpty) return;
                    available.sort((a, b) => a.pricePesewas.compareTo(b.pricePesewas));
                    context.push('/home/room/${available.first.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: SNSize.circleButton, width: SNSize.circleButton,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
