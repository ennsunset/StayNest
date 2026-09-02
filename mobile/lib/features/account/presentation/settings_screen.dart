// features/account/presentation/settings_screen.dart
//
// Screen 32 — Settings.
// Dark mode toggle removed (D3). No dead toggles.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _locationEnabled = true;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Settings',
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toggle(c, 'Push Notifications', 'Booking updates and alerts',
                Icons.notifications_outlined, _pushEnabled, (v) {
              setState(() => _pushEnabled = v);
            }),
            const SizedBox(height: SNSpace.x3),
            _toggle(c, 'Location Services', 'For nearby hostel search',
                Icons.location_on_outlined, _locationEnabled, (v) {
              setState(() => _locationEnabled = v);
            }),
            const SizedBox(height: SNSpace.x3),
            _toggle(c, 'Biometric Login', 'Use fingerprint or face',
                Icons.fingerprint_rounded, _biometricEnabled, (v) {
              setState(() => _biometricEnabled = v);
            }),
            const SizedBox(height: SNSpace.section),
            _navRow(c, 'Change Password', Icons.lock_outline_rounded, () {
              context.push('/forgot-password');
            }),
            const SizedBox(height: SNSpace.x3),
            _navRow(c, 'Security', Icons.shield_outlined, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
            }),
          ],
        ),
      ),
    );
  }

  Widget _toggle(SNColorTokens c, String title, String subtitle,
      IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(SNSpace.x4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(SNRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: c.foreground),
          const SizedBox(width: SNSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SNText.bodyBold.copyWith(color: c.foreground)),
                Text(subtitle, style: SNText.caption.copyWith(color: c.mutedForeground)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: c.primary,
          ),
        ],
      ),
    );
  }

  Widget _navRow(SNColorTokens c, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SNSpace.x4),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(SNRadius.lg),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c.foreground),
            const SizedBox(width: SNSpace.x4),
            Expanded(
              child: Text(title, style: SNText.bodyBold.copyWith(color: c.foreground)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.mutedForeground),
          ],
        ),
      ),
    );
  }
}
