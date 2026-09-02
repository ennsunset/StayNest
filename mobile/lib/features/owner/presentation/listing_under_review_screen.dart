// features/owner/presentation/listing_under_review_screen.dart
// Screen 47 — Listing Under Review [NEW].

import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';

class ListingUnderReviewScreen extends StatelessWidget {
  const ListingUnderReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sn.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: SNMoment(
            icon: Icons.schedule_rounded,
            headline: "We're reviewing your listing",
            body: 'Usually within 24 hours. We\'ll notify you as soon as it\'s live.',
            tone: SNStatusTone.warning,
            primaryAction: SNButton(
              label: 'Back to My Properties',
              onPressed: () => context.pop(),
            ),
            secondaryAction: SNButton(
              label: 'Edit Listing',
              variant: SNButtonVariant.secondary,
              onPressed: () {
                // PHASE2: navigate to edit
              },
            ),
          ),
        ),
      ),
    );
  }
}
