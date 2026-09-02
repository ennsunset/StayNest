// features/booking/presentation/bed_taken_screen.dart
//
// Screen 22 — Bed Just Taken [NEW].
// Calm moment screen. No red. No error iconography. No blame.
// The user did nothing wrong.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/features/discovery/presentation/hostel_details_screen.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';

class BedTakenScreen extends ConsumerWidget {
  const BedTakenScreen({super.key, this.roomId, this.hostelId});

  final String? roomId;
  final String? hostelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SNSpace.screenX),
          child: SNMoment(
            icon: Icons.people_outline_rounded,
            headline: 'This bed was just booked',
            body: 'Someone completed their booking a moment before you. '
                'Nothing was charged.',
            tone: SNStatusTone.neutral,
            primaryAction: SNButton(
              label: 'Browse available rooms',
              onPressed: () {
                if (hostelId != null) {
                  ref.invalidate(hostelDetailProvider(hostelId!));
                  context.go('/home/hostel/$hostelId');
                } else {
                  context.go('/home');
                }
              },
            ),
            secondaryAction: SNButton(
              label: 'Back to search',
              variant: SNButtonVariant.secondary,
              onPressed: () => context.go("/home"),
            ),
          ),
        ),
      ),
    );
  }
}
