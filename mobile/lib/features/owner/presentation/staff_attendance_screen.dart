import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';

class StaffAttendanceScreen extends StatelessWidget {
  const StaffAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Attendance Log', onBack: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            _StatBox(c: c, value: '12', label: 'PRESENT', color: c.foreground),
            const SizedBox(width: 12),
            _StatBox(c: c, value: '02', label: 'ABSENT', color: c.destructive),
            const SizedBox(width: 12),
            _StatBox(c: c, value: '00', label: 'LATE', color: c.warning),
          ]),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1C2B41), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('LIVE CHECK-INS', style: SNText.bodyBold.copyWith(color: Colors.white, fontSize: 13, letterSpacing: 1)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)), child: Text('LIVE', style: SNText.microAction.copyWith(color: Colors.white, letterSpacing: 1, fontWeight: FontWeight.w800))),
                ]),
              ),
              Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
                child: Column(children: [
                  _CheckInRow(c: c, name: 'Kofi Annan', role: 'Caretaker \u2022 Block A', time: '07:55 AM', status: 'ON TIME', statusColor: const Color(0xFF16A34A)),
                  Divider(height: 1, color: c.border.withValues(alpha: 0.3), indent: 72),
                  _CheckInRow(c: c, name: 'Efua Mansa', role: 'Security \u2022 Main Gate', time: '08:02 AM', status: 'GRACE PERIOD', statusColor: c.warning),
                  Divider(height: 1, color: c.border.withValues(alpha: 0.3), indent: 72),
                  _CheckInRow(c: c, name: 'Yaw Boakye', role: 'Cleaning \u2022 Block B', time: '---', status: 'EXPECTED 08:00', statusColor: c.mutedForeground),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export coming soon'))),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFF1C2B41), borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.download_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('EXPORT ATTENDANCE (WEEKLY)', style: SNText.bodyBold.copyWith(color: Colors.white, fontSize: 12, letterSpacing: 1.5)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.c, required this.value, required this.label, required this.color});
  final SNColorTokens c; final String value; final String label; final Color color;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: SNCard(child: Column(children: [
      Text(value, style: SNText.headingLg.copyWith(color: color)),
      const SizedBox(height: 2),
      Text(label, style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1)),
    ])));
  }
}

class _CheckInRow extends StatelessWidget {
  const _CheckInRow({required this.c, required this.name, required this.role, required this.time, required this.status, required this.statusColor});
  final SNColorTokens c; final String name; final String role; final String time; final String status; final Color statusColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: c.muted, child: Text(name[0], style: SNText.bodyBold.copyWith(color: c.foreground))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.toUpperCase(), style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13, letterSpacing: 0.5)),
          Text(role.toUpperCase(), style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 0.8)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(time, style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13)),
          Text(status, style: SNText.microAction.copyWith(color: statusColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ]),
      ]),
    );
  }
}
