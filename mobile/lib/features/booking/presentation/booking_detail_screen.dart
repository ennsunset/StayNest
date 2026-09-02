import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:staynest_mobile/features/messaging/data/messaging_repository.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';
// features/booking/presentation/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:printing/printing.dart';
import 'package:staynest_mobile/core/utils/receipt_generator.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/features/booking/presentation/refund_timeline_screen.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final async = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Booking', onBack: () => context.pop()),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: SNErrorState(
            headline: 'Could not load booking',
            onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
          ),
        ),
        data: (booking) => booking.status == 'CHECKED_IN' ? _TenantDashboard(booking: booking, bookingId: bookingId) : _Body(booking: booking, bookingId: bookingId),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.booking, required this.bookingId});
  final Booking booking;
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final hostelName = booking.bed?.room?.hostelName ?? 'Hostel';
    final roomInfo = booking.bed?.room != null
        ? 'Room ${booking.bed!.room!.number} - ${booking.bed!.label}'
        : booking.bed?.label ?? '';

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bookingDetailProvider(bookingId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.navClear,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          SNCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SNImage(url: booking.bed?.room?.imageUrl, height: 120, width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(SNRadius.lg))),
                Padding(
                  padding: const EdgeInsets.all(SNSpace.x5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hostelName, style: SNText.headingMd.copyWith(color: c.foreground)),
                          const SizedBox(height: SNSpace.x1),
                          Text(roomInfo, style: SNText.caption.copyWith(color: c.mutedForeground)),
                        ],
                      )),
                      _statusBadge(c, booking.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SNSpace.section),

          // Timeline
          _buildTimeline(c, booking),
          const SizedBox(height: SNSpace.section),

          // Agreement prompt
          if (booking.status == 'CONFIRMED' || booking.status == 'CHECKED_IN')
            GestureDetector(
              onTap: () => context.push(Routes.digitalAgreement, extra: {
                'bookingId': booking.id,
                'bookingReference': booking.reference,
                'hostelName': hostelName,
                'roomLabel': roomInfo,
              }),
              child: Container(
              padding: const EdgeInsets.all(SNSpace.x4),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(SNRadius.lg),
                border: Border.all(color: c.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: c.primary, size: 24),
                  const SizedBox(width: SNSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Digital Agreement', style: SNText.bodyBold.copyWith(color: c.foreground)),
                        const SizedBox(height: 2),
                        Text(booking.agreementSignedAt != null ? 'Lease signed' : 'Sign your lease to complete move-in', style: SNText.caption.copyWith(color: c.mutedForeground)),
                      ],
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: booking.agreementSignedAt != null ? c.success : c.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.agreementSignedAt != null ? 'View' : 'Sign',
                        style: SNText.bodyBold.copyWith(color: Colors.white, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            ),
          if (booking.status == 'CONFIRMED' || booking.status == 'CHECKED_IN')
            const SizedBox(height: SNSpace.section),

          // Reference
          SNCard(
            padding: const EdgeInsets.all(SNSpace.x4),
            onTap: () {
              Clipboard.setData(ClipboardData(text: booking.reference));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference copied'), duration: Duration(seconds: 2)),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('BOOKING REFERENCE', style: SNText.sectionLabel.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x1),
                  Text(booking.reference, style: SNText.mono.copyWith(color: c.foreground)),
                ]),
                Icon(Icons.copy_rounded, size: 18, color: c.mutedForeground),
              ],
            ),
          ),
          const SizedBox(height: SNSpace.section),

          // Price breakdown
          SNSectionLabel('Price Breakdown'),
          const SizedBox(height: SNSpace.x4),
          TransactionRow(label: 'Room fee', amountPesewas: booking.pricePesewas),
          if ((booking.bed?.room?.securityDepositPesewas ?? 0) > 0) ...[
            const SizedBox(height: SNSpace.x3),
            TransactionRow(label: 'Security Deposit (Refundable)', amountPesewas: booking.bed?.room?.securityDepositPesewas ?? 0),
          ],
          const SizedBox(height: SNSpace.x3),
          TransactionRow(label: 'StayNest Service Fee', amountPesewas: booking.platformFeePesewas),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SNSpace.x4),
            child: Divider(height: 1, color: c.border),
          ),
          TransactionRow(label: 'Total', amountPesewas: booking.totalPesewas, emphasised: true),

          // Installment status banner
          if (booking.isInstallment) ...[
            const SizedBox(height: SNSpace.x4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SNSpace.x4),
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(SNRadius.md),
                border: Border.all(color: c.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 18, color: c.primary),
                      const SizedBox(width: 8),
                      Text('Installment Plan', style: SNText.bodyBold.copyWith(color: c.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You paid ${Money.format((booking.totalPesewas / 2).round())} of ${Money.format(booking.totalPesewas)}',
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SNButton(
                          label: 'View Schedule',
                          variant: SNButtonVariant.secondary,
                          onPressed: () => context.push(Routes.installmentSchedule, extra: {
                            'bookingId': booking.id,
                            'hostelName': hostelName,
                            'roomLabel': roomInfo,
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SNButton(
                          label: 'Cancel Plan',
                          variant: SNButtonVariant.ghost,
                          onPressed: () => _showCancelInstallmentSheet(context, ref, booking, c),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: SNSpace.section),

          // Actions
          if (booking.status == 'CONFIRMED' || booking.status == 'CHECKED_IN') ...[
            SNButton(
              label: 'Show Access Pass',
              icon: Icons.qr_code_2_rounded,
              onPressed: () => context.push(Routes.qrCheckin, extra: {
                'bookingReference': booking.reference,
                'hostelName': hostelName,
                'roomId': roomInfo,
                'validUntil': 'June 2027',
              }),
            ),
            const SizedBox(height: SNSpace.x3),
            SNButton(
              label: 'Arrival Plan',
              variant: SNButtonVariant.secondary,
              icon: Icons.calendar_month_rounded,
              onPressed: () => context.push(Routes.moveInSchedule, extra: {
                'bookingId': bookingId,
                'moveInDate': booking.checkInDate != null ? DateTime.tryParse(booking.checkInDate!) : null,
                'hostelName': hostelName,
              }),
            ),
            const SizedBox(height: SNSpace.x3),
            SNButton(
              label: 'Message Owner',
              variant: SNButtonVariant.secondary,
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () async {
                final hostelId = booking.bed?.room?.hostelId;
                if (hostelId == null) return;
                try {
                  final hostelsRepo = ref.read(hostelsRepositoryProvider);
                  final hostel = await hostelsRepo.fetchById(hostelId);
                  if (hostel.ownerId == null || !context.mounted) return;
                  final msgRepo = ref.read(messagingRepositoryProvider);
                  final conv = await msgRepo.getOrCreateConversation(
                    hostelId: hostelId,
                    ownerId: hostel.ownerId!,
                  );
                  if (context.mounted) {
                    context.push('/messages/${conv.id}', extra: {'hostelName': hostelName, 'userId': ref.read(authNotifierProvider)?.id});
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: SNSpace.x3),
            SNButton(label: 'Download Receipt', variant: SNButtonVariant.secondary, onPressed: () async {
              final pdf = await ReceiptGenerator.generate(
                reference: booking.reference,
                hostelName: hostelName,
                roomInfo: roomInfo,
                pricePesewas: booking.pricePesewas,
                platformFeePesewas: booking.platformFeePesewas,
                totalPesewas: booking.totalPesewas,
                status: booking.status,
                createdAt: booking.createdAt,
              );
              await Printing.sharePdf(bytes: pdf, filename: 'StayNest-Receipt-${booking.reference}.pdf');
            }),
          ],
          if (booking.isHeld || booking.status == 'PENDING_PAYMENT') ...[
            const SizedBox(height: SNSpace.x3),
            SNButton(
              label: 'Cancel Booking',
              variant: SNButtonVariant.destructive,
              onPressed: () async {
                try {
                  await ref.read(bookingsRepositoryProvider).cancel(booking.id);
                  ref.invalidate(bookingDetailProvider(bookingId));
                  ref.invalidate(myBookingsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
                    context.pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    final msg = e is DioException && e.response?.data is Map
                        ? (e.response!.data as Map)['message'] ?? 'Could not cancel booking'
                        : 'Could not cancel booking';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg is List ? msg.first.toString() : msg.toString())));
                  }
                }
              },
            ),
          ],
          if (booking.status == 'CANCELLED' && booking.totalPesewas > 0) ...[
            const SizedBox(height: SNSpace.x3),
            SNButton(
              label: 'View Refund Status',
              variant: SNButtonVariant.secondary,
              onPressed: () => context.push('${Routes.refundTimeline}?bookingId=${booking.id}'),
            ),
          ],
          if (booking.status == 'COMPLETED') ...[
            const SizedBox(height: SNSpace.x3),
            SNButton(
              label: 'Leave a Review',
              icon: Icons.rate_review_outlined,
              onPressed: () {
                final hostelId = booking.bed?.room?.hostelId;
                if (hostelId != null) {
                  context.push(Routes.reviews, extra: {
                    'hostelId': hostelId,
                    'hostelName': hostelName,
                    'bookingId': booking.id,
                  });
                }
              },
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _statusBadge(SNColorTokens c, String status) {
    final Color bg; final Color fg;
    switch (status) {
      case 'CONFIRMED': case 'CHECKED_IN':
        bg = c.success.withValues(alpha: 0.15); fg = c.success;
      case 'HELD': case 'PENDING_PAYMENT':
        bg = c.warning.withValues(alpha: 0.15); fg = c.warning;
      case 'CANCELLED': case 'EXPIRED':
        bg = c.destructive.withValues(alpha: 0.15); fg = c.destructive;
      default:
        bg = c.muted; fg = c.mutedForeground;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.x3, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(SNRadius.xs)),
      child: Text(status, style: SNText.microAction.copyWith(color: fg, fontSize: 10)),
    );
  }

  Widget _buildTimeline(SNColorTokens c, Booking booking) {
    final steps = [
      _Step('Held', booking.createdAt, true),
      _Step('Paid', booking.isConfirmed || booking.status == 'CHECKED_IN' ? booking.createdAt : null,
          booking.isConfirmed || booking.status == 'CHECKED_IN'),
      _Step('Confirmed', booking.isConfirmed ? booking.createdAt : null,
          booking.isConfirmed || booking.status == 'CHECKED_IN'),
      _Step('Checked in', null, booking.status == 'CHECKED_IN'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SNSectionLabel('Status'),
      const SizedBox(height: SNSpace.x4),
      ...List.generate(steps.length, (i) {
        final s = steps[i]; final isLast = i == steps.length - 1;
        return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 24, child: Column(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.done ? c.primary : c.muted,
              border: s.done ? null : Border.all(color: c.border, width: 2),
            ), child: s.done ? Icon(Icons.check, size: 8, color: c.primaryForeground) : null),
            if (!isLast) Expanded(child: Container(width: 2, color: s.done ? c.primary : c.border)),
          ])),
          const SizedBox(width: SNSpace.x3),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: SNSpace.x5), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.label, style: SNText.bodyBold.copyWith(color: s.done ? c.foreground : c.mutedForeground)),
              if (s.at != null) Text(_fmt(s.at!), style: SNText.caption.copyWith(color: c.mutedForeground)),
            ],
          ))),
        ]));
      }),
    ]);
  }

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    return '${m[d.month-1]} ${d.day}, $h:${d.minute.toString().padLeft(2,"0")} ${d.hour >= 12 ? "PM" : "AM"}';
  }

  void _showCancelInstallmentSheet(BuildContext context, WidgetRef ref, Booking booking, SNColorTokens c) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SNSheetHandle(),
            const SizedBox(height: SNSpace.x2),
            Text('Cancel Installment Plan', style: SNText.headingMd),
            const SizedBox(height: 12),
            Text(
              'This will cancel your booking and release your bed. Any amount already paid will be eligible for a refund per the cancellation policy.',
              style: SNText.body.copyWith(color: c.mutedForeground, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: SNButton(
                label: 'Cancel Booking',
                variant: SNButtonVariant.primary,
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final repo = ref.read(bookingsRepositoryProvider);
                    await repo.cancel(booking.id, reason: 'Student cancelled installment plan');
                    if (context.mounted) {
                      ref.invalidate(bookingDetailProvider(booking.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking cancelled')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to cancel booking')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SNButton(
                label: 'Keep My Booking',
                variant: SNButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

}



class _TenantDashboard extends ConsumerWidget {
  const _TenantDashboard({required this.booking, required this.bookingId});
  final Booking booking;
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final user = ref.watch(authNotifierProvider);
    final hostelName = booking.bed?.room?.hostelName ?? 'Hostel';
    final roomInfo = booking.bed?.room != null
        ? 'Room ${booking.bed!.room!.number} · ${booking.bed!.label}'
        : booking.bed?.label ?? '';

    // Lease countdown
    final now = DateTime.now();
    final leaseEnd = now.add(const Duration(days: 120)); // TODO: from API
    final daysLeft = leaseEnd.difference(now).inDays;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bookingDetailProvider(bookingId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.navClear,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SNSpace.x5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.primary, c.primary.withValues(alpha: 0.85)],
                ),
                borderRadius: BorderRadius.circular(SNRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: SNSpace.x4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostelName,
                              style: SNText.headingMd.copyWith(color: Colors.white, fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              roomInfo,
                              style: SNText.body.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SNSpace.x5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4, vertical: SNSpace.x3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$daysLeft days remaining',
                          style: SNText.bodyBold.copyWith(color: Colors.white, fontSize: 13),
                        ),
                        Text(
                          booking.reference,
                          style: SNText.mono.copyWith(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SNSpace.section),

            // ── Installment Status (checked-in) ──
            if (booking.isInstallment) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SNSpace.x4),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(SNRadius.md),
                  border: Border.all(color: c.primary.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: c.primary),
                        const SizedBox(width: 8),
                        Text('Installment Plan', style: SNText.bodyBold.copyWith(color: c.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You paid ${Money.format((booking.totalPesewas / 2).round())} of ${Money.format(booking.totalPesewas)}',
                      style: SNText.caption.copyWith(color: c.mutedForeground),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SNButton(
                        label: 'View Payment Schedule',
                        variant: SNButtonVariant.secondary,
                        onPressed: () => context.push(Routes.installmentSchedule, extra: {
                          'bookingId': booking.id,
                          'hostelName': hostelName,
                          'roomLabel': roomInfo,
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SNSpace.section),
            ],

            // ── Quick Actions ──
            SNSectionLabel('Quick Actions'),
            const SizedBox(height: SNSpace.x4),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _actionTile(c, Icons.qr_code_2_rounded, 'Access\nPass', () {
                  context.push(Routes.qrCheckin, extra: {
                    'bookingReference': booking.reference,
                    'hostelName': hostelName,
                    'roomId': roomInfo,
                    'validUntil': 'June 2027',
                  });
                }),
                _actionTile(c, Icons.chat_bubble_outline_rounded, 'Message\nOwner', () async {
                  final hostelId = booking.bed?.room?.hostelId;
                  if (hostelId == null) return;
                  try {
                    final hostelsRepo = ref.read(hostelsRepositoryProvider);
                    final hostel = await hostelsRepo.fetchById(hostelId);
                    if (hostel.ownerId == null || !context.mounted) return;
                    final msgRepo = ref.read(messagingRepositoryProvider);
                    final conv = await msgRepo.getOrCreateConversation(
                      hostelId: hostelId,
                      ownerId: hostel.ownerId!,
                    );
                    if (context.mounted) {
                      context.push('/messages/${conv.id}', extra: {
                        'hostelName': hostelName,
                        'userId': ref.read(authNotifierProvider)?.id,
                      });
                    }
                  } catch (_) {}
                }),
                _actionTile(c, Icons.build_outlined, 'Report\nIssue', () {
                  context.push(Routes.reportIssue, extra: {'bookingId': booking.id});
                }),
                _actionTile(c, Icons.person_add_outlined, 'Visitors', () {
                  context.push(Routes.visitors, extra: {
                    'bookingId': booking.id,
                    'hostelName': hostelName,
                  });
                }),
                _actionTile(c, Icons.receipt_long_outlined, 'Payment\nHistory', () {
                  context.push(Routes.paymentHistory);
                }),
                _actionTile(c, Icons.download_outlined, 'Download\nReceipt', () async {
                  final pdf = await ReceiptGenerator.generate(
                    reference: booking.reference,
                    hostelName: hostelName,
                    roomInfo: roomInfo,
                    pricePesewas: booking.pricePesewas,
                    platformFeePesewas: booking.platformFeePesewas,
                    totalPesewas: booking.totalPesewas,
                    status: booking.status,
                    createdAt: booking.createdAt,
                  );
                  await Printing.sharePdf(bytes: pdf, filename: 'StayNest-Receipt-${booking.reference}.pdf');
                }),
                _actionTile(c, Icons.electric_bolt_outlined, 'Utility\nBills', () {
                  context.push(Routes.utilityBills, extra: {
                    'bookingId': booking.id,
                  });
                }),
                _actionTile(c, Icons.rate_review_outlined, 'Write\nReview', () {
                  final hostelId = booking.bed?.room?.hostelId;
                  if (hostelId != null) {
                    context.push(Routes.reviews, extra: {
                      'hostelId': hostelId,
                      'hostelName': hostelName,
                      'bookingId': booking.id,
                    });
                  }
                }),
                _actionTile(c, Icons.description_outlined, 'Digital\nContract', () {
                  context.push(Routes.digitalAgreement, extra: {
                    'bookingId': booking.id,
                    'bookingReference': booking.reference,
                    'hostelName': hostelName,
                    'roomLabel': roomInfo,
                  });
                }),
                _actionTile(c, Icons.calendar_month_rounded, 'Arrival\nPlan', () {
                  context.push(Routes.moveInSchedule, extra: {
                    'bookingId': booking.id,
                    'moveInDate': booking.checkInDate != null ? DateTime.tryParse(booking.checkInDate!) : null,
                    'hostelName': hostelName,
                  });
                }),
                _actionTile(c, Icons.campaign_outlined, 'Announce-\nments', () {
                  final hostelId = booking.bed?.room?.hostelId;
                  if (hostelId != null) {
                    context.push(Routes.announcements, extra: {
                      'hostelId': hostelId,
                      'hostelName': hostelName,
                    });
                  }
                }),
                _actionTile(c, Icons.forum_outlined, 'Community\nBoard', () {
                  final hostelId = booking.bed?.room?.hostelId;
                  if (hostelId != null) {
                    context.push(Routes.communityBoard, extra: {
                      'hostelId': hostelId,
                      'hostelName': hostelName,
                    });
                  }
                }),
                if (booking.isInstallment)
                  _actionTile(c, Icons.calendar_month_outlined, 'Installment\nPlan', () {
                    context.push(Routes.installmentSchedule, extra: {
                      'bookingId': booking.id,
                      'hostelName': hostelName,
                      'roomLabel': roomInfo,
                    });
                  }),
              ],
            ),
            const SizedBox(height: SNSpace.section),

            // ── Booking Details card ──
            SNSectionLabel('Booking Details'),
            const SizedBox(height: SNSpace.x4),
            SNCard(
              padding: const EdgeInsets.all(SNSpace.x4),
              child: Column(
                children: [
                  _detailRow(c, 'Reference', booking.reference),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: SNSpace.x3),
                    child: Divider(height: 1, color: c.border),
                  ),
                  TransactionRow(label: 'Room fee', amountPesewas: booking.pricePesewas),
                  if ((booking.bed?.room?.securityDepositPesewas ?? 0) > 0) ...[
                    const SizedBox(height: SNSpace.x3),
                    TransactionRow(label: 'Security Deposit (Refundable)', amountPesewas: booking.bed?.room?.securityDepositPesewas ?? 0),
                  ],
                  const SizedBox(height: SNSpace.x3),
                  TransactionRow(label: 'StayNest Service Fee', amountPesewas: booking.platformFeePesewas),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: SNSpace.x3),
                    child: Divider(height: 1, color: c.border),
                  ),
                  TransactionRow(label: 'Total', amountPesewas: booking.totalPesewas, emphasised: true),
                ],
              ),
            ),
            const SizedBox(height: SNSpace.section),

            // ── Roommate info ──
            SNSectionLabel('Roommate Info'),
            const SizedBox(height: SNSpace.x4),
            _RoommateCard(bookingId: booking.id),
          ],
        ),
      ),
    );
  }

  void _showCancelInstallmentSheet(BuildContext context, WidgetRef ref, Booking booking, SNColorTokens c) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SNSheetHandle(),
            const SizedBox(height: SNSpace.x2),
            Text('Cancel Installment Plan', style: SNText.headingMd),
            const SizedBox(height: 12),
            Text(
              'This will cancel your booking and release your bed. Any amount already paid will be eligible for a refund per the cancellation policy.',
              style: SNText.body.copyWith(color: c.mutedForeground, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: SNButton(
                label: 'Cancel Booking',
                variant: SNButtonVariant.primary,
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final repo = ref.read(bookingsRepositoryProvider);
                    await repo.cancel(booking.id, reason: 'Student cancelled installment plan');
                    if (context.mounted) {
                      ref.invalidate(bookingDetailProvider(booking.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking cancelled')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to cancel booking')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SNButton(
                label: 'Keep My Booking',
                variant: SNButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(SNColorTokens c, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.card,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, size: 20, color: c.foreground),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: SNText.microAction.copyWith(
              color: c.mutedForeground,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(SNColorTokens c, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SNText.body.copyWith(color: c.mutedForeground)),
        Text(value, style: SNText.mono.copyWith(color: c.foreground, fontSize: 13)),
      ],
    );
  }
}

class _RoommateCard extends ConsumerWidget {
  const _RoommateCard({required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;

    return FutureBuilder<List<dynamic>>(
      future: ref.read(bookingsRepositoryProvider).dio.get('/bookings/$bookingId/roommates').then((r) => r.data as List),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SNSkeleton(width: double.infinity, height: 72, radius: SNRadius.lg);
        }
        final roommates = snap.data ?? [];
        if (roommates.isEmpty) {
          return SNCard(
            padding: const EdgeInsets.all(SNSpace.x4),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.person_outline, color: c.mutedForeground),
                ),
                const SizedBox(width: SNSpace.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No roommate yet', style: SNText.bodyBold.copyWith(color: c.foreground)),
                      const SizedBox(height: 2),
                      Text('Bed is still available', style: SNText.caption.copyWith(color: c.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: roommates.map<Widget>((r) {
            final m = r as Map<String, dynamic>;
            final name = m['name'] as String? ?? 'Roommate';
            final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
            final checkedIn = m['checkedIn'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: SNSpace.x3),
              child: SNCard(
                onTap: () => _showRoommateSheet(context, ref, m),
                padding: const EdgeInsets.all(SNSpace.x4),
                child: Row(
                  children: [
                    SNAvatar(size: SNSize.avatarSm, initials: initials),
                    const SizedBox(width: SNSpace.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: SNText.bodyBold.copyWith(color: c.foreground)),
                          const SizedBox(height: 2),
                          Text(
                            m['level'] != null ? '${m['level']} · ${m['university'] ?? ''}' : 'Student',
                            style: SNText.caption.copyWith(color: c.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    SNBadge(
                      label: checkedIn ? 'Moved in' : 'Confirmed',
                      tone: checkedIn ? SNStatusTone.success : SNStatusTone.neutral,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }



  void _showRoommateSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> m) {
    final c = context.sn;
    final name = m['name'] as String? ?? 'Roommate';
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final checkedIn = m['checkedIn'] == true;
    final peerId = m['userId'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              SNAvatar(size: 64.0, initials: initials),
              const SizedBox(height: 16),
              Text(name, style: SNText.headingMd.copyWith(color: c.foreground)),
              const SizedBox(height: 4),
              Text(
                m['level'] != null ? '${m['level']} · ${m['university'] ?? ''}' : 'Student',
                style: SNText.body.copyWith(color: c.mutedForeground),
              ),
              const SizedBox(height: 8),
              SNBadge(
                label: checkedIn ? 'Moved in' : 'Confirmed',
                tone: checkedIn ? SNStatusTone.success : SNStatusTone.neutral,
              ),
              const SizedBox(height: 24),
              if (peerId != null)
                SNButton(
                  label: 'Message Roommate',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final dio = ref.read(bookingsRepositoryProvider).dio;
                      final res = await dio.post('/messaging/conversations/direct', data: {'peerId': peerId});
                      final convId = (res.data as Map<String, dynamic>)['id'];
                      if (context.mounted) {
                        context.push('/messages/$convId', extra: {
                          'hostelName': name,
                          'userId': ref.read(authNotifierProvider)?.id,
                        });
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not start conversation')),
                        );
                      }
                    }
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step { const _Step(this.label, this.at, this.done); final String label; final DateTime? at; final bool done; }
