import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';

class CompareHostelsScreen extends ConsumerStatefulWidget {
  const CompareHostelsScreen({super.key, required this.hostelIds});
  final List<String> hostelIds;

  @override
  ConsumerState<CompareHostelsScreen> createState() => _CompareHostelsScreenState();
}

class _CompareHostelsScreenState extends ConsumerState<CompareHostelsScreen> {
  List<Hostel>? _hostels;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHostels();
  }

  Future<void> _loadHostels() async {
    try {
      final repo = ref.read(hostelsRepositoryProvider);
      final futures = widget.hostelIds.map((id) => repo.fetchById(id));
      final results = await Future.wait(futures);
      if (mounted) setState(() { _hostels = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static const _compareAmenities = [
    'WIFI',
    'POWER_BACKUP',
    'WATER_SUPPLY',
    'LAUNDRY',
    'SECURITY',
    'KITCHEN',
    'PARKING',
    'AIR_CONDITIONING',
  ];

  static const _amenityLabels = {
    'WIFI': 'WiFi',
    'POWER_BACKUP': 'Power Backup',
    'WATER_SUPPLY': 'Water Supply',
    'LAUNDRY': 'Laundry',
    'SECURITY': 'Security',
    'KITCHEN': 'Kitchen',
    'PARKING': 'Parking',
    'AIR_CONDITIONING': 'Air Conditioning',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Comparison',
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: SNEmptyState(
                    icon: Icons.error_outline,
                    headline: 'Failed to load hostels',
                    actionLabel: 'Retry',
                    onAction: _loadHostels,
                  ),
                )
              : _buildComparison(c),
    );
  }

  Widget _buildComparison(SNColorTokens c) {
    final hostels = _hostels!;
    final colWidth = (MediaQuery.of(context).size.width - SNSpace.screenX * 2 - 120) / hostels.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.navClear),
      child: Column(
        children: [
          // ── Hostel headers ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 120),
              ...hostels.map((h) => SizedBox(
                width: colWidth,
                child: GestureDetector(
                  onTap: () => context.push('/home/hostel/${h.id}'),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(SNRadius.lg),
                        child: SNImage(
                          url: h.imageUrls.isNotEmpty ? h.imageUrls.first : null,
                          width: colWidth - 8,
                          height: colWidth - 8,
                        ),
                      ),
                      const SizedBox(height: SNSpace.x2),
                      Text(
                        h.name,
                        style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: SNSpace.x6),

          // ── Price row ──
          _CompareRow(
            label: 'PRICE / SEM',
            c: c,
            values: hostels.map((h) => Text(
              Money.format(h.fromPricePesewas),
              style: SNText.bodyBold.copyWith(color: c.primary, fontSize: 13),
              textAlign: TextAlign.center,
            )).toList(),
            colWidth: colWidth,
          ),

          // ── Address row ──
          _CompareRow(
            label: 'LOCATION',
            c: c,
            values: hostels.map((h) => Text(
              h.address,
              style: SNText.caption.copyWith(color: c.foreground, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )).toList(),
            colWidth: colWidth,
          ),

          // ── Amenity rows ──
          ..._compareAmenities.map((amenityKey) {
            final label = _amenityLabels[amenityKey] ?? amenityKey;
            return _CompareRow(
              label: label.toUpperCase(),
              c: c,
              values: hostels.map((h) {
                final has = h.amenities.any((a) => a.name.toUpperCase() == amenityKey);
                return Icon(
                  has ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: has ? const Color(0xFF16A34A) : c.border,
                  size: 22,
                );
              }).toList(),
              colWidth: colWidth,
            );
          }),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.label, required this.c, required this.values, required this.colWidth});
  final String label;
  final SNColorTokens c;
  final List<Widget> values;
  final double colWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: SNSpace.x4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: SNText.microAction.copyWith(
                color: c.mutedForeground,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...values.map((v) => SizedBox(
            width: colWidth,
            child: Center(child: v),
          )),
        ],
      ),
    );
  }
}
