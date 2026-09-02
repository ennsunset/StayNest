import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:staynest_mobile/core/utils/visitor_pass_generator.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/app/router.dart';

class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key, required this.bookingId, required this.hostelName});
  final String bookingId;
  final String hostelName;

  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen> {
  List<Map<String, dynamic>> _passes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  Future<void> _loadPasses() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final res = await repo.getVisitorPasses(widget.bookingId);
      if (mounted) setState(() { _passes = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final active = _passes.where((p) => p['status'] == 'ACTIVE').toList();
    final past = _passes.where((p) => p['status'] != 'ACTIVE').toList();

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Visitors', onBack: () => context.pop()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(c),
        backgroundColor: c.primary,
        foregroundColor: c.primaryForeground,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('New Pass'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _passes.isEmpty
              ? _emptyState(c)
              : RefreshIndicator(
                  onRefresh: _loadPasses,
                  child: ListView(
                    padding: const EdgeInsets.all(SNSpace.screenX),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(SNSpace.x4),
                        decoration: BoxDecoration(
                          color: c.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(SNRadius.md),
                          border: Border.all(color: c.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: c.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Passes are valid for 24 hours. Visitors must bring a valid ID.',
                                style: SNText.caption.copyWith(color: c.primary)),
                            ),
                          ],
                        ),
                      ),
                      if (active.isNotEmpty) ...[
                        const SizedBox(height: SNSpace.section),
                        SNSectionLabel('Active Passes'),
                        const SizedBox(height: SNSpace.x4),
                        ...active.map((p) => _passCard(c, p)),
                      ],
                      if (past.isNotEmpty) ...[
                        const SizedBox(height: SNSpace.section),
                        SNSectionLabel('Past Passes'),
                        const SizedBox(height: SNSpace.x4),
                        ...past.map((p) => _dismissiblePassCard(c, p)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _emptyState(SNColorTokens c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
              child: Icon(Icons.person_add_outlined, size: 36, color: c.mutedForeground),
            ),
            const SizedBox(height: 20),
            Text('No visitor passes yet', style: SNText.headingMd.copyWith(color: c.foreground)),
            const SizedBox(height: 8),
            Text('Generate a pass to let your visitor through the gate. They will need a valid ID.',
              style: SNText.body.copyWith(color: c.mutedForeground), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _dismissiblePassCard(SNColorTokens c, Map<String, dynamic> pass) {
    return Dismissible(
      key: Key(pass['id'] ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFDC3545),
          borderRadius: BorderRadius.circular(SNRadius.md),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Pass?'),
            content: const Text('This will permanently remove this pass from your history.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFDC3545)))),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final repo = ref.read(bookingsRepositoryProvider);
            await repo.deleteVisitorPass(pass['id']);
            _loadPasses();
          } catch (_) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete pass')));
          }
        }
        return false;
      },
      child: _passCard(c, pass),
    );
  }

  Widget _passCard(SNColorTokens c, Map<String, dynamic> pass) {
    final status = pass['status'] as String? ?? 'ACTIVE';
    final isActive = status == 'ACTIVE';
    final validUntil = DateTime.tryParse(pass['valid_until'] ?? '');
    final remaining = validUntil != null ? validUntil.difference(DateTime.now()) : Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SNCard(
        padding: const EdgeInsets.all(SNSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? c.primary.withOpacity(0.1) : c.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_outline, size: 20, color: isActive ? c.primary : c.mutedForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pass['visitor_name'] ?? '', style: SNText.bodyBold.copyWith(color: c.foreground)),
                      if (pass['purpose'] != null)
                        Text(pass['purpose'], style: SNText.caption.copyWith(color: c.mutedForeground)),
                    ],
                  ),
                ),
                _statusChip(c, status),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: c.mutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    remaining.inHours > 0
                        ? '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining'
                        : '${remaining.inMinutes}m remaining',
                    style: SNText.caption.copyWith(color: c.mutedForeground)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SNButton(label: 'Share Pass', variant: SNButtonVariant.secondary, icon: Icons.share_outlined,
                      onPressed: () => _sharePass(pass)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SNButton(label: 'Show QR', variant: SNButtonVariant.secondary, icon: Icons.qr_code_2,
                      onPressed: () => _showQR(pass)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SNButton(label: 'Revoke Pass', variant: SNButtonVariant.ghost, onPressed: () => _revokePass(pass['id'])),
              ),
            ],
            if (!isActive && pass['used_at'] != null) ...[
              const SizedBox(height: 8),
              Text('Used ${_formatDate(pass['used_at'])}', style: SNText.caption.copyWith(color: c.mutedForeground)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(SNColorTokens c, String status) {
    Color bg; Color fg;
    switch (status) {
      case 'ACTIVE': bg = const Color(0xFF3FB68B).withOpacity(0.1); fg = const Color(0xFF3FB68B); break;
      case 'USED': bg = c.primary.withOpacity(0.1); fg = c.primary; break;
      default: bg = c.muted; fg = c.mutedForeground;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: SNText.sectionLabel.copyWith(color: fg, fontSize: 9)),
    );
  }

  void _showCreateSheet(SNColorTokens c) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    bool creating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SNSheetHandle(),
              const SizedBox(height: SNSpace.x2),
              Text('Generate Visitor Pass', style: SNText.headingMd),
              const SizedBox(height: 4),
              Text('Your visitor must bring a valid ID to the gate.', style: SNText.caption.copyWith(color: c.mutedForeground)),
              const SizedBox(height: 20),
              SNInput(label: 'Visitor Name', controller: nameCtrl, hint: 'Full name as on ID'),
              const SizedBox(height: 16),
              SNInput(label: 'Phone Number', controller: phoneCtrl, hint: 'Required', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              SNInput(label: 'Purpose of Visit', controller: purposeCtrl, hint: 'e.g. Family visit, dropping off items'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: SNButton(
                  label: 'Generate Pass',
                  isLoading: creating,
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Visitor name is required'))); return; }
                    if (phoneCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Phone number is required'))); return; }
                    if (purposeCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Purpose of visit is required'))); return; }
                    setSheetState(() => creating = true);
                    try {
                      final repo = ref.read(bookingsRepositoryProvider);
                      await repo.createVisitorPass(widget.bookingId,
                        visitorName: nameCtrl.text.trim(),
                        visitorPhone: phoneCtrl.text.trim(),
                        purpose: purposeCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadPasses();
                    } catch (e) {
                      setSheetState(() => creating = false);
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to create pass')));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQR(Map<String, dynamic> pass) {
    context.push(Routes.visitorPass, extra: {
      'visitorName': pass['visitor_name'] ?? '',
      'hostelName': widget.hostelName,
      'qrToken': pass['qr_token'] ?? '',
      'validUntil': pass['valid_until'] ?? '',
      'purpose': pass['purpose'] ?? '',
      'visitorPhone': pass['visitor_phone'] ?? '',
    });
  }

  Future<void> _sharePass(Map<String, dynamic> pass) async {
    final user = ref.read(authNotifierProvider);
    final pdf = await VisitorPassGenerator.generate(
      visitorName: pass['visitor_name'] ?? '',
      hostelName: widget.hostelName,
      qrToken: pass['qr_token'] ?? '',
      validUntil: pass['valid_until'] ?? '',
      purpose: pass['purpose'] ?? '',
      visitorPhone: pass['visitor_phone'] ?? '',
      studentName: user?.fullName ?? '',
    );
    await Printing.sharePdf(bytes: pdf, filename: 'StayNest-Visitor-Pass.pdf');
  }

  Future<void> _revokePass(String passId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Pass?'),
        content: const Text('This will invalidate the pass immediately. The visitor will no longer be able to use it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      await repo.revokeVisitorPass(passId);
      _loadPasses();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to revoke pass')));
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${m[d.month - 1]} ${d.day}, ${d.year} at $hour:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}
