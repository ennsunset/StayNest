// features/owner/presentation/listing_rejected_screen.dart
// Screen 48 — Listing Rejected [NEW].
// Tone: corrective, not punitive. Headline: "A few things to fix" — NOT "Rejected".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';

class ListingRejectedScreen extends StatelessWidget {
  const ListingRejectedScreen({
    super.key,
    this.reason = 'Photos are too dark to verify the room condition. '
        'Please retake photos in daylight showing the full room.',
  });

  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: SNMoment(
            icon: Icons.edit_outlined,
            headline: 'A few things to fix',
            tone: SNStatusTone.danger,
            primaryAction: SNButton(
              label: 'Edit and resubmit',
              onPressed: () {
                // PHASE2: navigate to edit hostel
                context.pop();
              },
            ),
            footer: Padding(
              padding: const EdgeInsets.only(top: SNSpace.x5),
              child: SNCard(
                padding: const EdgeInsets.all(SNSpace.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REVIEW FEEDBACK',
                      style: SNText.sectionLabel.copyWith(color: c.mutedForeground),
                    ),
                    const SizedBox(height: SNSpace.x3),
                    Text(
                      reason,
                      style: SNText.body.copyWith(color: c.foreground, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
