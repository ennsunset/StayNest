// features/payment/presentation/payment_pending_screen.dart
//
// Screen 27 — Payment Pending [NEW].
// THE most important new screen in the product.
// Calm. Slow. No blocking spinner. No progress bar.
// User MUST be able to leave.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/app/router.dart';

class PaymentPendingScreen extends StatelessWidget {
  const PaymentPendingScreen({
    super.key,
    this.reference = 'STN-PAY-2026-A1B2',
    this.isMoMo = true,
  });

  final String reference;
  final bool isMoMo;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: SNMoment(
            icon: Icons.send_rounded,
            headline: "We're confirming your payment",
            body: 'This can take up to 5 minutes with Mobile Money. '
                'You can close the app — we\'ll notify you the moment it\'s done.',
            tone: SNStatusTone.warning,
            pulse: true,
            primaryAction: isMoMo
                ? SNCard(
                    tinted: true,
                    padding: const EdgeInsets.all(SNSpace.x4),
                    child: Row(
                      children: [
                        Icon(Icons.phone_android_rounded,
                            size: 18, color: c.primary),
                        const SizedBox(width: SNSpace.x3),
                        Expanded(
                          child: Text(
                            'Check your phone for the approval prompt and enter your PIN.',
                            style: SNText.caption.copyWith(color: c.primary),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            secondaryAction: SNButton(
              label: 'Back to My Stays',
              variant: SNButtonVariant.ghost,
              onPressed: () => context.go(Routes.myStays),
            ),
            footer: Column(
              children: [
                const SizedBox(height: SNSpace.x5),
                // Reference card — tap to copy
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: reference));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reference copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: SNCard(
                    padding: const EdgeInsets.all(SNSpace.x4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REFERENCE',
                              style: SNText.sectionLabel
                                  .copyWith(color: c.mutedForeground),
                            ),
                            const SizedBox(height: SNSpace.x1),
                            Text(
                              reference,
                              style: SNText.mono.copyWith(color: c.foreground),
                            ),
                          ],
                        ),
                        Icon(Icons.copy_rounded,
                            size: 18, color: c.mutedForeground),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
