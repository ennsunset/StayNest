// features/booking/presentation/select_bed_screen.dart
//
// Screen 19 — Select Bed (wired to real API).
// Fetches beds from GET /hostels/rooms/:roomId, polls every 20s.
// Anonymised roommate info (D4: Act 843).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';

class SelectBedScreen extends ConsumerStatefulWidget {
  const SelectBedScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<SelectBedScreen> createState() => _SelectBedScreenState();
}

class _SelectBedScreenState extends ConsumerState<SelectBedScreen> {
  String? _selectedBedId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 20s for freshness — someone else may take a bed
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(roomWithBedsProvider(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final roomAsync = ref.watch(roomWithBedsProvider(widget.roomId));

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Select Bed',
        onBack: () => context.pop(),
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load beds', style: SNText.body.copyWith(color: c.mutedForeground)),
              const SizedBox(height: SNSpace.x4),
              SNButton(label: 'Retry', onPressed: _refresh, variant: SNButtonVariant.secondary),
            ],
          ),
        ),
        data: (room) => _buildContent(context, c, room),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SNColorTokens c, RoomWithBeds room) {
    final selectedBed = _selectedBedId != null
        ? room.beds.where((b) => b.id == _selectedBedId).firstOrNull
        : null;

    // If selected bed was taken by someone else, clear selection
    if (selectedBed != null && !selectedBed.isAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedBedId = null);
      });
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SNSpace.screenX),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room label
                Text(
                  'Room ${room.number} · ${room.type}',
                  style: SNText.headingMd.copyWith(color: c.foreground),
                ),
                const SizedBox(height: SNSpace.x2),
                Text(
                  '${Money.format(room.pricePesewas)}',
                  style: SNText.body.copyWith(color: c.mutedForeground),
                ),
                const SizedBox(height: SNSpace.x2),
                Text(
                  'Select an available bed',
                  style: SNText.caption.copyWith(color: c.mutedForeground),
                ),

                const SizedBox(height: SNSpace.section),

                // Room plan
                _RoomPlan(
                  beds: room.beds,
                  selectedBedId: _selectedBedId,
                  onSelectBed: (id) => setState(() => _selectedBedId = id),
                ),

                const SizedBox(height: SNSpace.section),

                // Roommate info — anonymised (D4: Act 843)
                if (_selectedBedId != null)
                  _buildRoommateSection(c, room.beds),
              ],
            ),
          ),
        ),

        // Sticky footer
        Container(
          padding: const EdgeInsets.all(SNSpace.screenX),
          decoration: BoxDecoration(
            color: c.card,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: SafeArea(
            top: false,
            child: SNButton(
              label: 'Confirm Selection',
              onPressed: _selectedBedId != null
                  ? () => _navigateToReview(context, room)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToReview(BuildContext context, RoomWithBeds room) {
    final bed = room.beds.firstWhere((b) => b.id == _selectedBedId);
    context.push('/booking-review', extra: {
      'bedId': bed.id,
      'bedLabel': bed.label,
      'roomNumber': room.number,
      'roomType': room.type,
      'pricePesewas': room.pricePesewas,
      'hostelName': room.hostelName ?? '',
      'hostelId': room.hostelId ?? '',
      'roomId': room.id,
      'bookingMode': room.bookingMode,
      'semesterPricePesewas': room.semesterPricePesewas,
      'securityDepositPesewas': room.securityDepositPesewas,
    });
  }

  BedState _mapBedStatus(String status) {
    switch (status) {
      case 'AVAILABLE':
        return BedState.available;
      case 'OCCUPIED':
      case 'BOOKED':
        return BedState.occupied;
      case 'HELD':
        return BedState.held;
      case 'MAINTENANCE':
      case 'DISABLED':
        return BedState.maintenance;
      default:
        return BedState.available;
    }
  }

  Widget _buildRoommateSection(SNColorTokens c, List<BedInfo> beds) {
    final occupied = beds.where((b) => b.isOccupied).toList();
    if (occupied.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Roommate Info',
          style: SNText.headingMd.copyWith(color: c.foreground),
        ),
        const SizedBox(height: SNSpace.x4),
        ...occupied.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: SNSpace.x3),
          child: SNCard(
            padding: const EdgeInsets.all(SNSpace.x5),
            child: Row(
              children: [
                const SNAvatar(size: SNSize.avatarMd),
                const SizedBox(width: SNSpace.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b.label} · Occupied',
                        style: SNText.bodyBold.copyWith(color: c.foreground),
                      ),
                      const SizedBox(height: SNSpace.x1),
                      Text(
                        'Identity revealed after booking confirmed',
                        style: SNText.caption.copyWith(color: c.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}


class _RoomPlan extends StatelessWidget {
  const _RoomPlan({
    required this.beds,
    required this.selectedBedId,
    required this.onSelectBed,
  });

  final List<BedInfo> beds;
  final String? selectedBedId;
  final ValueChanged<String> onSelectBed;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final sorted = List<BedInfo>.from(beds)
      ..sort((a, b) => a.label.compareTo(b.label));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: c.border, width: 2),
      ),
      child: AspectRatio(
        aspectRatio: sorted.length <= 2 ? 1.0 : (sorted.length <= 4 ? 0.85 : 0.7),
        child: Stack(
          children: [
            // Dot pattern overlay
            Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter(color: c.foreground)),
            ),
            // Door notch
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 80,
                height: 8,
                decoration: BoxDecoration(
                  color: c.mutedForeground.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
              ),
            ),
            // Beds layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: _buildBedsLayout(c, sorted),
            ),
            // Study desk (for 2+ beds)
            if (sorted.length >= 2)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: c.foreground.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'STUDY DESK',
                    style: SNText.microAction.copyWith(
                      color: c.mutedForeground,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedsLayout(SNColorTokens c, List<BedInfo> beds) {
    if (beds.length == 1) {
      return Center(child: _buildBedTile(c, beds[0]));
    }
    if (beds.length == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Align(alignment: Alignment.center, child: _buildBedTile(c, beds[0]))),
          const SizedBox(width: 48),
          Expanded(child: Align(alignment: Alignment.center, child: _buildBedTile(c, beds[1]))),
        ],
      );
    }
    if (beds.length <= 4) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Expanded(child: _buildBedTile(c, beds[0])),
              const SizedBox(width: 16),
              Expanded(child: _buildBedTile(c, beds[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildBedTile(c, beds[2])),
              const SizedBox(width: 16),
              if (beds.length > 3)
                Expanded(child: _buildBedTile(c, beds[3]))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      );
    }
    // 5+ beds: scrollable 2-column grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: beds.length,
      itemBuilder: (_, i) => _buildBedTile(c, beds[i]),
    );
  }

  Widget _buildBedTile(SNColorTokens c, BedInfo bed) {
    final selected = selectedBedId == bed.id;
    final available = bed.isAvailable;

    final Color fill;
    final Color content;
    final Color borderColor;

    if (selected) {
      fill = c.primary.withValues(alpha: 0.1);
      content = c.primary;
      borderColor = c.primary;
    } else if (available) {
      fill = c.card;
      content = c.foreground;
      borderColor = c.border;
    } else {
      fill = c.muted;
      content = c.mutedForeground;
      borderColor = c.border;
    }

    return GestureDetector(
      onTap: available ? () => onSelectBed(bed.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(maxWidth: 140),
        height: 150,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: selected ? 3 : 2),
        ),
        child: Opacity(
          opacity: available || selected ? 1.0 : 0.6,
          child: Stack(
            children: [
              // Top tint band
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? c.primary.withValues(alpha: 0.15)
                        : c.mutedForeground.withValues(alpha: 0.07),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                ),
              ),
              // Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 28, color: content),
                    const SizedBox(height: 8),
                    Text(
                      bed.label.toUpperCase(),
                      style: SNText.bodyBold.copyWith(
                        color: content,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Positioned(
                bottom: 8, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? c.primary
                          : c.mutedForeground.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selected ? 'SELECTED' : (available ? 'AVAILABLE' : 'OCCUPIED'),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : c.mutedForeground,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  _DotPatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
