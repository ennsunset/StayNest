// features/owner/presentation/owner_profile_screen.dart
// Screen 49 — Owner Profile.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Profile', onBack: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: Column(
          children: [
            const SNAvatar(size: 80, initials: 'RP'),
            const SizedBox(height: SNSpace.x4),
            Text('Royal Palms Management', style: SNText.headingLg.copyWith(color: c.foreground)),
            const SizedBox(height: SNSpace.x2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const VerifiedBadge(label: 'Verified Partner'),
                const SizedBox(width: SNSpace.x2),
                Text('Since 2024', style: SNText.caption.copyWith(color: c.mutedForeground)),
              ],
            ),
            const SizedBox(height: SNSpace.x4),
            const RatingStars(rating: 4.8, reviewCount: 124, compact: false),
            const SizedBox(height: SNSpace.section),

            // Properties
            SNSectionLabel('Properties'),
            const SizedBox(height: SNSpace.x4),
            SNCard(
              padding: const EdgeInsets.all(SNSpace.x4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Royal Palms Hostel', style: SNText.bodyBold.copyWith(color: c.foreground)),
                      Text('24 rooms · 19 tenants', style: SNText.caption.copyWith(color: c.mutedForeground)),
                    ],
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.mutedForeground),
                ],
              ),
            ),
            const SizedBox(height: SNSpace.section),

            SNSectionLabel('About'),
            const SizedBox(height: SNSpace.x4),
            Text(
              'Professional hostel management company operating premium student '
              'accommodation near KNUST campus since 2024.',
              style: SNText.body.copyWith(color: c.mutedForeground, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
