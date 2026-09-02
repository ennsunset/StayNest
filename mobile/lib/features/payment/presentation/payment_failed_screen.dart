// features/payment/presentation/payment_failed_screen.dart
//
// Screen 28 — Payment Failed [NEW].
// Plain-language reason. Never surface raw gateway codes.
// Trap: retry reuses the same reference and hold.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/features/payment/data/payments_repository.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';

class PaymentFailedScreen extends ConsumerWidget {
  const PaymentFailedScreen({
    super.key,
    this.reason = 'Your Mobile Money balance was insufficient.',
    this.holdMinutesLeft,
    required this.bookingId,
    this.hostelName = '',
    this.roomLabel = '',
    this.bedLabel = '',
  });

  /// Plain-language reason mapped from provider codes.
  final String reason;

  /// If the hold still survives, show remaining time.
  final int? holdMinutesLeft;
  final String bookingId;
  final String hostelName;
  final String roomLabel;
  final String bedLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: SNMoment(
            icon: Icons.close_rounded,
            headline: "Payment didn't go through",
            body: reason,
            tone: SNStatusTone.danger,
            primaryAction: SNButton(
              label: 'Try again',
              onPressed: () async {
                try {
                  final repo = ref.read(paymentsRepositoryProvider);
                  final result = await repo.initialize(bookingId: bookingId);
                  if (context.mounted) {
                    context.pushReplacement('/payment/webview', extra: {
                      'authorizationUrl': result.authorizationUrl,
                      'reference': result.reference,
                      'bookingId': bookingId,
                      'hostelName': hostelName,
                      'roomLabel': roomLabel,
                      'bedLabel': bedLabel,
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Retry failed: \$e')),
                    );
                  }
                }
              },
            ),
            secondaryAction: SNButton(
              label: 'Choose another method',
              variant: SNButtonVariant.secondary,
              onPressed: () {
                
                context.pop();
              },
            ),
            footer: holdMinutesLeft != null
                ? Padding(
                    padding: const EdgeInsets.only(top: SNSpace.x5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 16, color: c.warning),
                        const SizedBox(width: SNSpace.x2),
                        Text(
                          'Your bed is still held for $holdMinutesLeft min',
                          style:
                              SNText.bodyBold.copyWith(color: c.warning),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
