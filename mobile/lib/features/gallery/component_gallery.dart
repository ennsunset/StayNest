// features/gallery/component_gallery.dart
//
// Sprint 0 deliverable: every primitive and domain widget rendered in all
// relevant states. This is how you prove the design system works before
// building a single screen.
//
// Delete this file before the pilot. It is scaffolding, not product.

import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/theme/status_palette.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/layout/sn_bottom_nav.dart';

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  int _navIndex = 0;
  bool _chipSelected = false;
  bool _saved = false;
  BedState _bedState = BedState.available;
  int? _selectedBed;
  final _inputCtl = TextEditingController();

  @override
  void dispose() {
    _inputCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Component Gallery',
        onBack: () {},
        trailing: SNCircleButton(
          icon: Icons.notifications_outlined,
          onTap: () {},
          badge: 3,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: SNSpace.screenX,
          right: SNSpace.screenX,
          bottom: SNSpace.navClear,
        ),
        children: [
          // ── Colours ────────────────────────────────────────
          _section('Colours'),
          Wrap(
            spacing: SNSpace.x2,
            runSpacing: SNSpace.x2,
            children: [
              _swatch('primary', c.primary),
              _swatch('secondary', c.secondary),
              _swatch('muted', c.muted),
              _swatch('accent', c.accent),
              _swatch('destructive', c.destructive),
              _swatch('success', c.success),
              _swatch('warning', c.warning),
              _swatch('foreground', c.foreground),
              _swatch('border', c.border),
            ],
          ),

          // ── Typography ─────────────────────────────────────
          _section('Typography'),
          Text('Display Large', style: SNText.displayLg.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x2),
          Text('Display Medium', style: SNText.displayMd.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x2),
          Text('Heading Large', style: SNText.headingLg.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x2),
          Text('Heading Medium', style: SNText.headingMd.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x2),
          Text('Body Large', style: SNText.bodyLg.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x2),
          Text('Body', style: SNText.body.copyWith(color: c.foreground)),
          const SizedBox(height: SNSpace.x2),
          Text('Caption', style: SNText.caption.copyWith(color: c.mutedForeground)),
          const SizedBox(height: SNSpace.x2),
          Text('SECTION LABEL', style: SNText.sectionLabel.copyWith(color: c.mutedForeground)),
          const SizedBox(height: SNSpace.x2),
          Text('MICRO ACTION', style: SNText.microAction.copyWith(color: c.primary)),
          const SizedBox(height: SNSpace.x2),
          Text('STN-2026-X8R2', style: SNText.mono.copyWith(color: c.foreground)),

          // ── Buttons ────────────────────────────────────────
          _section('Buttons'),
          SNButton(label: 'Primary Button', onPressed: () {}),
          const SizedBox(height: SNSpace.x3),
          SNButton(label: 'Loading', onPressed: () {}, isLoading: true),
          const SizedBox(height: SNSpace.x3),
          const SNButton(label: 'Disabled', onPressed: null),
          const SizedBox(height: SNSpace.x3),
          SNButton.secondary(label: 'Secondary', onPressed: () {}),
          const SizedBox(height: SNSpace.x3),
          Row(
            children: [
              SNButton.ghost(label: 'Ghost', onPressed: () {}),
              const SizedBox(width: SNSpace.x4),
              SNButton.destructive(label: 'Destructive', onPressed: () {}),
            ],
          ),

          // ── Inputs ─────────────────────────────────────────
          _section('Inputs'),
          SNInput(
            label: 'Email',
            hint: 'you@university.edu.gh',
            prefixIcon: Icons.email_outlined,
            controller: _inputCtl,
          ),
          const SizedBox(height: SNSpace.x4),
          const SNInput(
            label: 'Password',
            hint: 'Enter password',
            obscure: true,
          ),
          const SizedBox(height: SNSpace.x4),
          const SNInput(
            label: 'With Error',
            hint: 'Oops',
            errorText: 'This field is required',
          ),
          const SizedBox(height: SNSpace.x4),
          const SNInput(
            label: 'Disabled',
            hint: 'Cannot edit',
            enabled: false,
          ),

          // ── Cards ──────────────────────────────────────────
          _section('Cards'),
          const SNCard(
            child: Text('Standard card with border and shadow'),
          ),
          const SizedBox(height: SNSpace.x3),
          const SNCard(
            tinted: true,
            child: Text('Tinted info card (primary/5 background)'),
          ),
          const SizedBox(height: SNSpace.x3),
          SNCard(
            selected: true,
            child: const Text('Selected card (e.g. payment method)'),
            onTap: () {},
          ),

          // ── Badges ─────────────────────────────────────────
          _section('Status Badges'),
          Wrap(
            spacing: SNSpace.x2,
            runSpacing: SNSpace.x2,
            children: [
              SNBadge.bed(BedState.available),
              SNBadge.bed(BedState.held),
              SNBadge.bed(BedState.booked),
              SNBadge.bed(BedState.occupied),
              SNBadge.bed(BedState.maintenance),
              SNBadge.booking(BookingState.confirmed),
              SNBadge.booking(BookingState.cancelled),
              SNBadge.payment(PaymentState.pending),
              SNBadge.payment(PaymentState.successful),
              SNBadge.payment(PaymentState.failed),
            ],
          ),

          // ── Chips ──────────────────────────────────────────
          _section('Filter Chips'),
          Row(
            children: [
              SNChip(
                label: 'Nearby',
                selected: _chipSelected,
                onTap: () => setState(() => _chipSelected = !_chipSelected),
              ),
              const SizedBox(width: SNSpace.x2),
              SNChip(
                label: 'Women Only',
                selected: !_chipSelected,
                onTap: () => setState(() => _chipSelected = !_chipSelected),
              ),
            ],
          ),

          // ── Avatars ────────────────────────────────────────
          _section('Avatars'),
          Row(
            children: [
              const SNAvatar(initials: 'EQ', size: SNSize.avatarMd),
              const SizedBox(width: SNSpace.x3),
              const SNAvatar(
                size: SNSize.avatarSm,
                showPresence: true,
                isOnline: true,
              ),
              const SizedBox(width: SNSpace.x3),
              const SNAvatar(
                initials: 'KA',
                size: SNSize.avatarSm,
                showPresence: true,
                isOnline: false,
              ),
            ],
          ),

          // ── Section Header ─────────────────────────────────
          _section('Section Header'),
          SNSectionHeader(
            title: 'Featured Hostels',
            onSeeAll: () {},
          ),

          // ── Price Tag ──────────────────────────────────────
          _section('Price Tags'),
          const PriceTag.startsFrom(amountPesewas: 320000),
          const SizedBox(height: SNSpace.x4),
          const PriceTag(amountPesewas: 550000, large: true),

          // ── Rating ─────────────────────────────────────────
          _section('Ratings'),
          const RatingStars(rating: 4.5, reviewCount: 128),
          const SizedBox(height: SNSpace.x2),
          const RatingStars(rating: 3.5, compact: false),

          // ── Verified Badge ─────────────────────────────────
          _section('Verified Badge'),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: SNRadius.card,
            ),
            child: const Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: VerifiedBadge(),
                ),
              ],
            ),
          ),

          // ── Amenity Chips ──────────────────────────────────
          _section('Amenity Chips'),
          const Wrap(
            spacing: SNSpace.x2,
            runSpacing: SNSpace.x2,
            children: [
              AmenityChip(label: 'Free WiFi', icon: Icons.wifi),
              AmenityChip(label: '24/7 Power', icon: Icons.bolt),
              AmenityChip(label: 'Security', icon: Icons.shield_outlined),
              AmenityChip(label: 'Laundry', icon: Icons.local_laundry_service),
            ],
          ),

          // ── Occupancy Bar ──────────────────────────────────
          _section('Occupancy Bar'),
          const OccupancyBar(occupied: 42, total: 50),
          const SizedBox(height: SNSpace.x4),
          const OccupancyBar(occupied: 8, total: 50),

          // ── Transaction Rows ───────────────────────────────
          _section('Transaction Rows'),
          const TransactionRow(label: 'Room fee', amountPesewas: 320000),
          const TransactionRow(label: 'Caution deposit', amountPesewas: 50000),
          const TransactionRow(
            label: 'Platform fee',
            amountPesewas: 15000,
            sublabel: 'Non-refundable',
          ),
          const TransactionRow.total(amountPesewas: 385000),

          // ── Countdown Pill ─────────────────────────────────
          _section('Countdown Pill'),
          CountdownPill(
            heldUntil: DateTime.now().toUtc().add(const Duration(minutes: 14, seconds: 32)),
            onExpired: () {},
          ),
          const SizedBox(height: SNSpace.x3),
          CountdownPill(
            heldUntil: DateTime.now().toUtc().add(const Duration(minutes: 1, seconds: 45)),
            onExpired: () {},
          ),

          // ── Bed Tiles ──────────────────────────────────────
          _section('Bed Tiles'),
          Row(
            children: [
              Expanded(
                child: BedTile(
                  label: 'Bed A',
                  state: BedState.available,
                  selected: _selectedBed == 0,
                  onTap: () => setState(() => _selectedBed = 0),
                ),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(
                child: BedTile(
                  label: 'Bed B',
                  state: BedState.occupied,
                ),
              ),
            ],
          ),
          const SizedBox(height: SNSpace.x3),
          Row(
            children: [
              Expanded(
                child: BedTile(
                  label: 'Bed C',
                  state: BedState.maintenance,
                  showFullState: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(
                child: BedTile(
                  label: 'Bed D',
                  state: BedState.held,
                  showFullState: true,
                  onTap: () {},
                ),
              ),
            ],
          ),

          // ── Hostel Cards ───────────────────────────────────
          _section('Hostel Card — Featured'),
          SizedBox(
            height: 320,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                HostelCard.featured(
                  name: 'Elite Residency',
                  location: 'Near North Campus',
                  imageUrl: null,
                  fromPricePesewas: 320000,
                  rating: 4.5,
                  reviewCount: 128,
                  verified: true,
                  saved: _saved,
                  onToggleSave: () => setState(() => _saved = !_saved),
                  onTap: () {},
                ),
                const SizedBox(width: SNSpace.cardGap),
                HostelCard.featured(
                  name: 'Campus View Lodge',
                  location: 'Near South Campus',
                  imageUrl: null,
                  fromPricePesewas: 250000,
                  rating: 4.2,
                  reviewCount: 84,
                  onTap: () {},
                ),
              ],
            ),
          ),

          _section('Hostel Card — List'),
          HostelCard.list(
            name: 'Elite Residency',
            location: 'Near North Campus',
            imageUrl: null,
            fromPricePesewas: 320000,
            rating: 4.5,
            reviewCount: 128,
            verified: true,
            amenities: const [
              AmenityChip(label: 'WiFi', icon: Icons.wifi),
              AmenityChip(label: 'Power', icon: Icons.bolt),
            ],
            onTap: () {},
          ),

          // ── Room Card ──────────────────────────────────────
          _section('Room Card'),
          RoomCard(
            title: '1-in-a-room',
            pricePesewas: 550000,
            slotsLeft: 2,
            tag: 'Premium Unit',
            onTap: () {},
          ),
          const SizedBox(height: SNSpace.x3),
          RoomCard(
            title: '2-in-a-room',
            pricePesewas: 320000,
            slotsLeft: 12,
            onTap: () {},
          ),

          // ── Skeletons ──────────────────────────────────────
          _section('Skeletons'),
          const SNSkeleton(width: 200, height: 16),
          const SizedBox(height: SNSpace.x2),
          const SNSkeleton(width: 140, height: 12),
          const SizedBox(height: SNSpace.x2),
          const SNSkeleton.listCard(),

          // ── Feedback States ────────────────────────────────
          _section('Empty State'),
          SizedBox(
            height: 340,
            child: SNEmptyState(
              headline: 'No saved hostels',
              body: 'Hostels you save will appear here.',
              icon: Icons.favorite_border_rounded,
              actionLabel: 'Explore hostels',
              onAction: () {},
            ),
          ),

          _section('Error State'),
          SizedBox(
            height: 300,
            child: SNErrorState(onRetry: () {}),
          ),

          _section('Offline Banner'),
          const SNOfflineBanner(),
          const SizedBox(height: SNSpace.x3),
          const SNOfflineBanner(showingCached: true),

          // ── Moment Screen ──────────────────────────────────
          _section('Moment — Success'),
          SizedBox(
            height: 380,
            child: SNMoment(
              icon: Icons.check_circle_outline_rounded,
              headline: 'Payment successful',
              body: 'Your bed is confirmed. We\'ve sent a receipt to your email.',
              tone: SNStatusTone.success,
              primaryAction: SNButton(label: 'View booking', onPressed: () {}),
              secondaryAction: SNButton.secondary(label: 'Download receipt', onPressed: () {}),
            ),
          ),

          _section('Moment — Waiting'),
          SizedBox(
            height: 340,
            child: SNMoment(
              icon: Icons.send_rounded,
              headline: 'We\'re confirming your payment',
              body: 'This can take up to 5 minutes with Mobile Money. You can close the app.',
              tone: SNStatusTone.warning,
              pulse: true,
            ),
          ),

          // ── Bottom Nav ─────────────────────────────────────
          _section('Student Nav'),
          SNBottomNav.student(
            currentIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
          ),
          const SizedBox(height: SNSpace.x4),
          _section('Owner Nav'),
          SNBottomNav.owner(
            currentIndex: 0,
            onTap: (_) {},
          ),

          // ── Money Formatting ───────────────────────────────
          _section('Money (D1: pesewas)'),
          _moneyRow('320000 pesewas, full', Money.format(320000)),
          _moneyRow('320000 pesewas, compact', Money.formatCompact(320000)),
          _moneyRow('320050 pesewas, full', Money.format(320050)),
          _moneyRow('320050 pesewas, compact', Money.formatCompact(320050)),
          _moneyRow('0 pesewas', Money.format(0)),

          const SizedBox(height: SNSpace.section),
        ],
      ),
      bottomNavigationBar: SNBottomNav.student(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: SNSpace.section, bottom: SNSpace.x4),
      child: SNSectionLabel(title),
    );
  }

  Widget _swatch(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(SNRadius.xs),
            border: Border.all(
              color: context.sn.border,
            ),
          ),
        ),
        const SizedBox(height: SNSpace.x1),
        Text(
          name,
          style: SNText.caption.copyWith(color: context.sn.mutedForeground),
        ),
      ],
    );
  }

  Widget _moneyRow(String input, String output) {
    final c = context.sn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SNSpace.x1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(input, style: SNText.caption.copyWith(color: c.mutedForeground)),
          Text(output, style: SNText.bodyBold.copyWith(color: c.foreground)),
        ],
      ),
    );
  }
}
