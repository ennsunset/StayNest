// features/stays/presentation/my_stays_screen.dart
import 'package:staynest_mobile/design/primitives/sn_button.dart';
//
// Screen 24 — My Stays. Wired to real bookings API.
// Tabs: Current / Past. Shows real booking data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/features/payment/data/payments_repository.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

class MyStaysScreen extends ConsumerWidget {
  const MyStaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final bookingsAsync = ref.watch(myBookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          backgroundColor: c.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            ref.watch(myBookingsProvider).whenOrNull(
              data: (list) => list.any((b) => b.status == 'CHECKED_IN'),
            ) == true ? 'My Room' : 'My Stays',
            style: SNText.headingLg.copyWith(color: c.foreground),
          ),
          titleSpacing: SNSpace.screenX,
          toolbarHeight: 48,
          bottom: TabBar(
            labelColor: c.primary,
            unselectedLabelColor: c.mutedForeground,
            labelStyle: SNText.bodyBold,
            unselectedLabelStyle: SNText.body,
            indicatorColor: c.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: c.border,
            tabs: const [
              Tab(text: 'Current'),
              Tab(text: 'Past Bookings'),
            ],
          ),
        ),
        body: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SNErrorState(
              headline: 'Could not load bookings',
              onRetry: () => ref.invalidate(myBookingsProvider),
            ),
          ),
          data: (bookings) {
            final active = bookings.where((b) =>
              b.status == 'HELD' ||
              b.status == 'PENDING_PAYMENT' ||
              b.status == 'CONFIRMED' ||
              b.status == 'CHECKED_IN'
            ).toList();

            final past = bookings.where((b) =>
              b.status == 'COMPLETED' ||
              b.status == 'CANCELLED' ||
              b.status == 'EXPIRED' ||
              b.status == 'REFUNDED'
            ).toList();

            return TabBarView(
              children: [
                _CurrentStays(c: c, bookings: active, ref: ref),
                _PastStays(c: c, bookings: past),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CurrentStays extends StatelessWidget {
  const _CurrentStays({required this.c, required this.bookings, required this.ref});
  final SNColorTokens c;
  final List<Booking> bookings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: SNEmptyState(
          icon: Icons.hotel_outlined,
          headline: 'No active stays',
          actionLabel: 'Find a hostel',
          onAction: () => context.go('/home'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myBookingsProvider),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(SNSpace.screenX),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x4),
        itemBuilder: (_, i) => _StayCard(c: c, booking: bookings[i], ref: ref),
      ),
    );
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard({required this.c, required this.booking, required this.ref});
  final SNColorTokens c;
  final Booking booking;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final hostelName = booking.bed?.room?.hostelName ?? 'Hostel';
    final roomInfo = booking.bed?.room != null
        ? 'Room ${booking.bed!.room!.number} · ${booking.bed!.label}'
        : booking.bed?.label ?? '';

    return SNCard(
      padding: EdgeInsets.zero,
      onTap: () {
        context.push('/booking/${booking.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SNSpace.x5,
              vertical: SNSpace.x3,
            ),
            decoration: BoxDecoration(
              color: _statusColor(c).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SNRadius.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_outlined, size: 16, color: _statusColor(c)),
                    const SizedBox(width: SNSpace.x2),
                    Text(
                      _categoryLabel(),
                      style: SNText.microAction.copyWith(
                        color: _statusColor(c),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: SNSpace.x3, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(c).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(SNRadius.xs),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: SNText.microAction.copyWith(
                      color: _statusColor(c),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(SNSpace.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hostel image + name
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: booking.bed?.room?.imageUrl != null
                          ? Image.network(booking.bed!.room!.imageUrl!, width: 60, height: 60, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 60, height: 60,
                                decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.home_outlined, size: 24, color: c.mutedForeground)))
                          : Container(width: 60, height: 60,
                              decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.home_outlined, size: 24, color: c.mutedForeground)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hostelName, style: SNText.headingMd.copyWith(color: c.foreground, fontSize: 18)),
                          if (roomInfo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(roomInfo, style: SNText.caption.copyWith(color: c.mutedForeground)),
                            ),
                        ],
                      ),
                    ),
                    if (booking.isHeld || booking.status == 'PENDING_PAYMENT')
                      GestureDetector(
                        onTap: () => _showCancelSheet(context, c, booking, ref),
                        child: Icon(Icons.close_rounded, size: 20, color: c.mutedForeground),
                      ),
                  ],
                ),

                const SizedBox(height: SNSpace.x4),

                // Price + reference
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL', style: SNText.sectionLabel.copyWith(color: c.mutedForeground, fontSize: 10)),
                          const SizedBox(height: SNSpace.x1),
                          Text(
                            Money.format(booking.totalPesewas),
                            style: SNText.headingMd.copyWith(color: c.primary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REFERENCE', style: SNText.sectionLabel.copyWith(color: c.mutedForeground, fontSize: 10)),
                          const SizedBox(height: SNSpace.x1),
                          Text(
                            booking.reference,
                            style: SNText.bodyBold.copyWith(color: c.foreground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Hold countdown for HELD status
                if (booking.isHeld && booking.heldUntil != null) ...[
                  const SizedBox(height: SNSpace.x4),
                  Container(
                    padding: const EdgeInsets.all(SNSpace.x3),
                    decoration: BoxDecoration(
                      color: c.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(SNRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: c.warning),
                        const SizedBox(width: SNSpace.x2),
                        Text(
                          'Hold expires ${_timeLeft(booking.heldUntil!)}',
                          style: SNText.caption.copyWith(color: c.warning),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: SNSpace.x4),

                // Action buttons
                if (booking.status == 'PENDING_PAYMENT' || booking.isHeld) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(c: c, icon: Icons.description_outlined, label: 'View Details',
                          onTap: () => context.push('/booking/${booking.id}')),
                      ),
                      const SizedBox(width: SNSpace.x3),
                      Expanded(child: _PayNowAction(c: c, booking: booking, ref: ref)),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/booking/${booking.id}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 16, color: c.primaryForeground),
                                const SizedBox(width: 8),
                                Text('View Details', style: SNText.bodyBold.copyWith(color: c.primaryForeground, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push(Routes.reportIssue, extra: {'bookingId': booking.id}),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_outlined, size: 16, color: c.foreground),
                                const SizedBox(width: 8),
                                Text('Report Issue', style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Quick action strip for confirmed/checked-in
          if (booking.status == 'CONFIRMED' || booking.status == 'CHECKED_IN') ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniIcon(c: c, icon: Icons.person_add_outlined, label: 'Visitors',
                    color: const Color(0xFF6366F1),
                    onTap: () => context.push(Routes.visitors, extra: {'bookingId': booking.id, 'hostelName': hostelName})),
                  _MiniIcon(c: c, icon: Icons.electric_bolt_outlined, label: 'Utilities',
                    color: const Color(0xFFE8A33D),
                    onTap: () => context.push(Routes.utilityBills, extra: {'bookingId': booking.id})),
                  _MiniIcon(c: c, icon: Icons.description_outlined, label: 'Contract',
                    color: const Color(0xFF3FB68B),
                    onTap: () => context.push(Routes.digitalAgreement, extra: {
                      'bookingId': booking.id, 'bookingReference': booking.reference,
                      'hostelName': hostelName, 'roomLabel': roomInfo})),
                  _MiniIcon(c: c, icon: Icons.forum_outlined, label: 'Community',
                    color: const Color(0xFF0EA5E9),
                    onTap: () {
                      final hostelId = booking.bed?.room?.hostelId;
                      if (hostelId != null) context.push(Routes.communityBoard, extra: {'hostelId': hostelId, 'hostelName': hostelName});
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _categoryLabel() {
    return switch (booking.status) {
      'CONFIRMED' => 'ACTIVE STAY',
      'CHECKED_IN' => 'ACTIVE',
      'HELD' || 'PENDING_PAYMENT' => 'AWAITING PAYMENT',
      'CANCELLED' => 'CANCELLED',
      _ => booking.status,
    };
  }

  String _statusLabel() {
    return switch (booking.status) {
      'HELD' => 'HOLD ACTIVE',
      'PENDING_PAYMENT' => 'AWAITING PAYMENT',
      'CONFIRMED' => 'ACTIVE STAY',
      'CHECKED_IN' => 'CHECKED IN',
      _ => booking.status,
    };
  }

  Color _statusColor(SNColorTokens c) {
    return switch (booking.status) {
      'HELD' => c.warning,
      'PENDING_PAYMENT' => c.warning,
      'CONFIRMED' => c.success,
      'CHECKED_IN' => c.success,
      _ => c.mutedForeground,
    };
  }

  String _timeLeft(DateTime heldUntil) {
    final diff = heldUntil.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    if (diff.inMinutes < 1) return 'in ${diff.inSeconds}s';
    return 'in ${diff.inMinutes}m';
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.c, required this.icon, required this.label, required this.onTap, required this.color});
  final SNColorTokens c;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: SNText.microAction.copyWith(color: c.foreground, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.c,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final SNColorTokens c;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.muted,
          borderRadius: BorderRadius.circular(SNRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c.foreground),
            const SizedBox(width: SNSpace.x2),
            Text(label, style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PayNowAction extends StatefulWidget {
  const _PayNowAction({required this.c, required this.booking, required this.ref});
  final SNColorTokens c;
  final Booking booking;
  final WidgetRef ref;

  @override
  State<_PayNowAction> createState() => _PayNowActionState();
}

class _PayNowActionState extends State<_PayNowAction> {
  bool _loading = false;

  Future<void> _pay() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final repo = widget.ref.read(paymentsRepositoryProvider);
      final result = await repo.initialize(
        bookingId: widget.booking.id,
        callbackUrl: 'https://staynest.app/payment/callback',
      );

      if (!mounted) return;

      final hostelName = widget.booking.bed?.room?.hostelName ?? 'Hostel';
      final roomInfo = widget.booking.bed?.room != null
          ? 'Room ${widget.booking.bed!.room!.number} · ${widget.booking.bed!.label}'
          : widget.booking.bed?.label ?? '';

      context.push('/payment', extra: {
        'authorizationUrl': result.authorizationUrl,
        'reference': result.reference,
        'bookingId': widget.booking.id,
        'hostelName': hostelName,
        'roomLabel': roomInfo,
        'bedLabel': widget.booking.bed?.label ?? '',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initialize payment')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pay,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.c.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.c.primaryForeground,
                ),
              )
            else
              Icon(Icons.payment_rounded, size: 16, color: widget.c.primaryForeground),
            const SizedBox(width: SNSpace.x2),
            Text('Pay Now', style: SNText.bodyBold.copyWith(color: widget.c.primaryForeground, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

void _showCancelSheet(BuildContext context, SNColorTokens c, Booking booking, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    showDragHandle: false,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(SNRadius.lg)),
    ),
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, SNSpace.screenX),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: SNSpace.x6),
            Container(
              padding: const EdgeInsets.all(SNSpace.x5),
              decoration: BoxDecoration(
                color: c.destructive.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 32, color: c.destructive),
            ),
            const SizedBox(height: SNSpace.x5),
            Text('Cancel Booking?', style: SNText.headingLg.copyWith(color: c.foreground)),
            const SizedBox(height: SNSpace.x3),
            Text(
              'This will release your held bed at ${booking.bed?.room?.hostelName ?? "the hostel"}. Another student may book it immediately.',
              textAlign: TextAlign.center,
              style: SNText.body.copyWith(color: c.mutedForeground, height: 1.5),
            ),
            const SizedBox(height: SNSpace.x3),
            SNCard(
              padding: const EdgeInsets.all(SNSpace.x4),
              child: Row(
                children: [
                  Text('REF', style: SNText.sectionLabel.copyWith(color: c.mutedForeground, fontSize: 10)),
                  const SizedBox(width: SNSpace.x3),
                  Text(booking.reference, style: SNText.bodyBold.copyWith(color: c.foreground)),
                ],
              ),
            ),
            const SizedBox(height: SNSpace.x6),
            SNButton(
              label: 'Yes, Cancel Booking',
              variant: SNButtonVariant.destructive,
              onPressed: () async {
                Navigator.pop(sheetContext);
                try {
                  await ref.read(bookingsRepositoryProvider).cancel(booking.id);
                  ref.invalidate(myBookingsProvider);
                  ref.invalidate(bookingDetailProvider(booking.id));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
                  }
                } catch (e) {
                  ref.invalidate(myBookingsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not cancel booking')));
                  }
                }
              },
            ),
            const SizedBox(height: SNSpace.x3),
            SNButton(
              label: 'Keep My Booking',
              variant: SNButtonVariant.secondary,
              onPressed: () => Navigator.pop(sheetContext),
            ),
            const SizedBox(height: SNSpace.x4),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PastStays extends StatelessWidget {
  const _PastStays({required this.c, required this.bookings});
  final SNColorTokens c;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: SNEmptyState(
          icon: Icons.history_rounded,
          headline: 'No past stays',
          actionLabel: 'Find a hostel',
          onAction: () => context.go('/home'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(SNSpace.screenX),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x3),
      itemBuilder: (_, i) {
        final b = bookings[i];
        final hostelName = b.bed?.room?.hostelName ?? 'Hostel';
        return SNCard(
          onTap: () => context.push("/booking/${b.id}"),
          padding: const EdgeInsets.all(SNSpace.x4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SNSpace.x3),
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(SNRadius.sm),
                ),
                child: Icon(Icons.home_outlined, size: 20, color: c.mutedForeground),
              ),
              const SizedBox(width: SNSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hostelName, style: SNText.bodyBold.copyWith(color: c.foreground)),
                    Text(
                      b.reference,
                      style: SNText.caption.copyWith(color: c.mutedForeground),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.x2, vertical: 2),
                decoration: BoxDecoration(
                  color: b.status == 'CANCELLED' ? c.destructive.withValues(alpha: 0.1) : c.muted,
                  borderRadius: BorderRadius.circular(SNRadius.xs),
                ),
                child: Text(
                  b.status,
                  style: SNText.microAction.copyWith(
                    color: b.status == 'CANCELLED' ? c.destructive : c.mutedForeground,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
