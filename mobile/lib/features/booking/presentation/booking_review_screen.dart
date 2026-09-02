// features/booking/presentation/booking_review_screen.dart
//
// Screen 20 — Booking Review (wired to real API).
// Shows price from room data. On "Hold my bed" → POST /bookings.
// On 409 → BedTakenScreen. On success → BookingConfirmationScreen.
//
// Trap: every amount comes from the server. Client sends bed_id only.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_date_picker.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/features/payment/data/payments_repository.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

class BookingReviewScreen extends ConsumerStatefulWidget {
  const BookingReviewScreen({
    super.key,
    required this.bedId,
    required this.bedLabel,
    required this.roomNumber,
    required this.roomType,
    required this.pricePesewas,
    required this.hostelName,
    this.securityDepositPesewas = 0,
    this.hostelId,
    this.hostelImageUrl,
    this.roomId,
    this.bookingMode = 'FLEXIBLE',
    this.semesterPricePesewas,
  });

  final String bedId;
  final String bedLabel;
  final String roomNumber;
  final String roomType;
  final int pricePesewas;
  final String hostelName;
  final int securityDepositPesewas;
  final String? hostelId;
  final String? hostelImageUrl;
  final String? roomId;
  final String bookingMode;
  final int? semesterPricePesewas;

  @override
  ConsumerState<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> {
  bool _agreed = false;
  bool _submitting = false;
  bool _installmentEligible = false;
  bool _useInstallment = false;
  bool _checkingEligibility = false;

  // Platform fee: 5% (matches backend)
  late String _selectedDuration = widget.bookingMode == 'FULL_YEAR_ONLY' ? 'FULL_YEAR' : 'SEMESTER_1';
  DateTime? _checkInDate; // null = not set yet
  String? _hostelImageUrl;

  // pricePesewas = per-semester (base unit), full year = 2x
  int get _activePricePesewas => _selectedDuration == 'FULL_YEAR'
      ? widget.pricePesewas * 2
      : widget.pricePesewas;

  int get _platformFeePesewas => (_activePricePesewas * 0.05).round();
  int get _securityDepositPesewas => widget.securityDepositPesewas;
  int get _totalPesewas => _activePricePesewas + _securityDepositPesewas + _platformFeePesewas;

  bool get _showDurationToggle => widget.bookingMode == 'FLEXIBLE';

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    // Fetch hostel image
    if (widget.hostelId != null) {
      ref.read(hostelsRepositoryProvider).fetchById(widget.hostelId!).then((h) {
        if (mounted && h.imageUrls.isNotEmpty) setState(() => _hostelImageUrl = h.imageUrls.first);
      }).catchError((_) {});
    }
    if (widget.hostelId == null) return;
    setState(() => _checkingEligibility = true);
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final result = await repo.checkInstallmentEligibility(widget.hostelId!);
      if (mounted) {
        setState(() {
          _installmentEligible = result['eligible'] == true;
          _checkingEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingEligibility = false);
    }
  }

  // Amount to pay now: half if installment, full otherwise
  int get _payNowPesewas => _useInstallment ? (_totalPesewas / 2).round() : _totalPesewas;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Review Booking',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SNSpace.screenX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  _buildSummaryCard(c),
                  const SizedBox(height: SNSpace.section),

                  // Stay section
                  SNSectionLabel('Stay'),
                  const SizedBox(height: SNSpace.x4),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showSNDatePicker(
                        context,
                        initialDate: _checkInDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _checkInDate = picked);
                    },
                    child: _infoRow(c, 'Check-in', _checkInDate != null ? _formatDate(_checkInDate!) : 'Tap to set date', trailing: Icon(Icons.calendar_today, size: 16, color: c.primary)),
                  ),
                  const SizedBox(height: SNSpace.x3),
                  _buildDurationRow(c),
                  const SizedBox(height: SNSpace.section),

                  // Price breakdown — amounts from room price + computed fee
                  SNSectionLabel('Price Breakdown'),
                  const SizedBox(height: SNSpace.x4),
                  TransactionRow(label: 'Room fee', amountPesewas: _activePricePesewas),
                  if (_securityDepositPesewas > 0)
                    TransactionRow(label: 'Security Deposit (Refundable)', amountPesewas: _securityDepositPesewas),
                  TransactionRow(label: 'StayNest Service Fee', amountPesewas: _platformFeePesewas),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: SNSpace.x4),
                    child: Divider(height: 1, color: c.border),
                  ),
                  TransactionRow(
                    label: 'Total',
                    amountPesewas: _totalPesewas,
                    emphasised: true,
                  ),

                  // Installment option (only for full-year returning residents)
                  if (_installmentEligible && _selectedDuration == 'FULL_YEAR') ...[
                    const SizedBox(height: SNSpace.section),
                    SNSectionLabel('Payment Plan'),
                    const SizedBox(height: SNSpace.x4),
                    _buildPaymentPlanCard(c, false, 'Pay in full', Money.format(_totalPesewas), null),
                    const SizedBox(height: SNSpace.x3),
                    _buildPaymentPlanCard(
                      c,
                      true,
                      'Pay in 2 installments',
                      '${Money.format((_totalPesewas / 2).round())} now',
                      '${Money.format(_totalPesewas - (_totalPesewas / 2).round())} due in 2 months',
                    ),
                  ],
                  const SizedBox(height: SNSpace.section),

                  // Cancellation policy
                  SNCard(
                    tinted: false,
                    padding: const EdgeInsets.all(SNSpace.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Free cancellation within 24 hours of booking. '
                          'After that, a 10% fee applies.',
                          style: SNText.caption.copyWith(
                            color: c.mutedForeground,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: SNSpace.x3),
                        GestureDetector(
                          onTap: () {
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
                                    Text('Cancellation Policy', style: SNText.headingMd),
                                    const SizedBox(height: 16),
                                    Text('You may cancel your booking at any time before check-in. Once a booking is cancelled, the bed is released immediately and may be booked by another student. Refund eligibility depends on when the cancellation is made relative to the check-in date.', style: SNText.body),
                                    const SizedBox(height: 24),
                                    SizedBox(width: double.infinity, child: SNButton(label: 'Got it', onPressed: () => Navigator.pop(context))),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Read full policy',
                            style: SNText.bodyBold.copyWith(color: c.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SNSpace.x5),

                  // Terms checkbox
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _agreed,
                            onChanged: (v) => setState(() => _agreed = v ?? false),
                            activeColor: c.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: SNSpace.x3),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: SNText.caption.copyWith(color: c.mutedForeground),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms',
                                  style: SNText.caption.copyWith(color: c.primary),
                                ),
                                const TextSpan(text: ' and the '),
                                TextSpan(
                                  text: 'Cancellation Policy',
                                  style: SNText.caption.copyWith(color: c.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky footer
          Container(
            padding: const EdgeInsets.all(SNSpace.screenX),
            decoration: BoxDecoration(
              color: c.card,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SafeArea(
              top: false,
              child: SNButton(
                label: _useInstallment ? 'Hold my bed · ${Money.format(_payNowPesewas)} (1st)' : 'Hold my bed · ${Money.format(_totalPesewas)}',
                isLoading: _submitting,
                onPressed: _agreed ? _holdBed : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _holdBed() async {
    setState(() => _submitting = true);

    try {
      // 1. Hold the bed
      final bookingsRepo = ref.read(bookingsRepositoryProvider);
      final booking = await bookingsRepo.holdBed(widget.bedId, duration: _selectedDuration, checkInDate: _checkInDate?.toIso8601String().split('T').first, paymentType: _useInstallment ? 'INSTALLMENT' : 'FULL');

      if (!mounted) return;

      // 2. Initialize payment
      final paymentsRepo = ref.read(paymentsRepositoryProvider);
      final payment = await paymentsRepo.initialize(
        bookingId: booking.id,
        callbackUrl: 'https://staynest.app/payment/callback',
      );

      if (!mounted) return;

      // 3. Open Paystack checkout
      context.push('/payment', extra: {
        'authorizationUrl': payment.authorizationUrl,
        'reference': payment.reference,
        'bookingId': booking.id,
        'hostelName': widget.hostelName,
        'roomLabel': 'Room ${widget.roomNumber} · ${widget.bedLabel}',
        'bedLabel': widget.bedLabel,
      });

      setState(() => _submitting = false);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);

      if (e.response?.statusCode == 409) {
        context.go(Routes.bedTaken, extra: {
          'roomId': widget.roomId,
          'hostelId': widget.hostelId,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            e.response?.data?['message'] ?? 'Something went wrong. Please try again.',
          )),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  Widget _buildPaymentPlanCard(SNColorTokens c, bool isInstallment, String title, String amount, String? subtitle) {
    final selected = _useInstallment == isInstallment;
    return GestureDetector(
      onTap: () => setState(() => _useInstallment = isInstallment),
      child: Container(
        padding: const EdgeInsets.all(SNSpace.x4),
        decoration: BoxDecoration(
          color: selected ? c.primary.withOpacity(0.05) : c.card,
          borderRadius: BorderRadius.circular(SNRadius.md),
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? c.primary : c.border, width: 2),
                color: selected ? c.primary : Colors.transparent,
              ),
              child: selected
                  ? Icon(Icons.check, size: 14, color: c.primaryForeground)
                  : null,
            ),
            const SizedBox(width: SNSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SNText.bodyBold.copyWith(color: c.foreground)),
                  const SizedBox(height: 2),
                  Text(amount, style: SNText.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: SNText.caption.copyWith(color: c.mutedForeground)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SNColorTokens c) {
    return SNCard(
      padding: const EdgeInsets.all(SNSpace.x5),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SNRadius.sm),
            child: _hostelImageUrl != null
              ? Image.network(_hostelImageUrl!, width: 64, height: 64, fit: BoxFit.cover)
              : Container(width: 64, height: 64, color: Colors.grey[200], child: const Icon(Icons.image_outlined, color: Colors.grey)),
          ),
          const SizedBox(width: SNSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.hostelName,
                        style: SNText.headingMd.copyWith(color: c.foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const VerifiedBadge(),
                  ],
                ),
                const SizedBox(height: SNSpace.x1),
                Text(
                  'Room ${widget.roomNumber} · ${widget.bedLabel}',
                  style: SNText.caption.copyWith(color: c.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationRow(SNColorTokens c) {
    final durationLabel = _selectedDuration == 'FULL_YEAR' ? 'Full Academic Year' : 'One Semester';
    if (!_showDurationToggle) {
      final fixed = widget.bookingMode == 'YEAR_ONLY' ? 'Full Academic Year' : 'One Semester';
      return _infoRow(c, 'Duration', fixed);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Duration', style: SNText.body.copyWith(color: c.mutedForeground)),
        Container(
          decoration: BoxDecoration(
            color: c.muted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(SNRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _durationChip(c, '1 Semester', 'SEMESTER_1'),
              _durationChip(c, 'Full Year', 'FULL_YEAR'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _durationChip(SNColorTokens c, String label, String value) {
    final selected = _selectedDuration == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(SNRadius.sm),
        ),
        child: Text(
          label,
          style: SNText.caption.copyWith(
            color: selected ? c.primaryForeground : c.mutedForeground,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _infoRow(SNColorTokens c, String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SNText.body.copyWith(color: c.mutedForeground)),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(child: Text(value, style: SNText.bodyBold.copyWith(color: c.foreground), overflow: TextOverflow.ellipsis)),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ],
    );
  }
}
