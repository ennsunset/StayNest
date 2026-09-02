// features/payment/presentation/payment_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:staynest_mobile/core/utils/receipt_generator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/payment/data/payments_repository.dart';

part 'payment_history_screen.g.dart';

@riverpod
Future<PaymentHistoryResult> paymentHistory(Ref ref) {
  return ref.read(paymentsRepositoryProvider).getMyHistory();
}

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final asyncHistory = ref.watch(paymentHistoryProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Payment History',
        onBack: () => context.pop(),
      ),
      body: asyncHistory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: SNEmptyState(
            icon: Icons.error_outline,
            headline: 'Failed to load payments',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(paymentHistoryProvider),
          ),
        ),
        data: (result) {
          if (result.payments.isEmpty) {
            return Center(
              child: SNEmptyState(
                icon: Icons.receipt_long_outlined,
                headline: 'No payments yet',
                actionLabel: 'Find a hostel',
                onAction: () => context.go('/'),
              ),
            );
          }
          return _HistoryBody(result: result);
        },
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.result});
  final PaymentHistoryResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final grouped = _groupByMonth(result.payments);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.navClear,
      ),
      children: [
        // ── Dark summary card ──
        _SummaryCard(totalPesewas: result.totalPaidYearPesewas),
        const SizedBox(height: SNSpace.section),
        // ── Timeline ──
        ...grouped.entries.expand((entry) => [
          Padding(
            padding: const EdgeInsets.only(bottom: SNSpace.x3),
            child: Text(
              entry.key,
              style: SNText.sectionLabel.copyWith(
                color: c.mutedForeground,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...entry.value.asMap().entries.map((e) {
            final idx = e.key;
            final payment = e.value;
            final isLast = idx == entry.value.length - 1;
            return _TimelineItem(payment: payment, isLast: isLast);
          }),
          const SizedBox(height: SNSpace.x4),
        ]),
      ],
    );
  }

  Map<String, List<PaymentHistoryItem>> _groupByMonth(List<PaymentHistoryItem> items) {
    final map = <String, List<PaymentHistoryItem>>{};
    for (final item in items) {
      final key = DateFormat('MMMM yyyy').format(item.createdAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

// ── Dark Summary Card ──
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalPesewas});
  final int totalPesewas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SNSpace.x6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B41),
        borderRadius: BorderRadius.circular(SNRadius.xxl),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            right: -8,
            child: Icon(
              Icons.credit_score_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL PAID THIS YEAR',
                style: SNText.microAction.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: SNSpace.x2),
              Text(
                Money.format(totalPesewas),
                style: SNText.headingLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: SNSpace.x6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: SNText.microAction.copyWith(
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: SNSpace.x1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SNSpace.x3,
                          vertical: SNSpace.x1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(SNRadius.pill),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'ALL CLEAR',
                          style: SNText.microAction.copyWith(
                            color: const Color(0xFF4ADE80),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Timeline Item ──
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.payment, required this.isLast});
  final PaymentHistoryItem payment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final dateStr = DateFormat('MMM d, yyyy \u2022 hh:mm a').format(payment.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.background, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: c.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: SNSpace.x3),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: SNSpace.x4),
              child: SNCard(
                onTap: () => context.push('/booking/${payment.bookingId}'),
                padding: const EdgeInsets.all(SNSpace.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _paymentTitle(payment),
                                style: SNText.sectionLabel.copyWith(
                                  color: c.foreground,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: SNSpace.x1),
                              Text(
                                dateStr,
                                style: SNText.caption.copyWith(
                                  color: c.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+ ${Money.format(payment.amountPesewas)}',
                          style: SNText.bodyBold.copyWith(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SNSpace.x3),
                    Container(
                      height: 1,
                      color: c.border.withOpacity(0.5),
                    ),
                    const SizedBox(height: SNSpace.x3),
                    Row(
                      children: [
                        _ChannelIcon(channel: payment.channel, cardBrand: payment.cardBrand),
                        const SizedBox(width: SNSpace.x2),
                        Text(
                          _channelLabel(payment),
                          style: SNText.caption.copyWith(
                            color: c.mutedForeground,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showReceipt(context, payment),
                          child: Text(
                            'RECEIPT',
                            style: SNText.caption.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.underline,
                              decorationColor: c.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, PaymentHistoryItem p) {
    Printing.layoutPdf(onLayout: (_) => ReceiptGenerator.generateFromHistory(p));
  }

  String _paymentTitle(PaymentHistoryItem p) {
    if (p.paymentType == 'INSTALLMENT') return '${p.hostelName} — Installment';
    return '${p.hostelName} — Booking';
  }

  String _channelLabel(PaymentHistoryItem p) {
    if (p.channel == 'CARD' && p.cardBrand != null) {
      final brand = p.cardBrand!.toUpperCase().trim();
      final last4 = p.cardLast4 ?? '';
      if (brand.contains('VISA')) return 'VISA ****$last4';
      if (brand.contains('MASTER')) return 'MASTERCARD ****$last4';
      return '$brand ****$last4';
    }
    switch (p.channel) {
      case 'MOBILE_MONEY':
        return 'MOBILE MONEY';
      case 'CARD':
        return 'CARD PAYMENT';
      case 'BANK':
        return 'BANK TRANSFER';
      case 'USSD':
        return 'USSD';
      default:
        return 'PAYMENT';
    }
  }
}

class _ChannelIcon extends StatelessWidget {
  const _ChannelIcon({required this.channel, this.cardBrand});
  final String? channel;
  final String? cardBrand;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    final brand = (cardBrand ?? '').toUpperCase().trim();

    if (channel == 'CARD') {
      if (brand.contains('VISA')) {
        icon = Icons.credit_card;
        color = const Color(0xFF1A1F71);
      } else if (brand.contains('MASTER')) {
        icon = Icons.credit_card;
        color = const Color(0xFFEB001B);
      } else {
        icon = Icons.credit_card;
        color = const Color(0xFF6366F1);
      }
    } else if (channel == 'MOBILE_MONEY') {
      icon = Icons.phone_android;
      color = const Color(0xFFFBBF24);
    } else if (channel == 'BANK') {
      icon = Icons.account_balance;
      color = const Color(0xFF0EA5E9);
    } else {
      icon = Icons.payment;
      color = const Color(0xFF9CA3AF);
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
