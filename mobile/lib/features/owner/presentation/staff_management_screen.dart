import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

part 'staff_management_screen.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> ownerStaff(Ref ref) {
  return ref.read(ownerRepositoryProvider).fetchStaff();
}

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final asyncStaff = ref.watch(ownerStaffProvider);
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Staff Directory', onBack: () => context.pop()),
      body: asyncStaff.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: SNEmptyState(icon: Icons.error_outline, headline: 'Failed to load staff', actionLabel: 'Retry', onAction: () => ref.invalidate(ownerStaffProvider))),
        data: (staff) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(ownerStaffProvider),
          child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: [
            SNCard(
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle), child: Icon(Icons.person_add_outlined, color: c.primaryForeground, size: 22)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Onboard New Staff', style: SNText.bodyBold.copyWith(color: c.primary)),
                  Text('ADD CARETAKERS, CLEANERS, OR SECURITY', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1)),
                ])),
              ]),
              onTap: () => _showAddSheet(context, ref, c),
            ),
            const SizedBox(height: 16),
            if (staff.isEmpty) Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text('No staff added yet', style: SNText.body.copyWith(color: c.mutedForeground))))
            else ...staff.map((s) {
              final name = s['name'] as String? ?? '';
              final role = (s['role'] as String? ?? '').toUpperCase();
              final status = (s['status'] as String? ?? 'ACTIVE').toUpperCase();
              final hostel = s['hostel_name'] as String? ?? '';
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: SNCard(child: Row(children: [
                CircleAvatar(radius: 24, backgroundColor: c.muted, child: Text(name.isNotEmpty ? name[0] : '?', style: SNText.bodyBold.copyWith(color: c.foreground))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: SNText.bodyBold.copyWith(color: c.foreground)),
                  const SizedBox(height: 2),
                  Text('\$role \u2022 \$status', style: SNText.microAction.copyWith(color: status == 'ACTIVE' ? const Color(0xFF16A34A) : c.mutedForeground, letterSpacing: 1)),
                  if (hostel.isNotEmpty) Text(hostel, style: SNText.caption.copyWith(color: c.mutedForeground)),
                ])),
                IconButton(icon: Icon(Icons.delete_outline, size: 20, color: c.destructive), onPressed: () async {
                  final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
                    title: const Text('Remove Staff?'), content: Text('Remove \$name?'),
                    actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(d, true), child: Text('Remove', style: TextStyle(color: c.destructive)))],
                  ));
                  if (ok == true) { try { await ref.read(ownerRepositoryProvider).removeStaff(s['id'] as String); ref.invalidate(ownerStaffProvider); } catch (_) {} }
                }),
              ])));
            }),
          ]),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, SNColorTokens c) {
    String name = '', phone = '', role = 'CARETAKER';
    final roles = ['CARETAKER', 'SECURITY', 'HOUSEKEEPING', 'MAINTENANCE', 'ADMIN'];
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Add Staff Member', style: SNText.headingMd.copyWith(color: c.foreground)),
          const SizedBox(height: 20),
          TextField(decoration: InputDecoration(hintText: 'Full Name', filled: true, fillColor: c.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (v) => name = v),
          const SizedBox(height: 12),
          TextField(decoration: InputDecoration(hintText: 'Phone (optional)', filled: true, fillColor: c.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
          const SizedBox(height: 12),
          Text('Role', style: SNText.caption.copyWith(color: c.mutedForeground)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: roles.map((r) {
            final sel = role == r;
            return GestureDetector(onTap: () => ss(() => role = r), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: sel ? c.primary : c.muted, borderRadius: BorderRadius.circular(10)),
              child: Text(r, style: SNText.caption.copyWith(color: sel ? c.primaryForeground : c.foreground, fontWeight: FontWeight.w700))));
          }).toList()),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () async {
              if (name.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final hostels = await ref.read(ownerRepositoryProvider).fetchMyHostels();
                if (hostels.isEmpty) return;
                await ref.read(ownerRepositoryProvider).addStaff(name: name.trim(), role: role, phone: phone.trim().isNotEmpty ? phone.trim() : null, hostelId: hostels.first['id'] as String);
                ref.invalidate(ownerStaffProvider);
              } catch (_) {}
            },
            child: Text('Add Staff', style: SNText.bodyBold.copyWith(color: c.primaryForeground)),
          )),
        ]),
      )),
    );
  }
}
