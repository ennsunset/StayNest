// features/owner/presentation/owner_dashboard_screen.dart
//
// Screen 38 — Owner Dashboard. Wired to GET /owner/dashboard.

import 'package:flutter/material.dart';
import 'package:staynest_mobile/features/account/data/notifications_repository.dart';
import 'package:staynest_mobile/features/messaging/data/messaging_repository.dart';
import 'package:staynest_mobile/features/owner/presentation/owner_messages_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

part 'owner_dashboard_screen.g.dart';

@riverpod
Future<OwnerDashboard> ownerDashboardData(Ref ref) {
  return ref.read(ownerRepositoryProvider).fetchDashboard();
}

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final asyncData = ref.watch(ownerDashboardDataProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SNEmptyState(
              headline: 'Something went wrong',
              body: e.toString(),
              icon: Icons.error_outline_rounded,
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(ownerDashboardDataProvider),
            ),
          ),
          data: (dash) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerDashboardDataProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: SNSpace.navClear),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(c),
                  const SizedBox(height: SNSpace.x5),
                  if (dash.pendingRequests > 0) ...[
                    _buildAlerts(context, c, dash.pendingRequests),
                    const SizedBox(height: SNSpace.section),
                  ],
                  _buildStats(c, dash),
                  const SizedBox(height: SNSpace.section),
                  SNSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: SNSpace.x4),
                  _buildQuickNav(context, c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, SNSpace.x4, SNSpace.screenX, 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('StayNest', style: SNText.headingLg.copyWith(color: c.primary)),
              Text('Admin Dashboard', style: SNText.caption.copyWith(color: c.mutedForeground)),
            ],
          ),
          Row(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final convAsync = ref.watch(ownerConversationsProvider);
                  final unread = convAsync.whenOrNull(
                    data: (convs) => convs.fold<int>(0, (sum, c) => sum + c.unread),
                  ) ?? 0;
                  return SNCircleButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => context.go('/owner/messages'),
                    badge: unread > 0 ? unread : null,
                  );
                },
              ),
              const SizedBox(width: SNSpace.x3),
              Consumer(
                builder: (context, ref, _) {
                  final count = ref.watch(unreadNotificationsProvider).whenOrNull(data: (c) => c) ?? 0;
                  return SNCircleButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => context.push('/notifications'),
                    badge: count > 0 ? count : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(BuildContext context, SNColorTokens c, int pending) {
    final label = pending == 1
        ? '1 Pending Booking Request'
        : '$pending Pending Booking Requests';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: GestureDetector(
        onTap: () => context.push(Routes.ownerRequests),
        child: SNCard(
          tinted: true,
          tint: c.warning,
          padding: const EdgeInsets.all(SNSpace.x4),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: c.warning),
              const SizedBox(width: SNSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: SNText.bodyBold.copyWith(color: c.foreground)),
                    Text('Respond within 24 hours', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(SNColorTokens c, OwnerDashboard dash) {
    final occupancy = '${(dash.occupancyRate).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: SNSpace.x3,
        crossAxisSpacing: SNSpace.x3,
        childAspectRatio: 1.5,
        children: [
          _StatTile(c: c, label: 'Occupancy', value: occupancy, icon: Icons.people_outlined, color: c.primary),
          _StatTile(c: c, label: 'Revenue', value: Money.formatCompact(dash.netRevenue), icon: Icons.trending_up_rounded, color: c.success),
          _StatTile(c: c, label: 'Pending', value: '${dash.pendingRequests}', icon: Icons.pending_actions_rounded, color: c.warning),
          _StatTile(c: c, label: 'Repairs', value: '${dash.maintenanceCount}', icon: Icons.build_outlined, color: c.destructive),
        ],
      ),
    );
  }

  Widget _buildQuickNav(BuildContext context, SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: Column(
        children: [
          _quickNavTile(c, 'Property Management', Icons.home_work_outlined, () => context.go('/owner/hostels')),
          _quickNavTile(c, 'Tenant Management', Icons.people_alt_outlined, () => context.go('/owner/tenants')),
          _quickNavTile(c, 'Revenue Reports', Icons.bar_chart_rounded, () => context.go('/owner/reports')),
          _quickNavTile(c, 'Booking Requests', Icons.pending_actions_rounded, () => context.push(Routes.ownerRequests)),
        ],
      ),
    );
  }

  Widget _quickNavTile(SNColorTokens c, String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SNSpace.x3),
      child: SNCard(
        onTap: onTap,
        padding: const EdgeInsets.all(SNSpace.x4),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: BorderRadius.circular(SNRadius.sm),
              ),
              child: Icon(icon, size: 20, color: c.primary),
            ),
            const SizedBox(width: SNSpace.x4),
            Expanded(
              child: Text(label, style: SNText.bodyBold.copyWith(color: c.foreground)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.c,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final SNColorTokens c;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SNCard(
      padding: const EdgeInsets.all(SNSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SNRadius.xs),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: SNText.headingLg.copyWith(color: c.foreground)),
              Text(label, style: SNText.caption.copyWith(color: c.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}
