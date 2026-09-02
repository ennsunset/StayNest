// features/booking/presentation/report_issue_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'GENERAL';
  String _priority = 'MEDIUM';
  bool _submitting = false;

  static const _categories = [
    ('PLUMBING', Icons.plumbing, 'Plumbing'),
    ('ELECTRICAL', Icons.electrical_services, 'Electrical'),
    ('FURNITURE', Icons.chair, 'Furniture'),
    ('PEST', Icons.bug_report, 'Pest Control'),
    ('CLEANING', Icons.cleaning_services, 'Cleaning'),
    ('GENERAL', Icons.build_outlined, 'Other'),
  ];

  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/bookings/${widget.bookingId}/maintenance', data: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'priority': _priority,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit report')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Report Issue', onBack: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What needs fixing?', style: SNText.headingMd.copyWith(color: c.foreground)),
            const SizedBox(height: SNSpace.x5),

            // Category grid
            Text('Category', style: SNText.bodyBold.copyWith(color: c.foreground)),
            const SizedBox(height: SNSpace.x3),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) {
                final selected = _category == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat.$1),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 2 * SNSpace.screenX - 20) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? c.primary.withValues(alpha: 0.1) : c.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? c.primary : c.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(cat.$2, size: 24, color: selected ? c.primary : c.mutedForeground),
                        const SizedBox(height: 6),
                        Text(
                          cat.$3,
                          style: SNText.caption.copyWith(
                            color: selected ? c.primary : c.foreground,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: SNSpace.section),

            // Title
            SNInput(
              label: 'Issue Title',
              hint: 'e.g. Leaking faucet in bathroom',
              controller: _titleCtrl,
            ),
            const SizedBox(height: SNSpace.x4),

            // Description
            SNInput(
              label: 'Description (optional)',
              hint: 'Describe the issue in detail...',
              controller: _descCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: SNSpace.section),

            // Priority
            Text('Priority', style: SNText.bodyBold.copyWith(color: c.foreground)),
            const SizedBox(height: SNSpace.x3),
            Row(
              children: _priorities.map((p) {
                final selected = _priority == p;
                final color = p == 'URGENT' ? c.destructive : p == 'HIGH' ? c.warning : p == 'MEDIUM' ? c.primary : c.mutedForeground;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      margin: EdgeInsets.only(right: p != 'URGENT' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.15) : c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? color : c.border),
                      ),
                      child: Center(
                        child: Text(
                          p[0] + p.substring(1).toLowerCase(),
                          style: SNText.caption.copyWith(
                            color: selected ? color : c.mutedForeground,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: SNSpace.section),

            // Submit
            SNButton(
              label: 'Submit Report',
              icon: Icons.send_rounded,
              isLoading: _submitting,
              onPressed: _titleCtrl.text.trim().isNotEmpty ? _submit : null,
            ),
            const SizedBox(height: SNSpace.section),
          ],
        ),
      ),
    );
  }
}
