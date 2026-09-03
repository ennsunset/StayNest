import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

part 'maintenance_dashboard_screen.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> maintenanceRequests(Ref ref) {
  return ref.read(ownerRepositoryProvider).fetchMaintenanceRequests();
}

class MaintenanceDashboardScreen extends ConsumerStatefulWidget {
  const MaintenanceDashboardScreen({super.key});
  @override
  ConsumerState<MaintenanceDashboardScreen> createState() => _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState extends ConsumerState<MaintenanceDashboardScreen> {
  int _tab = 0;
  static const _tabs = ['Pending', 'In Progress', 'Resolved'];
  static const _statusMap = ['PENDING', 'IN_PROGRESS', 'RESOLVED'];

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final asyncData = ref.watch(maintenanceRequestsProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Maintenance', onBack: () => context.pop()),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: SNEmptyState(icon: Icons.error_outline, headline: 'Failed to load', actionLabel: 'Retry', onAction: () => ref.invalidate(maintenanceRequestsProvider))),
        data: (all) {
          final filtered = all.where((r) => (r['status'] as String? ?? 'PENDING') == _statusMap[_tab]).toList();
          final pendingCount = all.where((r) => (r['status'] as String? ?? 'PENDING') == 'PENDING').length;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(children: List.generate(_tabs.length, (i) {
                final active = i == _tab;
                final label = i == 0 ? '\${_tabs[i]} (\$pendingCount)' : _tabs[i];
                return Padding(padding: const EdgeInsets.only(right: 10), child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: active ? c.primary : c.muted, borderRadius: BorderRadius.circular(20)),
                    child: Text(label, style: SNText.caption.copyWith(color: active ? c.primaryForeground : c.mutedForeground, fontWeight: FontWeight.w700))),
                ));
              })),
            ),
            Expanded(child: filtered.isEmpty
              ? Center(child: Text('No \${_tabs[_tab].toLowerCase()} requests', style: SNText.body.copyWith(color: c.mutedForeground)))
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(maintenanceRequestsProvider),
                  child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(c, filtered[i])))),
          ]);
        },
      ),
    );
  }

  Widget _card(SNColorTokens c, Map<String, dynamic> req) {
    final title = req['title'] as String? ?? 'Issue';
    final desc = req['description'] as String? ?? '';
    final priority = (req['priority'] as String? ?? 'MEDIUM').toUpperCase();
    final hostel = req['hostel_name'] as String? ?? '';
    final room = req['room_label'] as String? ?? '';
    final status = req['status'] as String? ?? 'PENDING';
    final sevColor = priority == 'URGENT' || priority == 'HIGH' ? c.destructive : c.warning;

    return SNCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.build_outlined, color: c.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13, letterSpacing: 0.5)),
          if (room.isNotEmpty || hostel.isNotEmpty) Text('\${room.isNotEmpty ? room : ""}\${room.isNotEmpty && hostel.isNotEmpty ? " \u2022 " : ""}\$hostel', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 0.5)),
        ])),
        Text(priority, style: SNText.microAction.copyWith(color: sevColor, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ]),
      if (desc.isNotEmpty) ...[const SizedBox(height: 12), Text('"\$desc"', style: SNText.body.copyWith(color: c.mutedForeground, fontStyle: FontStyle.italic))],
      if (status == 'PENDING') ...[
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () async { try { await ref.read(ownerRepositoryProvider).updateMaintenanceStatus(req['id'] as String, status: 'IN_PROGRESS'); ref.invalidate(maintenanceRequestsProvider); } catch (_) {} },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(12)), child: Center(child: Text('IN PROGRESS', style: SNText.bodyBold.copyWith(color: c.primaryForeground, fontSize: 12, letterSpacing: 1)))),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async { try { await ref.read(ownerRepositoryProvider).updateMaintenanceStatus(req['id'] as String, status: 'RESOLVED'); ref.invalidate(maintenanceRequestsProvider); } catch (_) {} },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(12)), child: Text('RESOLVE', style: SNText.bodyBold.copyWith(color: c.mutedForeground, fontSize: 12, letterSpacing: 1))),
          ),
        ]),
      ],
      if (status == 'IN_PROGRESS') ...[
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async { try { await ref.read(ownerRepositoryProvider).updateMaintenanceStatus(req['id'] as String, status: 'RESOLVED'); ref.invalidate(maintenanceRequestsProvider); } catch (_) {} },
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('MARK RESOLVED', style: SNText.bodyBold.copyWith(color: Colors.white, fontSize: 12, letterSpacing: 1)))),
        ),
      ],
    ]));
  }
}
