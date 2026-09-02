// features/owner/presentation/tenant_detail_screen.dart
//
// Screen 45 — Tenant Detail [NEW].

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class TenantDetailScreen extends StatelessWidget {
  const TenantDetailScreen({super.key, required this.tenantId});
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Tenant', onBack: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            SNCard(
              padding: const EdgeInsets.all(SNSpace.x5),
              child: Row(
                children: [
                  const SNAvatar(size: SNSize.avatarMd, initials: 'KA'),
                  const SizedBox(width: SNSpace.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kofi Asante', style: SNText.headingMd.copyWith(color: c.foreground)),
                        const SizedBox(height: SNSpace.x1),
                        Text('Room 104B · Bed A', style: SNText.caption.copyWith(color: c.mutedForeground)),
                      ],
                    ),
                  ),
                  SNBadge(label: 'Paid', tone: SNStatusTone.success),
                ],
              ),
            ),
            const SizedBox(height: SNSpace.section),
            SNSectionLabel('Contract'),
            const SizedBox(height: SNSpace.x4),
            _row(c, 'Check-in', 'Sept 1, 2026'),
            const SizedBox(height: SNSpace.x3),
            _row(c, 'Contract ends', 'May 31, 2027'),
            const SizedBox(height: SNSpace.section),
            SNSectionLabel('Payment History'),
            const SizedBox(height: SNSpace.x4),
            const TransactionRow(label: 'Booking payment', sublabel: 'Aug 14, 2026', amountPesewas: 320000),
            const SizedBox(height: SNSpace.section),
            SNButton(label: 'Message Tenant', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _row(SNColorTokens c, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SNText.body.copyWith(color: c.mutedForeground)),
        Text(value, style: SNText.bodyBold.copyWith(color: c.foreground)),
      ],
    );
  }
}
