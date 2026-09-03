import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

part 'revenue_reports_screen.g.dart';

@riverpod
Future<Map<String, dynamic>> revenueBreakdown(Ref ref) {
  return ref.read(ownerRepositoryProvider).fetchRevenueBreakdown();
}

class RevenueReportsScreen extends ConsumerWidget {
  const RevenueReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final asyncData = ref.watch(revenueBreakdownProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Revenue Reports',
        onBack: () => context.pop(),
        trailing: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export coming soon'))),
          child: Icon(Icons.download_outlined, color: c.foreground, size: 22),
        ),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: SNEmptyState(
          icon: Icons.error_outline, headline: 'Failed to load revenue',
          actionLabel: 'Retry', onAction: () => ref.invalidate(revenueBreakdownProvider),
        )),
        data: (data) {
          final total = (data['totalRevenuePesewas'] as num?)?.toInt() ?? 0;
          final hostels = (data['hostels'] as List?) ?? [];
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(revenueBreakdownProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1C2B41), borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TOTAL REVENUE', style: SNText.microAction.copyWith(color: Colors.white60, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(Money.format(total), style: SNText.headingLg.copyWith(color: Colors.white, fontSize: 28)),
                    const SizedBox(height: 4),
                    Text('Across \${hostels.length} properties', style: SNText.caption.copyWith(color: Colors.white54)),
                  ]),
                ),
                const SizedBox(height: 28),
                Text('BREAKDOWN BY PROPERTY', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                if (hostels.isEmpty)
                  SNCard(child: Center(child: Text('No revenue data yet', style: SNText.body.copyWith(color: c.mutedForeground))))
                else
                  ...hostels.map((h) {
                    final rev = (h['revenuePesewas'] as num?)?.toInt() ?? 0;
                    final beds = (h['bedCount'] as num?)?.toInt() ?? 0;
                    final pct = (h['collectionPct'] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SNCard(child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h['name'] as String? ?? '', style: SNText.bodyBold.copyWith(color: c.foreground)),
                          const SizedBox(height: 2),
                          Text('\$beds beds', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(Money.format(rev), style: SNText.bodyBold.copyWith(color: c.foreground)),
                          const SizedBox(height: 2),
                          Text('\$pct% occupancy', style: SNText.caption.copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                        ]),
                      ])),
                    );
                  }),
              ]),
            ),
          );
        },
      ),
    );
  }
}
