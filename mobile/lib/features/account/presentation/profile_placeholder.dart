import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: SNEmptyState(
          icon: Icons.person_outline_rounded,
          headline: 'Profile',
          actionLabel: 'Back',
          onAction: () {},
        ),
      ),
    );
  }
}
