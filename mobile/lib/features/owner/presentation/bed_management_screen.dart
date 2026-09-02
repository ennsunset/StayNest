// features/owner/presentation/bed_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

class BedManagementScreen extends ConsumerStatefulWidget {
  const BedManagementScreen({super.key, required this.roomId, this.hostelId = ''});

  final String roomId;
  final String hostelId;

  @override
  ConsumerState<BedManagementScreen> createState() => _BedManagementScreenState();
}

class _BedManagementScreenState extends ConsumerState<BedManagementScreen> {
  List<OwnerBed>? _beds;
  String _roomNumber = '';
  int _maxBeds = 99;
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
      final result = await repo.fetchBeds(widget.roomId);
      if (mounted) {
        setState(() {
          _roomNumber = result.roomNumber;
          _maxBeds = result.maxBeds;
          _beds = result.beds;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  BedState _statusToBedState(String s) {
    switch (s) {
      case 'OCCUPIED': return BedState.occupied;
      case 'BOOKED': return BedState.booked;
      case 'HELD': return BedState.held;
      case 'MAINTENANCE': return BedState.maintenance;
      case 'DISABLED': return BedState.disabled;
      default: return BedState.available;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: _roomNumber.isNotEmpty ? 'Room $_roomNumber' : 'Room',
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: SNText.body.copyWith(color: c.mutedForeground)))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(SNSpace.screenX),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_beds?.length ?? 0} beds in this room',
                                style: SNText.body.copyWith(color: c.mutedForeground),
                              ),
                              const SizedBox(height: SNSpace.x5),
                              Container(
                                padding: const EdgeInsets.all(SNSpace.x5),
                                decoration: BoxDecoration(
                                  borderRadius: SNRadius.card,
                                  border: Border.all(color: c.border),
                                  color: c.card,
                                ),
                                child: _beds == null || _beds!.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(SNSpace.x5),
                                          child: Text('No beds yet', style: SNText.body.copyWith(color: c.mutedForeground)),
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: SNSpace.x4,
                                          crossAxisSpacing: SNSpace.x4,
                                          childAspectRatio: 1.3,
                                        ),
                                        itemCount: _beds!.length,
                                        itemBuilder: (_, i) {
                                          final bed = _beds![i];
                                          return BedTile(
                                            label: bed.label,
                                            state: _statusToBedState(bed.status),
                                            showFullState: true,
                                            onTap: () => _showBedSheet(context, c, bed),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(SNSpace.screenX),
                      decoration: BoxDecoration(
                        color: c.card,
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: (_beds != null && _beds!.length >= _maxBeds)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Room at capacity ($_maxBeds ${_maxBeds == 1 ? "bed" : "beds"})',
                              style: SNText.caption.copyWith(color: c.mutedForeground, fontSize: 12),
                            ),
                          ),
                        )
                      : SNButton(
                          label: 'Add beds to this room',
                          variant: SNButtonVariant.secondary,
                          icon: Icons.add_rounded,
                          onPressed: () => _showAddBedsSheet(context, c),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showAddBedsSheet(BuildContext context, SNColorTokens c) {
    final remaining = _maxBeds - (_beds?.length ?? 0);
    int count = 1;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SNRadius.lg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, SNSpace.screenX),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SNSheetHandle(),
                const SizedBox(height: SNSpace.x2),
                Text('Add Beds', style: SNText.headingMd.copyWith(color: c.foreground)),
                const SizedBox(height: SNSpace.x5),
                Text('How many beds?', style: SNText.body.copyWith(color: c.mutedForeground)),
                const SizedBox(height: SNSpace.x3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: count > 1 ? () => setSheetState(() => count--) : null,
                      icon: Icon(Icons.remove_circle_outline, color: count > 1 ? c.foreground : c.muted),
                    ),
                    const SizedBox(width: SNSpace.x4),
                    Text('$count', style: SNText.headingLg.copyWith(color: c.foreground)),
                    const SizedBox(width: SNSpace.x4),
                    IconButton(
                      onPressed: count < remaining ? () => setSheetState(() => count++) : null,
                      icon: Icon(Icons.add_circle_outline, color: count < remaining ? c.foreground : c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: SNSpace.x5),
                SNButton(
                  label: 'Add $count bed${count > 1 ? "s" : ""}',
                  variant: SNButtonVariant.primary,
                  isLoading: submitting,
                  onPressed: () async {
                    setSheetState(() => submitting = true);
                    try {
                      final repo = ref.read(ownerRepositoryProvider);
                      await repo.addBeds(widget.roomId, count);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$count ${count == 1 ? "bed" : "beds"} added')),
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
        ),
      ),
    );
  }

  void _showBedSheet(BuildContext context, SNColorTokens c, OwnerBed bed) {
    final state = _statusToBedState(bed.status);
    final canToggle = state == BedState.available || state == BedState.maintenance || state == BedState.disabled;

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SNRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, SNSpace.screenX),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SNSheetHandle(),
              const SizedBox(height: SNSpace.x2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bed.label, style: SNText.headingMd.copyWith(color: c.foreground)),
                  SNBadge.bed(state),
                ],
              ),
              if (bed.tenantName != null) ...[
                const SizedBox(height: SNSpace.x3),
                Text(bed.tenantName!, style: SNText.body.copyWith(color: c.mutedForeground)),
              ],
              if (bed.heldUntil != null) ...[
                const SizedBox(height: SNSpace.x3),
                Text('Held until ${bed.heldUntil}', style: SNText.body.copyWith(color: c.mutedForeground)),
              ],
              const SizedBox(height: SNSpace.section),

