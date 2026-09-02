// features/owner/presentation/manage_hostels_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

part 'manage_hostels_screen.g.dart';

// ── Data class for owner hostel cards ──

class _HostelCard {
  _HostelCard({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    required this.imageUrls,
    required this.totalRooms,
    required this.totalBeds,
    required this.availableBeds,
  });

  final String id;
  final String name;
  final String address;
  final String status;
  final List<String> imageUrls;
  final int totalRooms;
  final int totalBeds;
  final int availableBeds;

  factory _HostelCard.fromJson(Map<String, dynamic> json) {
    int rooms = 0, beds = 0, avail = 0;
    for (final b in (json['buildings'] as List? ?? [])) {
      for (final f in ((b as Map)['floors'] as List? ?? [])) {
        for (final r in ((f as Map)['rooms'] as List? ?? [])) {
          rooms++;
          for (final bd in ((r as Map)['beds'] as List? ?? [])) {
            beds++;
            if ((bd as Map)['status'] == 'AVAILABLE') avail++;
          }
        }
      }
    }
    return _HostelCard(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      totalRooms: rooms,
      totalBeds: beds,
      availableBeds: avail,
    );
  }
}

@riverpod
Future<List<_HostelCard>> ownerHostels(Ref ref) async {
  final raw = await ref.read(ownerRepositoryProvider).fetchMyHostels();
  return raw.map((j) => _HostelCard.fromJson(j)).toList();
}

class ManageHostelsScreen extends ConsumerWidget {
  const ManageHostelsScreen({super.key});

  static (String label, SNStatusTone tone) _statusDisplay(String status) {
    return switch (status) {
      'ACTIVE' => ('Active', SNStatusTone.success),
      'PENDING_REVIEW' => ('Under Review', SNStatusTone.warning),
      'REJECTED' => ('Needs Changes', SNStatusTone.danger),
      'DRAFT' => ('Draft', SNStatusTone.info),
      _ => (status, SNStatusTone.info),
    };
  }

  void _navigateToEdit(BuildContext context, WidgetRef ref, String hostelId) async {
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final data = await repo.fetchHostel(hostelId);
      nav.pop(); // dismiss loading
      if (context.mounted) {
        context.push('/owner/hostels/$hostelId/edit', extra: data);
      }
    } catch (e) {
      nav.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load hostel: \$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final hostelsAsync = ref.watch(ownerHostelsProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () => ref.refresh(ownerHostelsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: SNSpace.navClear),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x4, SNSpace.screenX, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Properties', style: SNText.headingLg.copyWith(color: c.foreground)),
                      SNCircleButton(
                        icon: Icons.add,
                        filled: true,
                        onTap: () async {
                          final result = await context.push('/owner/hostels/add');
                          if (result == true) ref.invalidate(ownerHostelsProvider);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SNSpace.x5),
                hostelsAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                    child: Column(
                      children: List.generate(2, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: SNSpace.x4),
                        child: SNSkeleton(width: double.infinity, height: 280, radius: SNRadius.lg),
                      )),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(SNSpace.screenX),
                    child: SNEmptyState(
                      headline: 'Could not load properties',
                      body: e.toString(),
                      icon: Icons.error_outline,
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(ownerHostelsProvider),
                    ),
                  ),
                  data: (hostels) => Column(
                    children: hostels.map((h) {
                      final occupied = h.totalBeds - h.availableBeds;
                      final (badgeLabel, badgeTone) = _statusDisplay(h.status);
                      final isActive = h.status == 'ACTIVE';

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, SNSpace.x4),
                        child: GestureDetector(
                          onLongPress: () => _navigateToEdit(context, ref, h.id),
                          child: SNCard(
                            onTap: isActive
                                ? () => context.push('/owner/hostels/${h.id}/rooms?name=${Uri.encodeComponent(h.name)}')
                                : null,
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    SNImage(
                                      url: h.imageUrls.isNotEmpty ? h.imageUrls.first : null,
                                      height: 140,
                                      width: double.infinity,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(SNRadius.lg)),
                                    ),
                                    Positioned(
                                      top: SNSpace.x3,
                                      right: SNSpace.x3,
                                      child: SNBadge(label: badgeLabel, tone: badgeTone),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(SNSpace.x5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.name, style: SNText.headingMd.copyWith(color: c.foreground)),
                                      const SizedBox(height: SNSpace.x1),
                                      Text(h.address, style: SNText.caption.copyWith(color: c.mutedForeground)),

                                      if (isActive) ...[
                                        const SizedBox(height: SNSpace.x4),
                                        Row(
                                          children: [
                                            _stat(c, 'Rooms', h.totalRooms.toString()),
                                            _stat(c, 'Occupied', occupied.toString()),
                                            _stat(c, 'Vacant', h.availableBeds.toString()),
                                          ],
                                        ),
                                        const SizedBox(height: SNSpace.x5),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SNButton(
                                                label: 'Manage Rooms',
                                                variant: SNButtonVariant.secondary,
                                                onPressed: () => context.push('/owner/hostels/${h.id}/rooms?name=${Uri.encodeComponent(h.name)}'),
                                              ),
                                            ),
                                            const SizedBox(width: SNSpace.x2),
                                            SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: IconButton(
                                                onPressed: () => _navigateToEdit(context, ref, h.id),
                                                icon: Icon(Icons.edit_outlined, size: 20, color: c.mutedForeground),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      if (h.status == 'PENDING_REVIEW') ...[
                                        const SizedBox(height: SNSpace.x4),
                                        Container(
                                          padding: const EdgeInsets.all(SNSpace.x3),
                                          decoration: BoxDecoration(color: c.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(SNSpace.x3)),
                                          child: Row(children: [
                                            Icon(Icons.schedule, color: c.warning, size: 18),
                                            const SizedBox(width: SNSpace.x2),
                                            Expanded(child: Text('Under review — usually 24-48 hours', style: SNText.caption.copyWith(color: c.foreground))),
                                          ]),
                                        ),
                                        const SizedBox(height: SNSpace.x3),
                                        SNButton(label: 'Edit Listing', variant: SNButtonVariant.secondary, onPressed: () => _navigateToEdit(context, ref, h.id)),
                                      ],

                                      if (h.status == 'REJECTED') ...[
                                        const SizedBox(height: SNSpace.x4),
                                        Container(
                                          padding: const EdgeInsets.all(SNSpace.x3),
                                          decoration: BoxDecoration(color: c.destructive.withOpacity(0.08), borderRadius: BorderRadius.circular(SNSpace.x3)),
                                          child: Row(children: [
                                            Icon(Icons.error_outline, color: c.destructive, size: 18),
                                            const SizedBox(width: SNSpace.x2),
                                            Expanded(child: Text('A few things to fix before this can go live', style: SNText.caption.copyWith(color: c.foreground))),
                                          ]),
                                        ),
                                        const SizedBox(height: SNSpace.x3),
                                        SNButton(label: 'Edit & Resubmit', onPressed: () => _navigateToEdit(context, ref, h.id)),
                                      ],

                                      if (h.status == 'DRAFT') ...[
                                        const SizedBox(height: SNSpace.x4),
                                        SNButton(label: 'Edit & Submit', onPressed: () => _navigateToEdit(context, ref, h.id)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(SNColorTokens c, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: SNText.bodyBold.copyWith(color: c.foreground), maxLines: 1)),
          Text(label, style: SNText.caption.copyWith(color: c.mutedForeground)),
        ],
      ),
    );
  }
}
