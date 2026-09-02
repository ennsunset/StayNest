// features/payment/presentation/payment_success_screen.dart
//
// Screen 29 — Payment Success / Receipt [NEW].
// Success moment with receipt breakdown.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/app/router.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, this.amountPesewas = 386000});

  final int amountPesewas;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: SNMoment(
            icon: Icons.check_rounded,
            headline: 'Payment successful',
            tone: SNStatusTone.success,
            primaryAction: SNButton(
              label: 'View booking',
              onPressed: () => context.go(Routes.myStays),
            ),
            secondaryAction: Row(
              children: [
                Expanded(
                  child: SNButton(
                    label: 'Download PDF',
                    variant: SNButtonVariant.secondary,
                    onPressed: () {
                      // PHASE2: download receipt PDF
                    },
                  ),
                ),
                const SizedBox(width: SNSpace.x3),
                Expanded(
                  child: SNButton(
                    label: 'Email receipt',
                    variant: SNButtonVariant.secondary,
                    onPressed: () {
                      // PHASE2: email receipt
                    },
                  ),
                ),
              ],
            ),
            footer: Column(
              children: [
                const SizedBox(height: SNSpace.x5),
                // Amount
                Text(
                  Money.format(amountPesewas),
                  style: SNText.displayLg.copyWith(color: c.foreground),
                ),
                const SizedBox(height: SNSpace.section),
                // Receipt card
                SNCard(
                  padding: const EdgeInsets.all(SNSpace.x5),
                  child: Column(
                    children: [
                      const TransactionRow(
                          label: 'Room fee', amountPesewas: 320000),
                      const SizedBox(height: SNSpace.x3),
                      const TransactionRow(
                          label: 'Caution deposit', amountPesewas: 50000),
                      const SizedBox(height: SNSpace.x3),
                      const TransactionRow(
                          label: 'Platform fee', amountPesewas: 16000),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: SNSpace.x4),
                        child: Divider(height: 1, color: c.border),
                      ),
                      const TransactionRow(
                        label: 'Total',
                        amountPesewas: 386000,
                        emphasised: true,
                      ),
                      const SizedBox(height: SNSpace.x5),
                      _receiptLine(c, 'Method', 'Mobile Money (MTN)'),
                      const SizedBox(height: SNSpace.x3),
                      _receiptLine(c, 'Reference', 'STN-PAY-2026-A1B2'),
                      const SizedBox(height: SNSpace.x3),
                      _receiptLine(c, 'Date', 'Aug 14, 2026 · 10:34 AM'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptLine(SNColorTokens c, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SNText.caption.copyWith(color: c.mutedForeground)),
        Text(value, style: SNText.caption.copyWith(color: c.foreground)),
      ],
    );
  }
}
