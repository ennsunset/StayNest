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
  Hostel? _hostelA;
  Hostel? _hostelB;
  String? _selectedRoomTypeA;
  String? _selectedRoomTypeB;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHostels();
  }

  Future<void> _loadHostels() async {
    try {
      setState(() { _loading = true; _error = null; });
      final repo = ref.read(hostelsRepositoryProvider);
      final ids = widget.hostelIds;
      if (ids.isEmpty) {
        setState(() { _loading = false; _error = 'No hostels selected'; });
        return;
      }
      final a = await repo.fetchById(ids[0]);
      final b = ids.length > 1 ? await repo.fetchById(ids[1]) : null;
      if (mounted) setState(() {
        _hostelA = a; _hostelB = b; _loading = false;
        _selectedRoomTypeA = a.rooms.isNotEmpty ? a.rooms.first.type : null;
        _selectedRoomTypeB = b != null && b.rooms.isNotEmpty ? b.rooms.first.type : null;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _swapHostel(int slot) async {
    final query = TextEditingController();
    final result = await showModalBottomSheet<Hostel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchHostelSheet(query: query, repo: ref.read(hostelsRepositoryProvider)),
    );
    if (result != null && mounted) {
      // Swap needs full detail for rooms — search returns shallow data
        final fullHostel = await ref.read(hostelsRepositoryProvider).fetchById(result.id);
        if (!mounted) return;
        setState(() {
          if (slot == 0) {
            _hostelA = fullHostel;
            _selectedRoomTypeA = fullHostel.rooms.isNotEmpty ? fullHostel.rooms.first.type : null;
          } else {
            _hostelB = fullHostel;
            _selectedRoomTypeB = fullHostel.rooms.isNotEmpty ? fullHostel.rooms.first.type : null;
          }
        });
    }
  }

  static const _compareAmenities = [
    'WIFI', 'POWER_BACKUP', 'WATER_SUPPLY', 'LAUNDRY',
    'SECURITY', 'KITCHEN', 'PARKING', 'AIR_CONDITIONING',
  ];

  static const _amenityLabels = {
    'WIFI': 'WiFi',
    'POWER_BACKUP': 'Power Backup',
    'WATER_SUPPLY': 'Water Supply',
    'LAUNDRY': 'Laundry',
    'SECURITY': 'Security',
    'KITCHEN': 'Kitchen',
    'PARKING': 'Parking',
    'AIR_CONDITIONING': 'AC',
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
              ? Center(child: SNEmptyState(icon: Icons.error_outline, headline: 'Failed to load hostels', actionLabel: 'Retry', onAction: _loadHostels))
              : _buildComparison(c),
    );
  }

  Widget _buildComparison(SNColorTokens c) {
    final colWidth = (MediaQuery.of(context).size.width - 24 * 2 - 100) / 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      child: Column(
        children: [
          // ── Hostel headers ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 100),
              _hostelHeader(c, _hostelA, colWidth, 0),
              _hostelHeader(c, _hostelB, colWidth, 1),
            ],
          ),
          const SizedBox(height: 24),

          // ── Location ──
          _row(c, 'LOCATION', colWidth, [
            _textCell(c, _hostelA?.address ?? '—'),
            _textCell(c, _hostelB?.address ?? '—'),
          ]),

          // ── Room Type Picker ──
          _row(c, 'ROOM TYPE', colWidth, [
            _roomTypePicker(c, _hostelA, _selectedRoomTypeA, (v) => setState(() => _selectedRoomTypeA = v)),
            _roomTypePicker(c, _hostelB, _selectedRoomTypeB, (v) => setState(() => _selectedRoomTypeB = v)),
          ]),

          // ── Room Price ──
          _row(c, 'ROOM PRICE', colWidth, [
            _roomDetailCell(c, _hostelA, _selectedRoomTypeA, (r) => Money.format(r.pricePesewas), isPrimary: true),
            _roomDetailCell(c, _hostelB, _selectedRoomTypeB, (r) => Money.format(r.pricePesewas), isPrimary: true),
          ]),
          // ── Security Deposit ──
          _row(c, 'DEPOSIT', colWidth, [
            _roomDetailCell(c, _hostelA, _selectedRoomTypeA, (r) => r.securityDepositPesewas > 0 ? Money.format(r.securityDepositPesewas) : 'None'),
            _roomDetailCell(c, _hostelB, _selectedRoomTypeB, (r) => r.securityDepositPesewas > 0 ? Money.format(r.securityDepositPesewas) : 'None'),
          ]),

          // ── Amenities ──
          ..._compareAmenities.map((key) => _row(
            c,
            (_amenityLabels[key] ?? key).toUpperCase(),
            colWidth,
            [
              _amenityCell(c, _hostelA, key),
              _amenityCell(c, _hostelB, key),
            ],
          )),
        ],
      ),
    );
  }

  Widget _hostelHeader(SNColorTokens c, Hostel? hostel, double colWidth, int slot) {
    if (hostel == null) {
      return SizedBox(
        width: colWidth,
        child: GestureDetector(
          onTap: () => _swapHostel(slot),
          child: Column(
            children: [
              Container(
                width: colWidth - 16,
                height: colWidth - 16,
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border, width: 1.5),
                ),
                child: Icon(Icons.add_rounded, color: c.mutedForeground, size: 32),
              ),
              const SizedBox(height: 8),
              Text('Add hostel', style: SNText.caption.copyWith(color: c.mutedForeground)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: colWidth,
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => context.push('/home/hostel/${hostel.id}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SNImage(
                    url: hostel.imageUrls.isNotEmpty ? hostel.imageUrls.first : null,
                    width: colWidth - 16,
                    height: colWidth - 16,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () => _swapHostel(slot),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hostel.name,
            style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _priceCell(SNColorTokens c, Hostel? h) {
    if (h == null) return const SizedBox.shrink();
    return Text(Money.format(h.fromPricePesewas), style: SNText.bodyBold.copyWith(color: c.primary, fontSize: 13), textAlign: TextAlign.center);
  }

  Widget _textCell(SNColorTokens c, String text) {
    return Text(text, style: SNText.caption.copyWith(color: c.foreground, fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  Widget _roomTypePicker(SNColorTokens c, Hostel? h, String? selected, ValueChanged<String?> onChanged) {
    if (h == null) return const SizedBox.shrink();
    final types = h.rooms.map((r) => r.type).toSet().toList()..sort();
    if (types.isEmpty) return Text('—', style: SNText.caption.copyWith(color: c.mutedForeground));
    if (types.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(types.first, style: SNText.caption.copyWith(color: c.primary, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(8)),
      child: DropdownButton<String>(
        value: selected ?? types.first,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: SNText.caption.copyWith(color: c.foreground, fontSize: 11, fontWeight: FontWeight.w700),
        items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _roomDetailCell(SNColorTokens c, Hostel? h, String? selectedType, String Function(RoomSummary) formatter, {bool isPrimary = false}) {
    if (h == null) return const SizedBox.shrink();
    final type = selectedType ?? (h.rooms.isNotEmpty ? h.rooms.first.type : null);
    if (type == null) return Text('—', style: SNText.caption.copyWith(color: c.mutedForeground));
    final rooms = h.rooms.where((r) => r.type == type).toList();
    if (rooms.isEmpty) return Text('—', style: SNText.caption.copyWith(color: c.mutedForeground));
    // Aggregate: show range or first
    final values = rooms.map(formatter).toSet().toList();
    final display = values.length == 1 ? values.first : values.join(' – ');
    return Text(display, style: SNText.bodyBold.copyWith(color: isPrimary ? c.primary : c.foreground, fontSize: 12), textAlign: TextAlign.center);
  }

  Widget _amenityCell(SNColorTokens c, Hostel? h, String key) {
    if (h == null) return const SizedBox.shrink();
    final has = h.amenities.any((a) => a.name.toUpperCase() == key);
    return Icon(
      has ? Icons.check_circle_outline : Icons.cancel_outlined,
      color: has ? const Color(0xFF16A34A) : c.border,
      size: 22,
    );
  }

  Widget _row(SNColorTokens c, String label, double colWidth, List<Widget> values) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.5)))),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
          ),
          ...values.map((v) => SizedBox(width: colWidth, child: Center(child: v))),
        ],
      ),
    );
  }
}

// ── Search sheet for swapping a hostel ──
class _SearchHostelSheet extends StatefulWidget {
  const _SearchHostelSheet({required this.query, required this.repo});
  final TextEditingController query;
  final HostelsRepository repo;

  @override
  State<_SearchHostelSheet> createState() => _SearchHostelSheetState();
}

class _SearchHostelSheetState extends State<_SearchHostelSheet> {
  List<Hostel> _results = [];
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    try {
      final results = await widget.repo.search(query: q.trim());
      if (mounted) setState(() { _results = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SNColorTokens>()!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: widget.query,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search hostels...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: c.muted,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          Expanded(
            child: Material(color: Colors.transparent, child: ListView.builder(
              itemCount: _results.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (ctx, i) {
                final h = _results[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SNImage(url: h.imageUrls.isNotEmpty ? h.imageUrls.first : null, width: 48, height: 48),
                  ),
                  title: Text(h.name, style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 14)),
                  subtitle: Text(h.address, style: SNText.caption.copyWith(color: c.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(Money.format(h.fromPricePesewas), style: SNText.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(ctx, h),
                );
              },
            )),
          ),
        ],
      ),
    );
  }
}
