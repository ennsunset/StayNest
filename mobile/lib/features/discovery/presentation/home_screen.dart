import 'package:staynest_mobile/app/router.dart';
// features/discovery/presentation/home_screen.dart
//
// Screen 11 — Home. Now wired to the real API.
// Featured hostels come from featuredHostelsProvider.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:staynest_mobile/features/account/data/notifications_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/features/discovery/data/featured_hostels_provider.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';
import 'package:staynest_mobile/features/discovery/presentation/saved_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    _notifTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(unreadNotificationsProvider);
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  int _selectedFilter = 0;

  static const _filters = [
    {'label': 'All', 'gender': null},
    {'label': 'Women Only', 'gender': 'FEMALE_ONLY'},
    {'label': 'Men Only', 'gender': 'MALE_ONLY'},
    {'label': 'Mixed', 'gender': 'MIXED'},
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final user = ref.watch(authNotifierProvider);
    final featuredAsync = ref.watch(featuredHostelsProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(featuredHostelsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: SNSpace.navClear),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(c, user?.fullName ?? 'Student'),
              const SizedBox(height: SNSpace.x5),
              _buildSearchField(c),
              const SizedBox(height: SNSpace.x4),
              _buildAIStrip(c),
              const SizedBox(height: SNSpace.x6),
              _buildFilterPills(c),
              const SizedBox(height: SNSpace.section),
              SNSectionHeader(
                title: 'Featured Hostels',
                onSeeAll: () => context.push('/home/search-results'),
              ),
              const SizedBox(height: SNSpace.x4),
              _buildFeaturedSection(c, featuredAsync),
              const SizedBox(height: SNSpace.section),
              SNSectionHeader(
                title: 'Search by Amenities',
                onSeeAll: () => context.push('/home/search-results'),
              ),
              const SizedBox(height: SNSpace.x4),
              _buildAmenityGrid(c),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(SNColorTokens c, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, SNSpace.x4, SNSpace.screenX, 0,
      ),
      child: Row(
        children: [
          SNAvatar(size: SNSize.avatarMd, initials: _initials(name)),
          const SizedBox(width: SNSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: SNText.body.copyWith(color: c.mutedForeground)),
                Text('${name.split(' ').first} 👋', style: SNText.headingLg.copyWith(color: c.foreground)),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(unreadNotificationsProvider).whenOrNull(data: (c) => c) ?? 0;
              return SNCircleButton(
                icon: Icons.notifications_outlined,
                onTap: () async { await context.push('/notifications'); ref.invalidate(unreadNotificationsProvider); },
                badge: count > 0 ? count : null,
              );
            },
          ),
          const SizedBox(width: SNSpace.x3),
          SNCircleButton(icon: Icons.auto_awesome_outlined, onTap: () => context.push(Routes.aiChat), filled: true),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  Widget _buildSearchField(SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: GestureDetector(
        onTap: () => context.push('/home/search-results'),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.x5),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: SNRadius.control,
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 22, color: c.mutedForeground),
              const SizedBox(width: SNSpace.x3),
              Text('Find your perfect hostel...', style: SNText.body.copyWith(color: c.mutedForeground)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIStrip(SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: SNCard(
        tinted: true,
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.x5, vertical: SNSpace.x4),
        onTap: () => context.push('/ai-chat?q=Find+me+a+hostel+under+GH%E2%82%B53%2C000+near+campus'),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: c.primary),
            const SizedBox(width: SNSpace.x3),
            Expanded(child: Text('Ask AI: "Find me a hostel under GH₵3,000 near campus"', style: SNText.body.copyWith(color: c.primary))),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills(SNColorTokens c) {
    return SizedBox(
      height: SNSpace.minTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: SNSpace.x3),
        itemBuilder: (_, i) => SNChip(
          label: _filters[i]['label'] as String,
          selected: _selectedFilter == i,
          onTap: () => setState(() => _selectedFilter = i),
        ),
      ),
    );
  }

  // ── Featured: loading / error / data ──────────────

  Widget _buildFeaturedSection(SNColorTokens c, AsyncValue<List<Hostel>> async) {
    return async.when(
      loading: () => SizedBox(
        height: 340,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: SNSpace.cardGap),
          itemBuilder: (_, __) => const SNSkeleton(width: SNSize.featuredCardW, height: 300, radius: SNRadius.lg),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
        child: SNErrorState(
          headline: 'Could not load hostels',
          onRetry: () => ref.invalidate(featuredHostelsProvider),
        ),
      ),
      data: (allHostels) {
        final genderFilter = _filters[_selectedFilter]['gender'] as String?;
        final hostels = genderFilter == null
            ? allHostels
            : allHostels.where((h) => h.genderPolicy == genderFilter).toList();
        if (hostels.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
            child: SNEmptyState(
              headline: 'No hostels for your university yet',
              body: 'We\'re adding hostels near your campus soon. Try searching all hostels instead.',
              icon: Icons.apartment_rounded,
              actionLabel: 'Browse All Hostels',
              onAction: () => ref.invalidate(featuredHostelsProvider),
            ),
          );
        }
        return SizedBox(
        height: 340,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
          itemCount: hostels.length,
          separatorBuilder: (_, __) => const SizedBox(width: SNSpace.cardGap),
          itemBuilder: (_, i) {
            final h = hostels[i];
            return HostelCard.featured(
              name: h.name,
              location: h.address,
              imageUrl: h.imageUrls.isNotEmpty ? h.imageUrls.first : null,
              fromPricePesewas: h.fromPricePesewas,
              rating: h.averageRating,
              reviewCount: h.reviewCount,
              verified: h.verified,
              onTap: () {
                context.push('/home/hostel/${h.id}');
              },
            );
          },
        ),
      );
      },
    );
  }

  Widget _buildAmenityGrid(SNColorTokens c) {
    final items = [
      ('Fast WiFi', Icons.wifi_rounded),
      ('Backup Power', Icons.bolt_rounded),
      ('Security', Icons.shield_outlined),
      ('Laundry', Icons.local_laundry_service_outlined),
      ('Air Conditioning', Icons.ac_unit_rounded),
      ('Water Supply', Icons.water_drop_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: SNSpace.x3,
        crossAxisSpacing: SNSpace.x3,
        childAspectRatio: 1.1,
        children: items.map((a) {
          return _AmenityTile(label: a.$1, icon: a.$2, onTap: () => context.push('/home/search-results'));
        }).toList(),
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  const _AmenityTile({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: SNRadius.card,
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 44, width: 44,
              decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(SNRadius.sm)),
              child: Icon(icon, size: 22, color: c.primary),
            ),
            const SizedBox(height: SNSpace.x2),
            Text(label, style: SNText.caption.copyWith(color: c.foreground), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
