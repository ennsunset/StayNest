// features/owner/presentation/tenant_management_screen.dart
//
// Screen 44 — Tenant Management. Wired to GET /owner/tenants.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

part 'tenant_management_screen.g.dart';

@riverpod
Future<List<OwnerTenant>> ownerTenants(Ref ref) {
  return ref.read(ownerRepositoryProvider).fetchTenants();
}

class TenantManagementScreen extends ConsumerWidget {
  const TenantManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final tenantsAsync = ref.watch(ownerTenantsProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () => ref.refresh(ownerTenantsProvider.future),
          child: tenantsAsync.when(
            loading: () => ListView(
              padding: const EdgeInsets.all(SNSpace.screenX),
              children: List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: SNSpace.x3),
                child: SNSkeleton(width: double.infinity, height: 72, radius: SNRadius.lg),
              )),
            ),
            error: (e, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(SNSpace.screenX),
                  child: SNEmptyState(
                    headline: 'Could not load tenants',
                    body: e.toString(),
                    icon: Icons.error_outline,
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(ownerTenantsProvider),
                  ),
                ),
              ],
            ),
            data: (tenants) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tenants', style: SNText.headingLg.copyWith(color: c.foreground)),
                      Text(
                        tenants.length.toString() + ' TOTAL',
                        style: SNText.microAction.copyWith(color: c.mutedForeground),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: tenants.isEmpty
                    ? Center(
                        child: SNEmptyState(
                          headline: 'No active tenants',
                          body: 'Tenants will appear here once bookings are confirmed.',
                          icon: Icons.people_outline,
                          actionLabel: 'Refresh',
                          onAction: () => ref.invalidate(ownerTenantsProvider),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          SNSpace.screenX, 0, SNSpace.screenX, SNSpace.navClear,
                        ),
                        itemCount: tenants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x3),
                        itemBuilder: (_, i) {
                          final t = tenants[i];
                          final isPaid = t.status == 'CHECKED_IN';
                          final initials = t.studentName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

                          return SNCard(
                            onTap: () {},
                            padding: const EdgeInsets.all(SNSpace.x4),
                            child: Row(
                              children: [
                                SNAvatar(size: SNSize.avatarSm, initials: initials),
                                const SizedBox(width: SNSpace.x4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.studentName, style: SNText.bodyBold.copyWith(color: c.foreground)),
                                      const SizedBox(height: SNSpace.x1),
                                      Text(
                                        t.hostelName + ' · Room ' + t.roomNumber,
                                        style: SNText.caption.copyWith(color: c.mutedForeground),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SNBadge(
                                      label: isPaid ? 'Active' : t.status,
                                      tone: isPaid ? SNStatusTone.success : SNStatusTone.neutral,
                                    ),
                                    const SizedBox(height: SNSpace.x2),
                                    if (t.status == 'CONFIRMED')
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            await ref.read(ownerRepositoryProvider).checkInTenant(t.bookingId);
                                            ref.invalidate(ownerTenantsProvider);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('${t.studentName} checked in!')),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Could not check in tenant')),
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: c.primary,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('Check In', style: SNText.caption.copyWith(color: c.primaryForeground, fontWeight: FontWeight.w700, fontSize: 11)),
                                        ),
                                      )
                                    else
                                      Text(
                                        t.bedLabel,
                                        style: SNText.caption.copyWith(color: c.mutedForeground),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
