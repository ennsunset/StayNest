import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  static const _mockStaff = [
    {'name': 'Sampson Mensah', 'role': 'Head Caretaker', 'status': 'Active'},
    {'name': 'Grace Osei', 'role': 'Housekeeping', 'status': 'On Break'},
    {'name': 'Kofi Annan', 'role': 'Security', 'status': 'Active'},
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Staff Directory', onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SNCard(
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle), child: Icon(Icons.person_add_outlined, color: c.primaryForeground, size: 22)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Onboard New Staff', style: SNText.bodyBold.copyWith(color: c.primary)),
                Text('ADD CARETAKERS, CLEANERS, OR SECURITY', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1)),
              ])),
            ]),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff onboarding coming soon'))),
          ),
          const SizedBox(height: 16),
          ..._mockStaff.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SNCard(
              child: Row(children: [
                CircleAvatar(radius: 24, backgroundColor: c.muted, child: Text(s['name']![0], style: SNText.bodyBold.copyWith(color: c.foreground))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['name']!, style: SNText.bodyBold.copyWith(color: c.foreground)),
                  const SizedBox(height: 2),
                  Text(
                    '${s['role']!.toUpperCase()} \u2022 ${s['status']!.toUpperCase()}',
                    style: SNText.microAction.copyWith(color: s['status'] == 'Active' ? const Color(0xFF16A34A) : c.mutedForeground, letterSpacing: 1),
                  ),
                ])),
                IconButton(icon: Icon(Icons.chat_bubble_outline, size: 20, color: c.mutedForeground), onPressed: () {}),
                IconButton(icon: Icon(Icons.settings_outlined, size: 20, color: c.mutedForeground), onPressed: () {}),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}
