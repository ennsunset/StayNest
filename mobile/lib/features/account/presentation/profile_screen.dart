// features/account/presentation/profile_screen.dart
//
// Screen 31 — Profile. Wired to auth user data.
// "Profile" header + settings gear, avatar, name from auth, stats, menu.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staynest_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/features/account/presentation/edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final user = ref.watch(authNotifierProvider);
    final name = user?.fullName ?? 'Student';
    final university = user?.university ?? 'University';
    final level = user?.level ?? '';

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: SNSpace.navClear),
          child: Column(
            children: [
              // ── Header: "Profile" + settings gear ──
              Padding(
                padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x5, SNSpace.screenX, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile', style: SNText.headingLg.copyWith(color: c.foreground)),
                    SNCircleButton(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: SNSpace.x6),

              // ── Profile card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                child: SNCard(
                  padding: const EdgeInsets.all(SNSpace.x5),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _pickAndUploadAvatar(context, ref),
                        child: Stack(
                          children: [
                            if (user?.avatarUrl != null)
                              CircleAvatar(radius: 40, backgroundImage: NetworkImage(user!.avatarUrl!))
                            else
                              SNAvatar(size: 80, initials: _initials(name)),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                                child: Icon(Icons.camera_alt, size: 16, color: c.primaryForeground),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: SNSpace.x4),
                      Text(name, style: SNText.headingLg.copyWith(color: c.foreground)),
                      const SizedBox(height: SNSpace.x3),
                      SNButton(label: 'Edit Profile', variant: SNButtonVariant.secondary, onPressed: () => context.push('/edit-profile')),
                      const SizedBox(height: SNSpace.x2),
                      Text(
                        '$university${level.isNotEmpty ? ' · $level' : ''}',
                        style: SNText.body.copyWith(color: c.mutedForeground),
                      ),

                      const SizedBox(height: SNSpace.x5),
                      Divider(color: c.border),
                      const SizedBox(height: SNSpace.x4),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat(c, '01', 'STAYS'),
                          Container(width: 1, height: 32, color: c.border),
                          _stat(c, '0', 'REVIEWS'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: SNSpace.x5),

              // ── Student ID Verified banner ──
              if (user?.idVerified == true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                  child: Container(
                    padding: const EdgeInsets.all(SNSpace.x4),
                    decoration: BoxDecoration(
                      color: c.success.withValues(alpha: 0.1),
                      borderRadius: SNRadius.card,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(SNSpace.x3),
                          decoration: BoxDecoration(
                            color: c.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(SNRadius.sm),
                          ),
                          child: Icon(Icons.verified_user_outlined, size: 20, color: c.success),
                        ),
                        const SizedBox(width: SNSpace.x4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Student ID Verified', style: SNText.bodyBold.copyWith(color: c.success)),
                              Text(
                                'You are eligible for student-only discounts',
                                style: SNText.caption.copyWith(color: c.success),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle_rounded, size: 20, color: c.success),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: SNSpace.section),

              // ── MESSAGES ──
              _menuItem(c, Icons.chat_bubble_outline_rounded, 'Messages', () => context.go('/messages')),

              const SizedBox(height: SNSpace.section),

              // ── ACCOMMODATION section ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOMMODATION',
                    style: SNText.sectionLabel.copyWith(color: c.mutedForeground),
                  ),
                ),
              ),
              const SizedBox(height: SNSpace.x3),

              _menuItem(c, Icons.qr_code_2_rounded, 'Access Pass', () async {
                final bookings = await ref.read(myBookingsProvider.future);
                final active = bookings.where((b) => b.status == 'CONFIRMED' || b.status == 'CHECKED_IN').toList();
                if (active.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active booking found')));
                  }
                  return;
                }
                final b = active.first;
                final hostel = b.bed?.room?.hostelName ?? '';
                final room = b.bed?.room != null ? 'Room ${b.bed!.room!.number} - ${b.bed!.label}' : b.bed?.label ?? '';
                if (context.mounted) {
                  context.push(Routes.qrCheckin, extra: {
                    'bookingReference': b.reference,
                    'hostelName': hostel,
                    'roomId': room,
                    'validUntil': 'June 2027',
                  });
                }
              }),
              _menuItem(c, Icons.description_outlined, 'Digital Contracts', () {}),
              _menuItem(c, Icons.receipt_long_outlined, 'Payment History', () => context.push(Routes.paymentHistory)),
              _menuItem(c, Icons.favorite_border_rounded, 'Saved Hostels', () {}),
              _menuItem(c, Icons.history_rounded, 'Search History', () => context.push(Routes.searchHistory)),
              _menuItem(c, Icons.visibility_outlined, 'Recently Viewed', () => context.push(Routes.recentlyViewed)),
              _menuItem(c, Icons.electric_bolt_outlined, 'Utility Bills', () => context.push(Routes.utilityBills)),

              const SizedBox(height: SNSpace.section),

              // ── Log out ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                child: GestureDetector(
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go(Routes.login);
                  },
                  child: Text('Log Out', style: SNText.bodyBold.copyWith(color: c.destructive)),
                ),
              ),

              const SizedBox(height: SNSpace.section),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.uploadAvatar(File(picked.path));
      ref.invalidate(authNotifierProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  Widget _stat(SNColorTokens c, String value, String label) {
    return Column(
      children: [
        Text(value, style: SNText.headingLg.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x1),
        Text(label, style: SNText.sectionLabel.copyWith(color: c.mutedForeground, fontSize: 10)),
      ],
    );
  }

  Widget _menuItem(SNColorTokens c, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SNSpace.x4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(SNSpace.x3),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(SNRadius.sm),
                    ),
                    child: Icon(icon, size: 20, color: c.primary),
                  ),
                  const SizedBox(width: SNSpace.x4),
                  Expanded(child: Text(label, style: SNText.body.copyWith(color: c.foreground))),
                  Icon(Icons.chevron_right_rounded, size: 20, color: c.mutedForeground),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: c.border),
        ],
      ),
    );
  }
}
