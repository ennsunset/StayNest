import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';

final utilityDataProvider = FutureProvider.family<UtilityData, String>((ref, bookingId) {
  return ref.read(bookingsRepositoryProvider).getUtilities(bookingId);
});

class UtilityBillsScreen extends ConsumerWidget {
  final String? bookingId;
  const UtilityBillsScreen({super.key, this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;

    // If no bookingId passed, find active booking
    if (bookingId == null) {
      final bookingsAsync = ref.watch(myBookingsProvider);
      return bookingsAsync.when(
        loading: () => Scaffold(backgroundColor: c.background, body: const Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(backgroundColor: c.background, body: Center(child: Text('Error: $e'))),
        data: (bookings) {
          final active = bookings.where((b) => b.status == 'CONFIRMED' || b.status == 'CHECKED_IN').toList();
          if (active.isEmpty) {
            return Scaffold(
              backgroundColor: c.background,
              body: SafeArea(child: Column(children: [
                _appBar(context, c),
                const Expanded(child: Center(child: Text('No active booking found'))),
              ])),
            );
          }
          return _UtilityBody(bookingId: active.first.id, c: c);
        },
      );
    }

    return _UtilityBody(bookingId: bookingId!, c: c);
  }

  Widget _appBar(BuildContext context, dynamic c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(bottom: BorderSide(color: c.border, width: 1)),
      ),
      child: Row(
        children: [
          SNCircleButton(icon: Icons.arrow_back_rounded, onTap: () => context.canPop() ? context.pop() : context.go('/')),
          const SizedBox(width: 16),
          Text('UTILITY MANAGEMENT', style: SNText.headingMd),
        ],
      ),
    );
  }
}

class _UtilityBody extends ConsumerWidget {
  final String bookingId;
  final dynamic c;
  const _UtilityBody({required this.bookingId, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(utilityDataProvider(bookingId));

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(bottom: BorderSide(color: c.border, width: 1)),
              ),
              child: Row(
                children: [
                  SNCircleButton(icon: Icons.arrow_back_rounded, onTap: () => context.canPop() ? context.pop() : context.go('/')),
                  const SizedBox(width: 16),
                  Text('UTILITY MANAGEMENT', style: SNText.headingMd),
                ],
              ),
            ),
            Expanded(
              child: dataAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load: $e')),
                data: (data) => _buildContent(context, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UtilityData data) {
    final elec = data.accounts.where((a) => a.utilityType == 'ELECTRICITY').toList();
    final elecAccount = elec.isNotEmpty ? elec.first : null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Prepaid credit card
        _buildPrepaidCard(context, elecAccount),
        const SizedBox(height: 32),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('RECENT CONSUMPTION', style: SNText.sectionLabel),
        ),
        const SizedBox(height: 24),

        // Bills list
        _buildBillsList(data.bills),
        const SizedBox(height: 32),

        // AI tip
        _buildAiTip(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrepaidCard(BuildContext context, UtilityAccount? elec) {
    final credit = elec?.creditPesewas ?? 0;
    final daysLeft = elec?.estimatedDaysLeft ?? 0;
    final maxDays = 30;
    final progress = daysLeft / maxDays;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned(top: -40, right: -40, child: Opacity(opacity: 0.05, child: Icon(Icons.bolt_rounded, size: 180, color: c.foreground))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PREPAID CREDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: c.mutedForeground, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(Money.format(credit), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: c.foreground, letterSpacing: -1)),
                  ]),
                  Column(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Icon(Icons.bolt_rounded, size: 24, color: Color(0xFFEA580C))),
                    ),
                    const SizedBox(height: 4),
                    Text('ELECTRICITY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: c.mutedForeground)),
                  ]),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('ESTIMATED DAYS LEFT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFC2410C), letterSpacing: 1.5)),
                    Text('$daysLeft DAYS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF9A3412))),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316))),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recharge coming in a future update'))),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: (c.primary as Color).withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: const Center(child: Text('INSTANT RECHARGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList(List<UtilityBill> bills) {
    if (bills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(32)),
        child: Center(child: Text('No bills yet', style: TextStyle(color: c.mutedForeground))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: bills.asMap().entries.map((entry) {
          final bill = entry.value;
          final isLast = entry.key == bills.length - 1;

          IconData icon;
          Color iconBg, iconColor;
          switch (bill.utilityType) {
            case 'WATER':
              icon = Icons.water_drop_outlined;
              iconBg = const Color(0xFFEFF6FF);
              iconColor = const Color(0xFF2563EB);
              break;
            case 'INTERNET':
              icon = Icons.wifi_rounded;
              iconBg = const Color(0xFFF5F3FF);
              iconColor = const Color(0xFF9333EA);
              break;
            default:
              icon = Icons.bolt_rounded;
              iconBg = const Color(0xFFFFF7ED);
              iconColor = const Color(0xFFEA580C);
          }

          String statusText;
          Color statusColor;
          switch (bill.status) {
            case 'SETTLED':
              statusText = 'SETTLED';
              statusColor = const Color(0xFF16A34A);
              break;
            case 'OVERDUE':
              statusText = 'OVERDUE';
              statusColor = c.destructive;
              break;
            default:
              if (bill.dueDate != null) {
                final daysUntil = bill.dueDate!.difference(DateTime.now()).inDays;
                statusText = 'DUE IN $daysUntil DAYS';
              } else {
                statusText = 'PENDING';
              }
              statusColor = c.primary;
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: c.border, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Icon(icon, size: 20, color: iconColor)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bill.label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c.foreground, letterSpacing: 1.2)),
                  Text((bill.billingPeriod ?? '').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.mutedForeground, letterSpacing: 1.5)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(Money.format(bill.amountPesewas), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c.foreground)),
                  Text(statusText, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: statusColor)),
                ]),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAiTip() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B41),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: const Color(0xFF172554).withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology_rounded, size: 32, color: c.primary),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI ENERGY TIP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c.primary, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            const Text(
              'TENANTS IN BLOCK A WHO TURN OFF AC BETWEEN 10 AM - 4 PM SAVE AN AVERAGE OF GH\u20B5 80 MONTHLY.',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, color: Colors.white70, letterSpacing: 1.5, height: 1.6),
            ),
          ])),
        ],
      ),
    );
  }
}
