// features/owner/presentation/room_management_screen.dart

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
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key, required this.hostelId, this.hostelName = 'Rooms'});

  final String hostelId;
  final String hostelName;

  @override
  ConsumerState<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  List<OwnerRoom>? _rooms;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final rooms = await repo.fetchRooms(widget.hostelId);
      if (mounted) setState(() { _rooms = rooms; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: widget.hostelName,
        onBack: () => context.pop(),
        trailing: SNCircleButton(
          icon: Icons.add_rounded,
          onTap: () => _showAddRoomSheet(context, c),
          filled: true,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: SNText.body.copyWith(color: c.mutedForeground)))
              : _rooms == null || _rooms!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 48, color: c.muted),
                          const SizedBox(height: SNSpace.x4),
                          Text('No rooms yet', style: SNText.body.copyWith(color: c.mutedForeground)),
                          const SizedBox(height: SNSpace.x4),
                          SNButton(
                            label: 'Add first room',
                            variant: SNButtonVariant.primary,
                            icon: Icons.add_rounded,
                            onPressed: () => _showAddRoomSheet(context, c),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(SNSpace.screenX),
                        itemCount: _rooms!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: SNSpace.x3),
                        itemBuilder: (_, i) => GestureDetector(
                          onLongPress: () => _showEditRoomSheet(context, c, _rooms![i]),
                          child: _RoomCard(
                            c: c,
                            room: _rooms![i],
                            onTap: () {
                              context.push('/owner/rooms/${_rooms![i].id}/beds?hostelId=${widget.hostelId}');
                            },
                          ),
                        ),
                      ),
                    ),
    );
  }

  void _showAddRoomSheet(BuildContext context, SNColorTokens c) async {
    final repo = ref.read(ownerRepositoryProvider);

    List<FloorOption>? floors;
    try {
      floors = await repo.fetchFloors(widget.hostelId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load floors')),
        );
      }
      return;
    }

    if (floors.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No floors found. Add a building first.')),
        );
      }
      return;
    }

    if (!mounted) return;

    FloorOption selectedFloor = floors.first;
    String roomNumber = '';
    int roomCapacity = 2;
    String priceText = '';
    bool hasAC = false;
    bool hasFan = false;
    bool hasPrivateBath = false;
    bool hasTV = false;
    int socketCount = 1;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SNRadius.lg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: SNSpace.screenX,
              right: SNSpace.screenX,
              top: 0,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + SNSpace.screenX,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SNSheetHandle(),
                  const SizedBox(height: SNSpace.x2),
                  Text('Add Room', style: SNText.headingMd.copyWith(color: c.foreground)),
                  const SizedBox(height: SNSpace.x5),

                  // Floor picker
                  Text('Floor', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: c.card,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SNSheetHandle(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                                child: Text('Select Floor', style: SNText.headingMd.copyWith(color: c.foreground)),
                              ),
                              ...floors!.map((fl) => ListTile(
                                title: Text('${fl.buildingName} - ${fl.label}', style: SNText.body.copyWith(color: c.foreground)),
                                trailing: fl.id == selectedFloor.id ? Icon(Icons.check, color: c.primary) : null,
                                onTap: () {
                                  setSheetState(() { selectedFloor = fl; });
                                  Navigator.pop(context);
                                },
                              )),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: SNRadius.card,
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text('${selectedFloor.buildingName} - ${selectedFloor.label}', style: SNText.body.copyWith(color: c.foreground), overflow: TextOverflow.ellipsis)),
                          Icon(Icons.keyboard_arrow_down, color: c.mutedForeground),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Room number
                  Text('Room Number', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'e.g. 101, G01',
                      filled: true, fillColor: c.background,
                      border: OutlineInputBorder(borderRadius: SNRadius.card, borderSide: BorderSide(color: c.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: SNText.body.copyWith(color: c.foreground),
                    onChanged: (v) => roomNumber = v,
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Room capacity (1-8)
                  Text('Room Capacity', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  Row(
                    children: List.generate(8, (i) {
                      final cap = i + 1;
                      final selected = roomCapacity == cap;
                      return Padding(
                        padding: const EdgeInsets.only(right: SNSpace.x2),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => roomCapacity = cap),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: selected ? c.primary : c.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
                            ),
                            alignment: Alignment.center,
                            child: Text('$cap', style: SNText.bodyBold.copyWith(color: selected ? c.primaryForeground : c.foreground, fontSize: 13)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Price
                  Text('Annual Price (GH\u20B5)', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2500',
                      filled: true, fillColor: c.background,
                      border: OutlineInputBorder(borderRadius: SNRadius.card, borderSide: BorderSide(color: c.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: SNText.body.copyWith(color: c.foreground),
                    onChanged: (v) => priceText = v,
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Features grid
                  Text('Features', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  Wrap(
                    spacing: SNSpace.x3,
                    runSpacing: SNSpace.x2,
                    children: [
                      _FeatureToggle(label: 'AC', value: hasAC, c: c, onChanged: (v) => setSheetState(() => hasAC = v)),
                      _FeatureToggle(label: 'Fan', value: hasFan, c: c, onChanged: (v) => setSheetState(() => hasFan = v)),
                      _FeatureToggle(label: 'Private Bath', value: hasPrivateBath, c: c, onChanged: (v) => setSheetState(() => hasPrivateBath = v)),
                      _FeatureToggle(label: 'TV', value: hasTV, c: c, onChanged: (v) => setSheetState(() => hasTV = v)),
                    ],
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Socket count
                  Text('Number of Sockets', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  Row(
                    children: List.generate(6, (i) {
                      final n = i + 1;
                      final selected = socketCount == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: SNSpace.x2),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => socketCount = n),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: selected ? c.primary : c.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
                            ),
                            alignment: Alignment.center,
                            child: Text('$n', style: SNText.bodyBold.copyWith(color: selected ? c.primaryForeground : c.foreground, fontSize: 13)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: SNSpace.x5),

                  // Submit
                  SNButton(
                    label: 'Create Room',
                    variant: SNButtonVariant.primary,
                    isLoading: submitting,
                    onPressed: () async {
                      if (roomNumber.trim().isEmpty) return;
                      final price = double.tryParse(priceText);
                      if (price == null || price <= 0) return;

                      setSheetState(() => submitting = true);
                      try {
                        await repo.createRoom(widget.hostelId, {
                          'floorId': selectedFloor.id,
                          'number': roomNumber.trim(),
                          'type': '$roomCapacity-in-a-room',
                          'pricePesewas': (price * 100).round(),
                          'hasAC': hasAC,
                          'hasFan': hasFan,
                          'hasPrivateBath': hasPrivateBath,
                          'hasTV': hasTV,
                          'socketCount': socketCount,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        setSheetState(() => submitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: SNSpace.x4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditRoomSheet(BuildContext context, SNColorTokens c, OwnerRoom room) async {
    final repo = ref.read(ownerRepositoryProvider);

    int roomCapacity = int.tryParse(room.type.split('-').first) ?? 2;
    String priceText = (room.pricePesewas / 100).toStringAsFixed(0);
    bool hasAC = room.hasAC;
    bool hasFan = room.hasFan;
    bool hasPrivateBath = room.hasPrivateBath;
    bool hasTV = room.hasTV;
    int socketCount = room.socketCount;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SNRadius.lg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: SNSpace.screenX,
              right: SNSpace.screenX,
              top: 0,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + SNSpace.screenX,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SNSheetHandle(),
                  const SizedBox(height: SNSpace.x2),
                  Text('Edit Room ${room.number}', style: SNText.headingMd.copyWith(color: c.foreground)),
                  const SizedBox(height: SNSpace.x5),

                  // Room capacity
                  Text('Room Capacity', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  Row(
                    children: List.generate(8, (i) {
                      final cap = i + 1;
                      final selected = roomCapacity == cap;
                      return Padding(
                        padding: const EdgeInsets.only(right: SNSpace.x2),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => roomCapacity = cap),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: selected ? c.primary : c.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
                            ),
                            alignment: Alignment.center,
                            child: Text('$cap', style: SNText.bodyBold.copyWith(color: selected ? c.primaryForeground : c.foreground, fontSize: 13)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Price
                  Text('Annual Price (GH\u20B5)', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  TextFormField(
                    initialValue: priceText,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true, fillColor: c.background,
                      border: OutlineInputBorder(borderRadius: SNRadius.card, borderSide: BorderSide(color: c.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: SNText.body.copyWith(color: c.foreground),
                    onChanged: (v) => priceText = v,
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Features
                  Text('Features', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  Wrap(
                    spacing: SNSpace.x3,
                    runSpacing: SNSpace.x2,
                    children: [
                      _FeatureToggle(label: 'AC', value: hasAC, c: c, onChanged: (v) => setSheetState(() => hasAC = v)),
                      _FeatureToggle(label: 'Fan', value: hasFan, c: c, onChanged: (v) => setSheetState(() => hasFan = v)),
                      _FeatureToggle(label: 'Private Bath', value: hasPrivateBath, c: c, onChanged: (v) => setSheetState(() => hasPrivateBath = v)),
                      _FeatureToggle(label: 'TV', value: hasTV, c: c, onChanged: (v) => setSheetState(() => hasTV = v)),
                    ],
                  ),
                  const SizedBox(height: SNSpace.x4),

                  // Sockets
                  Text('Number of Sockets', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  const SizedBox(height: SNSpace.x2),
                  Row(
                    children: List.generate(6, (i) {
                      final n = i + 1;
                      final selected = socketCount == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: SNSpace.x2),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => socketCount = n),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: selected ? c.primary : c.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
                            ),
                            alignment: Alignment.center,
                            child: Text('$n', style: SNText.bodyBold.copyWith(color: selected ? c.primaryForeground : c.foreground, fontSize: 13)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: SNSpace.x5),

                  // Save
                  SNButton(
                    label: 'Save Changes',
                    variant: SNButtonVariant.primary,
                    isLoading: submitting,
                    onPressed: () async {
                      final price = double.tryParse(priceText);
                      if (price == null || price <= 0) return;

                      setSheetState(() => submitting = true);
                      try {
                        await repo.updateRoom(room.id, {
                          'type': '$roomCapacity-in-a-room',
                          'pricePesewas': (price * 100).round(),
                          'hasAC': hasAC,
                          'hasFan': hasFan,
                          'hasPrivateBath': hasPrivateBath,
                          'hasTV': hasTV,
                          'socketCount': socketCount,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Room updated')),
                          );
                        }
                        _load();
                      } catch (e) {
                        setSheetState(() => submitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: SNSpace.x4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  const _FeatureToggle({required this.label, required this.value, required this.c, required this.onChanged});
  final String label;
  final bool value;
  final SNColorTokens c;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? c.accent.withValues(alpha: 0.15) : c.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? c.accent : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check : Icons.close, size: 14, color: value ? c.primary : c.mutedForeground),
            const SizedBox(width: 4),
            Text(label, style: SNText.bodyBold.copyWith(color: value ? c.primary : c.foreground, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.c, required this.room, required this.onTap});

  final SNColorTokens c;
  final OwnerRoom room;
  final VoidCallback onTap;

  BedState get _bedState {
    switch (room.dominantStatus) {
      case 'OCCUPIED': return BedState.occupied;
      case 'MAINTENANCE': return BedState.maintenance;
      default: return BedState.available;
    }
  }

  String get _typeLabel => '${room.type.split('-').first}-in-a-room';

  @override
  Widget build(BuildContext context) {
    return SNCard(
      onTap: onTap,
      padding: const EdgeInsets.all(SNSpace.x4),
      child: Row(
        children: [
          // Room icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.meeting_room_rounded, color: c.accent, size: 24),
          ),
          const SizedBox(width: SNSpace.x4),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Room ${room.number}', style: SNText.bodyBold.copyWith(color: c.foreground)),
                    SNBadge.bed(_bedState),
                  ],
                ),
                const SizedBox(height: SNSpace.x1),
                Text('${room.floorLabel}  •  $_typeLabel', style: SNText.caption.copyWith(color: c.mutedForeground)),
                const SizedBox(height: SNSpace.x2),
                Row(
                  children: [
                    Text(Money.formatCompact(room.pricePesewas), style: SNText.bodyBold.copyWith(color: c.foreground)),
                    Text('/yr', style: SNText.caption.copyWith(color: c.mutedForeground)),
                    const Spacer(),
                    Text('${room.occupiedBeds}/${room.totalBeds} occupied', style: SNText.caption.copyWith(color: c.mutedForeground)),
                  ],
                ),
                if (room.hasAC || room.hasFan || room.hasPrivateBath || room.hasTV) ...[
                  const SizedBox(height: SNSpace.x2),
                  Wrap(
                    spacing: SNSpace.x2,
                    children: [
                      if (room.hasAC) _featureChip('AC', c),
                      if (room.hasFan) _featureChip('Fan', c),
                      if (room.hasPrivateBath) _featureChip('Bath', c),
                      if (room.hasTV) _featureChip('TV', c),
                      if (room.socketCount > 1) _featureChip('${room.socketCount} sockets', c),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: SNSpace.x2),
          Icon(Icons.chevron_right_rounded, color: c.muted),
        ],
      ),
    );
  }

  Widget _featureChip(String label, SNColorTokens c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.muted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: SNText.caption.copyWith(color: c.mutedForeground, fontSize: 10)),
    );
  }
}
