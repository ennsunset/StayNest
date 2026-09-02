// features/discovery/presentation/room_details_screen.dart
//
// Screen 17 — Room Details. Wired to real API.
// Room hero, PREMIUM UNIT tag, price, description, config grid,
// scarcity line, Proceed to Booking → navigates to select-bed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';

class RoomDetailsScreen extends ConsumerWidget {
  const RoomDetailsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final roomAsync = ref.watch(roomWithBedsProvider(roomId));

    return roomAsync.when(
      loading: () => Scaffold(
        backgroundColor: c.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: SNErrorState(
            headline: 'Could not load room',
            onRetry: () => ref.invalidate(roomWithBedsProvider(roomId)),
          ),
        ),
      ),
      data: (room) => _buildContent(context, ref, c, room),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SNColorTokens c, RoomWithBeds room) {
    final availableBeds = room.beds.where((b) => b.isAvailable).length;
    final isAC = room.hasAC;
    final isPremium = room.type == '1-in-a-room';
    final tag = isPremium ? 'PREMIUM UNIT' : null;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SNImage(url: room.imageUrl, height: 260, width: double.infinity),
                    if (tag != null)
                      Positioned(
                        top: SNSpace.x10 + SNSpace.x8,
                        left: SNSpace.screenX,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: SNSpace.x3, vertical: SNSpace.x1 + 2),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(SNRadius.xs),
                          ),
                          child: Text(tag, style: SNText.microAction.copyWith(color: c.primaryForeground)),
                        ),
                      ),
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x3),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  height: SNSize.circleButton, width: SNSize.circleButton,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x5, SNSpace.screenX, 120),
                sliver: SliverList.list(
                  children: [
                    // Title + price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${room.type.toUpperCase()}${isAC ? '\n(A/C)' : ''}',
                            style: SNText.headingLg.copyWith(color: c.foreground, fontSize: 24),
                          ),
                        ),
                        PriceTag(amountPesewas: room.pricePesewas),
                      ],
                    ),

                    const SizedBox(height: SNSpace.x4),

                    Text(
                      _roomDescription(room.type, isAC),
                      style: SNText.body.copyWith(color: c.mutedForeground, height: 1.6),
                    ),

                    const SizedBox(height: SNSpace.section),

                    // Room Configuration
                    Text('Room Configuration', style: SNText.headingMd.copyWith(color: c.foreground)),
                    const SizedBox(height: SNSpace.x4),
                    _buildConfigGrid(context, c, room),

                    const SizedBox(height: SNSpace.section),

                    // What's Inside
                    Text("WHAT'S INSIDE", style: SNText.sectionLabel.copyWith(color: c.mutedForeground)),
                    const SizedBox(height: SNSpace.x4),
                    SNCard(
                      padding: const EdgeInsets.all(SNSpace.x4),
                      child: Wrap(
                        spacing: SNSpace.x6,
                        runSpacing: SNSpace.x3,
                        children: [
                          _insideItem(c, 'Twin XL Bed'),
                          _insideItem(c, 'Study Desk'),
                          _insideItem(c, 'Wardrobe'),
                          if (room.hasPrivateBath) _insideItem(c, 'Private Bath'),
                          if (isAC) _insideItem(c, 'AC Incl.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: SNSpace.section),

                    // Scarcity line
                    if (availableBeds > 0 && availableBeds <= 5)
                      SNCard(
                        tinted: true,
                        tint: c.warning,
                        padding: const EdgeInsets.all(SNSpace.x4),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: c.warning),
                            const SizedBox(width: SNSpace.x3),
                            Text(
                              'Only $availableBeds bed${availableBeds == 1 ? '' : 's'} left',
                              style: SNText.bodyBold.copyWith(color: c.warning),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Sticky bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x4),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.border)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: SNButton(
                  label: 'PROCEED TO BOOKING',
                  onPressed: availableBeds > 0
                      ? () => context.push('/home/room/$roomId/select-bed')
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insideItem(SNColorTokens c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: c.success),
        const SizedBox(width: SNSpace.x2),
        Text(label, style: SNText.bodyBold.copyWith(color: c.foreground)),
      ],
    );
  }

  String _roomDescription(String type, bool hasAC) {
    return switch (type) {
      '1-in-a-room' => 'Maximum privacy and comfort. Designed for students who need a focused environment.',
      '2-in-a-room' => 'Share with one roommate. A great balance of affordability and personal space.',
      '3-in-a-room' => 'Shared living at an affordable price. Ideal for social students.',
      '4-in-a-room' => 'The most affordable option. Lively and social living arrangement.',
      _ => 'A comfortable room designed for student living.',
    };
  }

  Widget _buildConfigGrid(BuildContext context, SNColorTokens c, RoomWithBeds room) {
    final items = <(String, IconData)>[
      if (room.hasAC) ('AC', Icons.ac_unit_rounded),
      if (room.hasFan) ('FAN', Icons.air_outlined),
      if (room.hasTV) ('TV', Icons.tv_outlined),
      if (room.hasPrivateBath) ('PRIVATE BATH', Icons.bathtub_outlined),
      if (room.socketCount > 1) ('${room.socketCount} SOCKETS', Icons.electrical_services_outlined),
      if (room.socketCount == 1) ('1 SOCKET', Icons.electrical_services_outlined),
    ];

    return Wrap(
      spacing: SNSpace.x3,
      runSpacing: SNSpace.x3,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - SNSpace.screenX * 2 - SNSpace.x3 * 2) / 3,
          child: SNCard(
            padding: const EdgeInsets.symmetric(vertical: SNSpace.x4, horizontal: SNSpace.x3),
            child: Column(
              children: [
                Container(
                  height: 40, width: 40,
                  decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(SNRadius.sm)),
                  child: Icon(item.$2, size: 20, color: c.primary),
                ),
                const SizedBox(height: SNSpace.x2),
                Text(item.$1, style: SNText.caption.copyWith(color: c.foreground), textAlign: TextAlign.center, maxLines: 2),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
