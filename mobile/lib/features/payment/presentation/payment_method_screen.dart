// features/payment/presentation/payment_method_screen.dart
//
// Screen 26 — Payment Method [NEW].
// MoMo first and pre-selected. Card second. Bank third.
// Trap: launch Paystack hosted checkout. App never sees card data.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key, this.amountPesewas = 386000});

  final int amountPesewas;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedMethod = 0; // 0 = MoMo, 1 = Card, 2 = Bank
  int _selectedNetwork = 0; // 0 = MTN, 1 = Telecel, 2 = AT
  final _phoneController = TextEditingController();
  bool _submitting = false;

  static const _networks = ['MTN', 'Telecel', 'AT'];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Payment',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          // Countdown pill
          CountdownPill(
            heldUntil: DateTime.now().add(const Duration(minutes: 15)),
            onExpired: () {
              // PHASE2: navigate to bed taken screen
            },
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SNSpace.screenX),
              child: Column(
                children: [
                  // Amount hero
                  const SizedBox(height: SNSpace.x4),
                  SNSectionLabel('Amount Due'),
                  const SizedBox(height: SNSpace.x2),
                  Text(
                    Money.format(widget.amountPesewas),
                    style: SNText.displayLg.copyWith(color: c.foreground),
                  ),
                  const SizedBox(height: SNSpace.section),

                  // Method cards
                  _buildMethodCard(c, 0, Icons.phone_android_rounded,
                      'Mobile Money', 'MTN, Telecel, AT'),
                  const SizedBox(height: SNSpace.x3),
                  _buildMethodCard(c, 1, Icons.credit_card_rounded, 'Card',
                      'Visa, Mastercard'),
                  const SizedBox(height: SNSpace.x3),
                  _buildMethodCard(c, 2, Icons.account_balance_rounded,
                      'Bank Transfer', 'Pay from your bank app'),

                  // MoMo sub-selector
                  if (_selectedMethod == 0) ...[
                    const SizedBox(height: SNSpace.x5),
                    _buildMoMoDetails(c),
                  ],

                  const SizedBox(height: SNSpace.section),

                  // Trust line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: c.mutedForeground),
                      const SizedBox(width: SNSpace.x2),
                      Flexible(
                        child: Text(
                          'Payments are secured by Paystack. StayNest never sees your card details.',
                          style: SNText.caption.copyWith(color: c.mutedForeground),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sticky pay button
          Container(
            padding: const EdgeInsets.all(SNSpace.screenX),
            decoration: BoxDecoration(
              color: c.card,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SafeArea(
              top: false,
              child: SNButton(
                label: 'Pay ${Money.format(widget.amountPesewas)}',
                isLoading: _submitting,
                onPressed: () async {
                  setState(() => _submitting = true);
                  // PHASE2: initialise Paystack checkout
                  await Future.delayed(const Duration(milliseconds: 800));
                  if (!mounted) return;
                  setState(() => _submitting = false);
                  // PHASE2: navigate to payment pending
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(
    SNColorTokens c,
    int index,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _selectedMethod == index;

    return SNCard(
      selected: selected,
      onTap: () => setState(() => _selectedMethod = index),
      padding: const EdgeInsets.all(SNSpace.x4),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: selected ? c.primary.withValues(alpha: 0.1) : c.muted,
              borderRadius: BorderRadius.circular(SNRadius.sm),
            ),
            child: Icon(icon, size: 22, color: selected ? c.primary : c.foreground),
          ),
          const SizedBox(width: SNSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SNText.bodyBold.copyWith(color: c.foreground)),
                Text(subtitle, style: SNText.caption.copyWith(color: c.mutedForeground)),
              ],
            ),
          ),
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? c.primary : c.border,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.primary,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMoMoDetails(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Network chips
        Row(
          children: List.generate(_networks.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: SNSpace.x3),
              child: SNChip(
                label: _networks[i],
                selected: _selectedNetwork == i,
                onTap: () => setState(() => _selectedNetwork = i),
              ),
            );
          }),
        ),
        const SizedBox(height: SNSpace.x4),
        // Phone number input
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: SNText.body.copyWith(color: c.foreground),
          decoration: InputDecoration(
            hintText: '024 XXX XXXX',
            hintStyle: SNText.body.copyWith(color: c.mutedForeground),
            prefixText: '+233 ',
            prefixStyle: SNText.body.copyWith(color: c.mutedForeground),
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SNRadius.sm),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SNRadius.sm),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SNRadius.sm),
              borderSide: BorderSide(color: c.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SNSpace.x5,
              vertical: SNSpace.x4,
            ),
          ),
        ),
      ],
    );
  }
}