              if (canToggle) ...[
                if (bed.status != 'AVAILABLE')
                  SNButton(
                    label: 'Mark as Available',
                    variant: SNButtonVariant.secondary,
                    onPressed: () => _updateStatus(bed.id, 'AVAILABLE', context),
                  ),
                if (bed.status != 'MAINTENANCE') ...[
                  if (bed.status != 'AVAILABLE') const SizedBox(height: SNSpace.x3),
                  SNButton(
                    label: 'Mark as Maintenance',
                    variant: SNButtonVariant.secondary,
                    onPressed: () => _updateStatus(bed.id, 'MAINTENANCE', context),
                  ),
                ],
                const SizedBox(height: SNSpace.x3),
                if (bed.status != 'DISABLED')
                  SNButton(
                    label: 'Disable Bed',
                    variant: SNButtonVariant.ghost,
                    onPressed: () => _updateStatus(bed.id, 'DISABLED', context),
                  ),
              ],

              if (canToggle) ...[
                const SizedBox(height: SNSpace.x3),
                SNButton(
                  label: 'Delete Bed',
                  variant: SNButtonVariant.ghost,
                  onPressed: () => _deleteBed(bed.id, context),
                ),
              ],

              if (!canToggle && (bed.status == 'OCCUPIED' || bed.status == 'BOOKED')) ...[
                SNButton(
                  label: 'Check Out Student',
                  variant: SNButtonVariant.secondary,
                  onPressed: () => _checkoutBed(bed.id, context),
                ),
                const SizedBox(height: SNSpace.x3),
              ],

              if (!canToggle) ...[
                Opacity(
                  opacity: 0.5,
                  child: SNButton(
                    label: 'Mark as Available',
                    variant: SNButtonVariant.secondary,
                    onPressed: null,
                  ),
                ),
                const SizedBox(height: SNSpace.x2),
                Text(
                  "Can't change status: bed is ${bed.status.toLowerCase()}",
                  style: SNText.caption.copyWith(color: c.mutedForeground),
                ),
              ],
              const SizedBox(height: SNSpace.x4),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _checkoutBed(String bedId, BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Check out student?'),
        content: const Text('This will complete the booking and make the bed available.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final repo = ref.read(ownerRepositoryProvider);
      await repo.checkoutBed(bedId);
      if (ctx.mounted) Navigator.pop(ctx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student checked out')),
        );
      }
      _load();
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteBed(String bedId, BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Delete bed?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final repo = ref.read(ownerRepositoryProvider);
      await repo.deleteBed(bedId);
      if (ctx.mounted) Navigator.pop(ctx);
      _load();
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _updateStatus(String bedId, String status, BuildContext ctx) async {
    try {
      final repo = ref.read(ownerRepositoryProvider);
      await repo.updateBedStatus(bedId, status);
      if (ctx.mounted) Navigator.pop(ctx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bed marked as ${status.toLowerCase()}')),
        );
      }
      _load();
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}
