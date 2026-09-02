import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';

part 'refund_timeline_screen.g.dart';

@riverpod
Future<RefundStatus?> refundStatus(Ref ref, String bookingId) {
  return ref.read(bookingsRepositoryProvider).getRefund(bookingId);
}

class RefundTimelineScreen extends ConsumerWidget {
  const RefundTimelineScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final asyncRefund = ref.watch(refundStatusProvider(bookingId));

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Refund Status',
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      body: asyncRefund.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: SNEmptyState(
            icon: Icons.error_outline,
            headline: 'Failed to load refund',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(refundStatusProvider(bookingId)),
          ),
        ),
        data: (refund) {
          if (refund == null) {
            return Center(
              child: SNEmptyState(
                icon: Icons.receipt_long_outlined,
                headline: 'No refund for this booking',
                actionLabel: 'Go back',
                onAction: () => context.pop(),
              ),
            );
          }
          return _RefundBody(refund: refund);
        },
      ),
    );
  }
}

class _RefundBody extends StatelessWidget {
  const _RefundBody({required this.refund});
  final RefundStatus refund;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final stages = _buildStages(refund);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.navClear,
      ),
      children: [
        // ── Summary card ──
        Container(
          padding: const EdgeInsets.all(SNSpace.x6),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2B41),
            borderRadius: BorderRadius.circular(SNRadius.xxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REFUND AMOUNT', style: SNText.microAction.copyWith(color: Colors.white.withOpacity(0.5), letterSpacing: 2)),
              const SizedBox(height: SNSpace.x2),
              Text(Money.format(refund.amountPesewas), style: SNText.headingLg.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: SNSpace.x4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HOSTEL', style: SNText.microAction.copyWith(color: Colors.white.withOpacity(0.4), letterSpacing: 2)),
                        const SizedBox(height: SNSpace.x1),
                        Text(refund.hostelName, style: SNText.body.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('REF', style: SNText.microAction.copyWith(color: Colors.white.withOpacity(0.4), letterSpacing: 2)),
                      const SizedBox(height: SNSpace.x1),
                      Text(refund.reference, style: SNText.caption.copyWith(color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: SNSpace.section),

        // ── Timeline ──
        Text('REFUND PROGRESS', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 2, fontWeight: FontWeight.w800)),
        const SizedBox(height: SNSpace.x4),
        ...stages.asMap().entries.map((e) {
          final idx = e.key;
          final stage = e.value;
          final isLast = idx == stages.length - 1;
          return _TimelineStep(stage: stage, isLast: isLast);
        }),

        // ── Rejected reason ──
        if (refund.status == 'REJECTED' && refund.rejectReason != null) ...[
          const SizedBox(height: SNSpace.x6),
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(SNRadius.sm),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: SNSpace.x3),
                Expanded(
                  child: Text(refund.rejectReason!, style: SNText.caption.copyWith(color: const Color(0xFFDC2626))),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<_Stage> _buildStages(RefundStatus r) {
    final stages = <_Stage>[
      _Stage(
        title: 'Refund Requested',
        subtitle: 'Your refund has been submitted for review',
        date: r.createdAt,
        state: _StageState.completed,
      ),
    ];

    if (r.status == 'REJECTED') {
      stages.add(_Stage(title: 'Rejected', subtitle: r.rejectReason ?? 'Refund was rejected', date: r.updatedAt, state: _StageState.rejected));
      return stages;
    }

    final isApproved = r.status == 'APPROVED' || r.status == 'PROCESSING' || r.status == 'REFUNDED';
    stages.add(_Stage(
      title: 'Approved',
      subtitle: 'Owner has approved your refund',
      date: r.approvedAt,
      state: isApproved ? _StageState.completed : _StageState.pending,
    ));

    final isProcessing = r.status == 'PROCESSING' || r.status == 'REFUNDED';
    stages.add(_Stage(
      title: 'Processing',
      subtitle: 'Payment provider is processing the refund',
      date: isProcessing ? r.updatedAt : null,
      state: isProcessing ? _StageState.completed : (isApproved ? _StageState.active : _StageState.pending),
    ));

    stages.add(_Stage(
      title: 'Refunded',
      subtitle: 'Amount has been returned to your account',
      date: r.refundedAt,
      state: r.status == 'REFUNDED' ? _StageState.completed : (isProcessing ? _StageState.active : _StageState.pending),
    ));

    return stages;
  }
}

enum _StageState { pending, active, completed, rejected }

class _Stage {
  _Stage({required this.title, required this.subtitle, this.date, required this.state});
  final String title;
  final String subtitle;
  final DateTime? date;
  final _StageState state;
  DateTime? get updatedAt => date;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.stage, required this.isLast});
  final _Stage stage;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    Color dotColor;
    IconData? dotIcon;
    switch (stage.state) {
      case _StageState.completed:
        dotColor = const Color(0xFF16A34A);
        dotIcon = Icons.check;
        break;
      case _StageState.active:
        dotColor = c.primary;
        dotIcon = null;
        break;
      case _StageState.rejected:
        dotColor = const Color(0xFFDC2626);
        dotIcon = Icons.close;
        break;
      case _StageState.pending:
        dotColor = c.border;
        dotIcon = null;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: stage.state == _StageState.pending ? Colors.transparent : dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: dotIcon != null
                      ? Icon(dotIcon, color: Colors.white, size: 16)
                      : (stage.state == _StageState.active
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                              ),
                            )
                          : null),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: stage.state == _StageState.completed ? const Color(0xFF16A34A) : c.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: SNSpace.x3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: SNSpace.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: SNText.bodyBold.copyWith(
                      color: stage.state == _StageState.pending ? c.mutedForeground : c.foreground,
                    ),
                  ),
                  const SizedBox(height: SNSpace.x1),
                  Text(
                    stage.subtitle,
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
                  if (stage.date != null) ...[
                    const SizedBox(height: SNSpace.x1),
                    Text(
                      DateFormat('MMM d, yyyy \u2022 hh:mm a').format(stage.date!),
                      style: SNText.caption.copyWith(color: c.mutedForeground.withOpacity(0.6), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
