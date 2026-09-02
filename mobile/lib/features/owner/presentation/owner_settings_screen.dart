// features/owner/presentation/owner_settings_screen.dart
// Screen 50 — Owner Settings [NEW].
// Trap: changing bank details triggers cool-down + admin verification.

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class OwnerSettingsScreen extends StatelessWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: SNSpace.navClear),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x5,
                ),
                child: Text('Settings', style: SNText.headingLg.copyWith(color: c.foreground)),
              ),

              // Payout
              _sectionHeader(c, 'Payout'),
              _settingsRow(c, 'Bank Account', 'GCB Bank ••• 4567', Icons.account_balance_outlined, () {
                // PHASE2: re-authenticate before opening form
                // Show cool-down warning
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                child: SNCard(
                  tinted: true,
                  tint: c.warning,
                  padding: const EdgeInsets.all(SNSpace.x4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: c.warning),
                      const SizedBox(width: SNSpace.x3),
                      Expanded(
                        child: Text(
                          'Changing bank details pauses settlements until verified by our team.',
                          style: SNText.caption.copyWith(color: c.mutedForeground),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SNSpace.x5),

              // Notifications
              _sectionHeader(c, 'Notifications'),
              _settingsRow(c, 'Push Notifications', 'Enabled', Icons.notifications_outlined, () {}),
              _settingsRow(c, 'Email Alerts', 'Enabled', Icons.email_outlined, () {}),
              const SizedBox(height: SNSpace.x5),

              // Security
              _sectionHeader(c, 'Security'),
              _settingsRow(c, 'Change Password', '', Icons.lock_outline_rounded, () {}),
              _settingsRow(c, 'Two-Factor Auth', 'Enabled', Icons.security_rounded, () {}),
              const SizedBox(height: SNSpace.x5),

              // Staff access (Phase 2)
              _sectionHeader(c, 'Staff Access'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                child: Opacity(
                  opacity: 0.5,
                  child: _settingsRow(c, 'Manage Staff', 'Phase 2', Icons.people_outline_rounded, null),
                ),
              ),
              const SizedBox(height: SNSpace.section),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                child: SNCard(
                  onTap: () async {
                    const storage = FlutterSecureStorage();
                    await storage.deleteAll();
                    if (context.mounted) context.go('/');
                  },
                  padding: const EdgeInsets.all(SNSpace.x4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: c.destructive),
                      const SizedBox(width: SNSpace.x3),
                      Text('Log Out', style: SNText.bodyBold.copyWith(color: c.destructive)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(SNColorTokens c, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x3,
      ),
      child: SNSectionLabel(label),
    );
  }

  Widget _settingsRow(SNColorTokens c, String title, String value, IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: SNCard(
        onTap: onTap,
        padding: const EdgeInsets.all(SNSpace.x4),
        child: Row(
          children: [
            Container(
              height: 36, width: 36,
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: BorderRadius.circular(SNRadius.xs),
              ),
              child: Icon(icon, size: 18, color: c.foreground),
            ),
            const SizedBox(width: SNSpace.x4),
            Expanded(
              child: Text(title, style: SNText.bodyBold.copyWith(color: c.foreground)),
            ),
            if (value.isNotEmpty)
              Text(value, style: SNText.caption.copyWith(color: c.mutedForeground)),
            const SizedBox(width: SNSpace.x2),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 18, color: c.mutedForeground),
          ],
        ),
      ),
    );
  }
}
