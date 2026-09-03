import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';

class SecurityCenterScreen extends StatelessWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Security Center', onBack: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(color: c.destructive.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.destructive.withValues(alpha: 0.15))),
            child: Column(children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: c.destructive.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(Icons.shield_outlined, color: c.destructive, size: 28)),
              const SizedBox(height: 12),
              Text('0 Fraud Alerts', style: SNText.headingMd.copyWith(color: c.destructive)),
              const SizedBox(height: 4),
              Text('All clear. No suspicious activity detected.', style: SNText.caption.copyWith(color: c.mutedForeground)),
            ]),
          ),
          const SizedBox(height: 28),
          Text('RECENT INCIDENTS', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SNCard(child: Column(children: [
            Icon(Icons.check_circle_outline, color: const Color(0xFF16A34A), size: 40),
            const SizedBox(height: 12),
            Text('No incidents', style: SNText.bodyBold.copyWith(color: c.foreground)),
            const SizedBox(height: 4),
            Text('Your properties are secure', style: SNText.caption.copyWith(color: c.mutedForeground)),
          ])),
        ]),
      ),
    );
  }
}
