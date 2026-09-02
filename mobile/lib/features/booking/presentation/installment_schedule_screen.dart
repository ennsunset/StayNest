// features/booking/presentation/installment_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/features/payment/data/payments_repository.dart';

class InstallmentScheduleScreen extends ConsumerStatefulWidget {
  const InstallmentScheduleScreen({
    super.key,
    required this.bookingId,
    required this.hostelName,
    required this.roomLabel,
  });

  final String bookingId;
  final String hostelName;
  final String roomLabel;

  @override
  ConsumerState<InstallmentScheduleScreen> createState() => _InstallmentScheduleScreenState();
}

class _InstallmentScheduleScreenState extends ConsumerState<InstallmentScheduleScreen> {
  Map<String, dynamic>? _plan;
  List<dynamic> _installments = [];
  bool _loading = true;
  String? _error;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final result = await repo.getInstallmentPlan(widget.bookingId);
      if (mounted) {
        setState(() {
          _plan = result['plan'] as Map<String, dynamic>?;
          _installments = (result['installments'] as List<dynamic>?) ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load installment plan'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Installment Plan',
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: SNText.body.copyWith(color: c.mutedForeground)),
                    const SizedBox(height: 16),
                    SNButton(label: 'Retry', onPressed: _loadPlan),
                  ],
                ))
              : _plan == null
                  ? Center(child: Text('No installment plan found', style: SNText.body.copyWith(color: c.mutedForeground)))
                  : _buildContent(c),
    );
  }

  Widget _buildContent(SNColorTokens c) {
    final total = _safeInt(_plan!['total_pesewas']);
    final paid = _installments
        .where((i) => i['status'] == 'PAID')
        .fold<int>(0, (sum, i) => sum + _safeInt(i['amount_pesewas']));
    final remaining = total - paid;
    final planStatus = _plan!['status'] as String? ?? 'ACTIVE';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SNSpace.screenX),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SNSpace.x5),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2B41),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hostelName,
                  style: SNText.headingMd.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.roomLabel,
                  style: SNText.caption.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: SNSpace.x5),
                Row(
                  children: [
                    Expanded(child: _summaryCol('Paid', Money.format(paid), const Color(0xFF3FB68B))),
                    Expanded(child: _summaryCol('Due', Money.format(remaining), remaining > 0 ? const Color(0xFFE8A33D) : const Color(0xFF3FB68B))),
                  ],
                ),
                const SizedBox(height: 16),
                _summaryCol('Total', Money.format(total), Colors.white),
                const SizedBox(height: SNSpace.x4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _planStatusColor(planStatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _planStatusColor(planStatus).withOpacity(0.3)),
                  ),
                  child: Text(
                    _planStatusLabel(planStatus),
                    style: SNText.sectionLabel.copyWith(color: _planStatusColor(planStatus), fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SNSpace.section),

          // ── Timeline ──
          SNSectionLabel('Payment Schedule'),
          const SizedBox(height: SNSpace.x4),
          ..._installments.asMap().entries.map((entry) {
            final i = entry.value as Map<String, dynamic>;
            final isLast = entry.key == _installments.length - 1;
            return _buildInstallmentTile(c, i, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildInstallmentTile(SNColorTokens c, Map<String, dynamic> inst, bool isLast) {
    final status = inst['status'] as String? ?? 'PENDING';
    final amount = _safeInt(inst['amount_pesewas']);
    final dueDate = inst['due_date'] as String? ?? '';
    final paidAt = inst['paid_at'] as String?;
    final seq = inst['sequence'] as int? ?? 0;
    final isPaid = status == 'PAID';
    final isOverdue = status == 'OVERDUE';
    final isGrace = status == 'GRACE';
    final canPay = !isPaid;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPaid ? c.primary : isOverdue ? const Color(0xFFDC3545) : c.muted,
                    border: Border.all(
                      color: isPaid ? c.primary : isOverdue ? const Color(0xFFDC3545) : c.border,
                      width: 2,
                    ),
                  ),
                  child: isPaid
                      ? Icon(Icons.check, size: 12, color: c.primaryForeground)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isPaid ? c.primary.withOpacity(0.3) : c.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: SNCard(
                padding: const EdgeInsets.all(SNSpace.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Installment $seq',
                          style: SNText.bodyBold.copyWith(color: c.foreground),
                        ),
                        _statusBadge(c, status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Money.format(amount),
                      style: SNText.headingMd.copyWith(
                        color: isPaid ? c.primary : isOverdue ? const Color(0xFFDC3545) : c.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPaid
                          ? 'Paid ${_formatDate(paidAt ?? '')}'
                          : isGrace
                              ? 'Due ${_formatDate(dueDate)} · Grace period'
                              : 'Due ${_formatDate(dueDate)}',
                      style: SNText.caption.copyWith(color: c.mutedForeground),
                    ),
                    if (canPay) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SNButton(
                          label: isOverdue ? 'Pay now (overdue)' : 'Pay now',
                          isLoading: _paying,
                          onPressed: () => _payInstallment(inst),
                          variant: isOverdue ? SNButtonVariant.primary : SNButtonVariant.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _payInstallment(Map<String, dynamic> inst) async {
    setState(() => _paying = true);
    try {
      final paymentsRepo = ref.read(paymentsRepositoryProvider);
      final payment = await paymentsRepo.initializeInstallment(
        bookingId: widget.bookingId,
        installmentId: inst['id'] as String,
        callbackUrl: 'https://staynest.app/payment/callback',
      );
      if (!mounted) return;
      context.push('/payment', extra: {
        'authorizationUrl': payment.authorizationUrl,
        'reference': payment.reference,
        'bookingId': widget.bookingId,
        'hostelName': widget.hostelName,
        'roomLabel': widget.roomLabel,
        'bedLabel': '',
        'installmentId': inst['id'],
      });
      setState(() => _paying = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize payment')),
      );
    }
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: SNText.sectionLabel.copyWith(color: Colors.white54, fontSize: 9)),
        const SizedBox(height: 4),
        Text(value, style: SNText.bodyBold.copyWith(color: color, fontSize: 15)),
      ],
    );
  }

  Widget _statusBadge(SNColorTokens c, String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'PAID':
        bg = const Color(0xFF3FB68B).withOpacity(0.1);
        fg = const Color(0xFF3FB68B);
        break;
      case 'OVERDUE':
        bg = const Color(0xFFDC3545).withOpacity(0.1);
        fg = const Color(0xFFDC3545);
        break;
      case 'GRACE':
        bg = const Color(0xFFE8A33D).withOpacity(0.1);
        fg = const Color(0xFFE8A33D);
        break;
      default:
        bg = c.muted;
        fg = c.mutedForeground;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: SNText.sectionLabel.copyWith(color: fg, fontSize: 9),
      ),
    );
  }

  Color _planStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return const Color(0xFF3FB68B);
      case 'DEFAULTED': return const Color(0xFFDC3545);
      default: return const Color(0xFF3FB68B);
    }
  }

  String _planStatusLabel(String status) {
    switch (status) {
      case 'COMPLETED': return 'ALL PAID';
      case 'DEFAULTED': return 'OVERDUE';
      default: return 'IN PROGRESS';
    }
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
