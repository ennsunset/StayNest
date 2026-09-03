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
      nav.pop();
      if (context.mounted) {
        context.push('/owner/hostels/$hostelId/edit', extra: data);
      }
    } catch (e) {
      nav.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load hostel: $e')));
      }
    }
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, _HostelCard h) {
    final c = context.sn;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: c.foreground),
                title: Text('Edit Listing', style: SNText.body.copyWith(color: c.foreground)),
                onTap: () { Navigator.pop(ctx); _navigateToEdit(context, ref, h.id); },
              ),
              ListTile(
                leading: Icon(Icons.meeting_room_outlined, color: c.foreground),
                title: Text('Manage Rooms', style: SNText.body.copyWith(color: c.foreground)),
                onTap: () { Navigator.pop(ctx); context.push('/owner/hostels/${h.id}/rooms?name=${Uri.encodeComponent(h.name)}'); },
              ),
              ListTile(
                leading: Icon(Icons.people_outline, color: c.foreground),
                title: Text('View Tenants', style: SNText.body.copyWith(color: c.foreground)),
                onTap: () { Navigator.pop(ctx); context.push('/owner/tenants'); },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: c.destructive),
                title: Text('Delete Hostel', style: SNText.body.copyWith(color: c.destructive)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Delete Hostel?'),
                      content: Text('This will permanently delete "${h.name}" and all its rooms. This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dCtx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete API coming soon')));
                          },
                          child: Text('Delete', style: TextStyle(color: c.destructive)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x4, SNSpace.screenX, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your Properties', style: SNText.headingLg.copyWith(color: c.foreground)),
                      GestureDetector(
                        onTap: () async {
                          final result = await context.push('/owner/hostels/add');
                          if (result == true) ref.invalidate(ownerHostelsProvider);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: c.primaryForeground, size: 18),
                              const SizedBox(width: 6),
                              Text('Add New', style: SNText.bodyBold.copyWith(color: c.primaryForeground, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SNSpace.x5),

                // ── Content ──
                hostelsAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                    child: Column(
                      children: List.generate(2, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: SNSpace.x4),
                        child: SNSkeleton(width: double.infinity, height: 300, radius: SNRadius.lg),
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
                    children: hostels.map((h) => _buildCard(context, ref, c, h)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, SNColorTokens c, _HostelCard h) {
    final occupied = h.totalBeds - h.availableBeds;
    final (badgeLabel, badgeTone) = _statusDisplay(h.status);
    final isActive = h.status == 'ACTIVE';

    return Padding(
      padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, SNSpace.x4),
      child: SNCard(
        onTap: isActive
            ? () => context.push('/owner/hostels/${h.id}/rooms?name=${Uri.encodeComponent(h.name)}')
            : null,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + badges ──
            Stack(
              children: [
                SNImage(
                  url: h.imageUrls.isNotEmpty ? h.imageUrls.first : null,
                  height: 180,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(SNRadius.lg)),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: SNBadge(label: badgeLabel, tone: badgeTone),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _showMoreMenu(context, ref, h),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.black87, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(SNSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + address ──
                  Text(h.name, style: SNText.headingMd.copyWith(color: c.foreground)),
                  const SizedBox(height: 2),
                  Text(h.address, style: SNText.caption.copyWith(color: c.mutedForeground)),

                  if (isActive) ...[
                    const SizedBox(height: 16),

                    // ── Stats row with dividers ──
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.5))),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _stat(c, 'ROOMS', h.totalRooms.toString(), null),
                            VerticalDivider(width: 1, thickness: 1, color: c.border.withValues(alpha: 0.5)),
                            _stat(c, 'OCCUPIED', occupied.toString(), null),
                            VerticalDivider(width: 1, thickness: 1, color: c.border.withValues(alpha: 0.5)),
                            _stat(c, 'VACANT', h.availableBeds.toString(), c.primary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Action buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/owner/hostels/${h.id}/rooms?name=${Uri.encodeComponent(h.name)}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: c.muted,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.meeting_room_outlined, size: 18, color: c.foreground),
                                  const SizedBox(width: 8),
                                  Text('Manage Rooms', style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _navigateToEdit(context, ref, h.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: c.muted,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.settings_outlined, size: 18, color: c.foreground),
                                  const SizedBox(width: 8),
                                  Text('Settings', style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (h.status == 'PENDING_REVIEW') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: c.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.schedule, color: c.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Under review — usually 24-48 hours', style: SNText.caption.copyWith(color: c.foreground))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    SNButton(label: 'Edit Listing', variant: SNButtonVariant.secondary, onPressed: () => _navigateToEdit(context, ref, h.id)),
                  ],

                  if (h.status == 'REJECTED') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: c.destructive.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: c.destructive, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('A few things to fix before this can go live', style: SNText.caption.copyWith(color: c.foreground))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    SNButton(label: 'Edit & Resubmit', onPressed: () => _navigateToEdit(context, ref, h.id)),
                  ],

                  if (h.status == 'DRAFT') ...[
                    const SizedBox(height: 16),
                    SNButton(label: 'Edit & Submit', onPressed: () => _navigateToEdit(context, ref, h.id)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(SNColorTokens c, String label, String value, Color? valueColor) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.2, fontWeight: FontWeight.w700, fontSize: 9),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: SNText.headingMd.copyWith(color: valueColor ?? c.foreground),
          ),
        ],
      ),
    );
  }
}
