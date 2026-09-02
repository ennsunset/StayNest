// features/booking/presentation/booking_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/receipt_generator.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/app/router.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({
    super.key,
    this.reference = '',
    this.hostelName = '',
    this.roomLabel = '',
    this.bedLabel = '',
  });

  final String reference;
  final String hostelName;
  final String roomLabel;
  final String bedLabel;

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  String? _selectedDate;
  DateTime? _savedDate;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDate();
  }

  Future<void> _loadDate() async {
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final booking = await repo.fetchByReference(widget.reference);
      if (mounted && booking.checkInDate != null) {
        final dt = DateTime.tryParse(booking.checkInDate!);
        if (dt != null) {
          setState(() {
            final m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            _savedDate = dt;
            _selectedDate = m[dt.month] + ' ' + dt.day.toString();
            _loaded = true;
          });
        }
      }
    } catch (_) {}
  }

  String get reference => widget.reference;
  String get hostelName => widget.hostelName;
  String get roomLabel => widget.roomLabel;
  String get bedLabel => widget.bedLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    final bodyText = hostelName.isNotEmpty
        ? "Congratulations! You've successfully booked your room at $hostelName. Your digital contract is ready for signing."
        : 'Your bed has been reserved. See you on move-in day!';

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(SNSpace.screenX),
          child: SNMoment(
            icon: Icons.check_rounded,
            headline: 'Booking Confirmed!',
            body: bodyText,
            tone: SNStatusTone.success,
            primaryAction: SNButton(
              label: 'Sign Digital Agreement',
              icon: Icons.description_outlined,
              onPressed: () => context.push(Routes.digitalAgreement, extra: {
                'bookingId': reference, // will be resolved by screen
                'bookingReference': reference,
                'hostelName': hostelName,
                'roomLabel': roomLabel,
              }),
            ),
            secondaryAction: SNButton(
              label: 'View My Bookings',
              variant: SNButtonVariant.secondary,
              onPressed: () => context.go(Routes.myStays),
            ),
            footer: Column(
              children: [
                const SizedBox(height: SNSpace.x3),
                SNButton(
                  label: 'Download Receipt',
                  variant: SNButtonVariant.ghost,
                  icon: Icons.download_outlined,
                  onPressed: () async {
                    try {
                      final repo = ref.read(bookingsRepositoryProvider);
                      final booking = await repo.fetchByReference(reference);
                      final hostel = booking.bed?.room?.hostelName ?? hostelName;
                      final room = booking.bed?.room != null
                          ? 'Room ${booking.bed!.room!.number} - ${booking.bed!.label}'
                          : roomLabel;
                      final pdf = await ReceiptGenerator.generate(
                        reference: booking.reference,
                        hostelName: hostel,
                        roomInfo: room,
                        pricePesewas: booking.pricePesewas,
                        platformFeePesewas: booking.platformFeePesewas,
                        totalPesewas: booking.totalPesewas,
                        status: booking.status,
                        createdAt: booking.createdAt,
                      );
                      await Printing.sharePdf(
                        bytes: pdf,
                        filename: 'StayNest-Receipt-${booking.reference}.pdf',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not generate receipt')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: SNSpace.x5),
                SNCard(
                  padding: const EdgeInsets.all(SNSpace.x5),
                  child: Column(
                    children: [
                      Text(
                        'BOOKING REFERENCE',
                        style: SNText.sectionLabel.copyWith(color: c.mutedForeground),
                      ),
                      const SizedBox(height: SNSpace.x3),
                      Text(
                        reference.isNotEmpty ? reference : 'STN-XXXX-XXXX',
                        style: SNText.mono.copyWith(color: c.foreground, fontSize: 20),
                      ),
                      const SizedBox(height: SNSpace.x4),
                      if (roomLabel.isNotEmpty) ...[
                        Text(
                          roomLabel,
                          style: SNText.body.copyWith(color: c.mutedForeground),
                        ),
                        const SizedBox(height: SNSpace.x3),
                      ],
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _savedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            try {
                              final repo = ref.read(bookingsRepositoryProvider);
                              final booking = await repo.fetchByReference(reference);
                              await repo.updateCheckInDate(
                                booking.id,
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
                              );
                              setState(() {
                                final m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                _savedDate = picked;
                                _selectedDate = m[picked.month] + ' ' + picked.day.toString();
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Move-in date updated!')),
                                );
                              }
                            } catch (_) {}
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CHECK-IN', style: SNText.sectionLabel.copyWith(color: c.primary)),
                            Row(
                              children: [
                                Text(
                                  _selectedDate != null ? _selectedDate!.toUpperCase() : 'TAP TO SET DATE',
                                  style: SNText.caption.copyWith(color: c.primary, fontWeight: _selectedDate != null ? FontWeight.w900 : FontWeight.w500),
                                ),
                                const SizedBox(width: 4),
                                Icon(_selectedDate != null ? Icons.check_circle_outline : Icons.edit_calendar_outlined, size: 14, color: c.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            ),
            // Back button
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => context.go(Routes.myStays),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.muted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 20, color: c.foreground),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
