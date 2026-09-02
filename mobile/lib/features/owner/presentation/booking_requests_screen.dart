// features/owner/presentation/booking_requests_screen.dart
//
// Screen 43 — Booking Requests. Wired to GET /owner/bookings + accept/decline.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

part 'booking_requests_screen.g.dart';

@riverpod
Future<List<OwnerBooking>> pendingBookings(Ref ref) {
  return ref.read(ownerRepositoryProvider).fetchBookings(status: 'CONFIRMED');
}

class BookingRequestsScreen extends ConsumerWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final bookingsAsync = ref.watch(pendingBookingsProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Booking Requests',
        onBack: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () => ref.refresh(pendingBookingsProvider.future),
        child: bookingsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(SNSpace.screenX),
            children: List.generate(3, (_) => const Padding(
              padding: EdgeInsets.only(bottom: SNSpace.x4),
              child: SNSkeleton(width: double.infinity, height: 180, radius: SNRadius.lg),
            )),
          ),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(SNSpace.screenX),
                child: SNEmptyState(
                  headline: 'Could not load requests',
                  body: e.toString(),
                  icon: Icons.error_outline,
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(pendingBookingsProvider),
                ),
              ),
            ],
          ),
          data: (bookings) => bookings.isEmpty
              ? Center(
                  child: SNEmptyState(
                    icon: Icons.inbox_outlined,
                    headline: 'No pending requests',
                    actionLabel: 'Back to dashboard',
                    onAction: () => context.pop(),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(SNSpace.screenX),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x4),
                  itemBuilder: (_, i) => _RequestCard(booking: bookings[i]),
                ),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.booking});
  final OwnerBooking booking;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _accepting = false;
  bool _declining = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref.read(ownerRepositoryProvider).acceptBooking(widget.booking.id);
      if (!mounted) return;
      ref.invalidate(pendingBookingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ' + e.toString())),
      );
    }
  }

  Future<void> _showDeclineSheet() async {
    final reasonCtl = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = ctx.sn;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            SNSpace.screenX, SNSpace.x5, SNSpace.screenX,
            MediaQuery.of(ctx).viewInsets.bottom + SNSpace.x5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: SNSpace.x5),
              Text('Decline Reason', style: SNText.headingMd.copyWith(color: c.foreground)),
              const SizedBox(height: SNSpace.x2),
              Text('A reason is required when declining a booking.',
                  style: SNText.caption.copyWith(color: c.mutedForeground)),
              const SizedBox(height: SNSpace.x4),
              SNInput(
                label: 'Reason',
                hint: 'e.g. Room under maintenance',
                controller: reasonCtl,
                maxLines: 3,
              ),
              const SizedBox(height: SNSpace.x5),
              SNButton(
                label: 'Confirm Decline',
                variant: SNButtonVariant.destructive,
                onPressed: () {
                  if (reasonCtl.text.trim().isNotEmpty) {
                    Navigator.of(ctx).pop(reasonCtl.text.trim());
                  }
                },
              ),
              const SizedBox(height: SNSpace.x3),
            ],
          ),
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _declining = true);
    try {
      await ref.read(ownerRepositoryProvider).declineBooking(widget.booking.id, reason);
      if (!mounted) return;
      ref.invalidate(pendingBookingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking declined')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _declining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ' + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final b = widget.booking;
    final initials = b.studentName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return SNCard(
      padding: const EdgeInsets.all(SNSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SNAvatar(size: SNSize.avatarSm, initials: initials),
                  const SizedBox(width: SNSpace.x3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.studentName, style: SNText.bodyBold.copyWith(color: c.foreground)),
                      Text(b.studentEmail, style: SNText.caption.copyWith(color: c.mutedForeground)),
                    ],
                  ),
                ],
              ),
              Text(b.reference, style: SNText.caption.copyWith(color: c.mutedForeground)),
            ],
          ),
          const SizedBox(height: SNSpace.x4),
          Text(
            b.hostelName + ' · Room ' + b.roomNumber + ' · ' + b.bedLabel,
            style: SNText.body.copyWith(color: c.mutedForeground),
          ),
          const SizedBox(height: SNSpace.x2),
          Text(
            Money.format(b.pricePesewas),
            style: SNText.headingMd.copyWith(color: c.foreground),
          ),
          const SizedBox(height: SNSpace.x5),

          Row(
            children: [
              Expanded(
                child: SNButton(
                  label: 'Accept',
                  isLoading: _accepting,
                  onPressed: _accepting || _declining ? null : _accept,
                ),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(
                child: SNButton(
                  label: 'Decline',
                  variant: SNButtonVariant.ghost,
                  isLoading: _declining,
                  onPressed: _accepting || _declining ? null : _showDeclineSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
