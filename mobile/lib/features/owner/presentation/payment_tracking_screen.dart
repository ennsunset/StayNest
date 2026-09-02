// features/owner/presentation/payment_tracking_screen.dart
//
// Screen 46 — Payment Tracking. Wired to GET /owner/payments.
// Trap: show commission openly on every row.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

part 'payment_tracking_screen.g.dart';

@riverpod
Future<OwnerPaymentSummary> ownerPayments(Ref ref) {
  return ref.read(ownerRepositoryProvider).fetchPayments();
}

class PaymentTrackingScreen extends ConsumerWidget {
  const PaymentTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final asyncData = ref.watch(ownerPaymentsProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SNEmptyState(
              headline: 'Could not load payments',
              body: e.toString(),
              icon: Icons.error_outline_rounded,
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(ownerPaymentsProvider),
            ),
          ),
          data: (summary) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerPaymentsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.navClear,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payments', style: SNText.headingLg.copyWith(color: c.foreground)),
                  const SizedBox(height: SNSpace.x5),

                  // Stat tiles
                  Row(
                    children: [
                      Expanded(child: _tile(c, 'Settled', Money.format(summary.totalSettled), c.success)),
                      const SizedBox(width: SNSpace.x3),
                      Expanded(child: _tile(c, 'Pending', Money.format(summary.totalPending), c.warning)),
                    ],
                  ),
                  const SizedBox(height: SNSpace.x3),
                  _tile(c, 'This Month', Money.format(summary.thisMonth), c.primary),
                  const SizedBox(height: SNSpace.section),

                  SNSectionLabel('Transactions'),
                  const SizedBox(height: SNSpace.x4),

                  if (summary.payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: SNSpace.x5),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: SNText.body.copyWith(color: c.mutedForeground),
                        ),
                      ),
                    )
                  else
                    ...summary.payments.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: SNSpace.x3),
                      child: _transactionCard(c, p),
                    )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(SNColorTokens c, String label, String value, Color color) {
    return SNCard(
      padding: const EdgeInsets.all(SNSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8, width: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: SNSpace.x3),
          Text(value, style: SNText.headingMd.copyWith(color: c.foreground)),
          Text(label, style: SNText.caption.copyWith(color: c.mutedForeground)),
        ],
      ),
    );
  }

  Widget _transactionCard(SNColorTokens c, OwnerPayment p) {
    final label = p.studentName.isNotEmpty
        ? '${p.studentName} · ${p.hostelName}'
        : p.hostelName;

    return SNCard(
      padding: const EdgeInsets.all(SNSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: SNText.bodyBold.copyWith(color: c.foreground))),
              Text(p.reference, style: SNText.caption.copyWith(color: c.mutedForeground)),
            ],
          ),
          const SizedBox(height: SNSpace.x4),
          _line(c, 'Gross', Money.format(p.amount)),
          const SizedBox(height: SNSpace.x2),
          _line(c, 'StayNest commission', '- ${Money.format(p.commission)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SNSpace.x3),
            child: Divider(height: 1, color: c.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net to you', style: SNText.bodyBold.copyWith(color: c.foreground)),
              Text(Money.format(p.netAmount), style: SNText.headingMd.copyWith(color: c.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(SNColorTokens c, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SNText.caption.copyWith(color: c.mutedForeground)),
        Text(value, style: SNText.body.copyWith(color: c.foreground)),
      ],
    );
  }
}
