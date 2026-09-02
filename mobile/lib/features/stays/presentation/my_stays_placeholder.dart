import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';

class MyStaysPlaceholder extends StatelessWidget {
  const MyStaysPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: SNEmptyState(
          icon: Icons.luggage_outlined,
          headline: 'My Stays',
          actionLabel: 'Find a hostel',
          onAction: () {},
        ),
      ),
    );
  }
}
