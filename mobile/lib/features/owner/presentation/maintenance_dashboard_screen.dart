import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  const MaintenanceDashboardScreen({super.key});
  @override
  State<MaintenanceDashboardScreen> createState() => _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState extends State<MaintenanceDashboardScreen> {
  int _tab = 0;
  static const _tabs = ['Pending', 'In Progress', 'Resolved'];
  static const _mockIssues = [
    {'title': 'Power Outage', 'room': 'Room 104', 'hostel': 'Anglican Hostel', 'severity': 'URGENT', 'desc': 'AC unit is not turning on and there is a smell of smoke from the socket.'},
    {'title': 'Leaking Tap', 'room': 'Room 205', 'hostel': 'Anglican Hostel', 'severity': 'MEDIUM', 'desc': ''},
    {'title': 'Broken Lock', 'room': 'Room 301', 'hostel': 'Prestige Hall', 'severity': 'HIGH', 'desc': 'Door lock mechanism jammed, tenant locked out.'},
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Maintenance',
        onBack: () => context.pop(),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.destructive.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Text('${_mockIssues.length}', style: SNText.caption.copyWith(color: c.destructive, fontWeight: FontWeight.w800)),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(children: List.generate(_tabs.length, (i) {
            final active = i == _tab;
            final label = i == 0 ? '${_tabs[i]} (${_mockIssues.length})' : _tabs[i];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: active ? c.primary : c.muted, borderRadius: BorderRadius.circular(20)),
                  child: Text(label, style: SNText.caption.copyWith(color: active ? c.primaryForeground : c.mutedForeground, fontWeight: FontWeight.w700)),
                ),
              ),
            );
          })),
        ),
        Expanded(
          child: _tab == 0
              ? ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _mockIssues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final issue = _mockIssues[i];
                    final sevColor = issue['severity'] == 'URGENT' ? c.destructive : c.warning;
                    return SNCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.build_outlined, color: c.primary, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text((issue['title'] as String).toUpperCase(), style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13, letterSpacing: 0.5)),
                          Text('${issue['room']} \u2022 ${issue['hostel']}', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 0.5)),
                        ])),
                        Text(issue['severity'] as String, style: SNText.microAction.copyWith(color: sevColor, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ]),
                      if ((issue['desc'] as String).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('"${issue['desc']}"', style: SNText.body.copyWith(color: c.mutedForeground, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff assignment coming soon'))),
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(12)), child: Center(child: Text('ASSIGN STAFF', style: SNText.bodyBold.copyWith(color: c.primaryForeground, fontSize: 12, letterSpacing: 1)))),
                        )),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {},
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(12)), child: Text('IGNORE', style: SNText.bodyBold.copyWith(color: c.mutedForeground, fontSize: 12, letterSpacing: 1))),
                        ),
                      ]),
                    ]));
                  },
                )
              : Center(child: Text('No ${_tabs[_tab].toLowerCase()} issues', style: SNText.body.copyWith(color: c.mutedForeground))),
        ),
      ]),
    );
  }
}
