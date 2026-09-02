// features/booking/presentation/qr_checkin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';

class QrCheckinScreen extends ConsumerWidget {
  const QrCheckinScreen({
    super.key,
    required this.bookingReference,
    this.hostelName = '',
    this.roomId = '',
    this.validUntil = '',
  });

  final String bookingReference;
  final String hostelName;
  final String roomId;
  final String validUntil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final user = ref.watch(authNotifierProvider);
    final studentName = user?.fullName ?? 'Student';
    
    return Scaffold(
      backgroundColor: c.primary,
      body: Stack(
        children: [
          // ── Decorative circles ──
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),

          // ── Close button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: SNSpace.screenX,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),

          // ── Main content ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── White card ──
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(48),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 64,
                          offset: const Offset(0, 32),
                          spreadRadius: -16,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Gradient bar
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [c.primary, c.primaryForeground],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                          child: Column(
                            children: [
                              // ── Hostel name ──
                              Text(
                                hostelName.isNotEmpty ? hostelName : 'StayNest',
                                style: SNText.headingMd.copyWith(
                                  color: const Color(0xFF1C2B41),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'OFFICIAL ACCESS PASS',
                                style: SNText.caption.copyWith(
                                  color: c.mutedForeground,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── QR code area ──
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: c.muted.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(color: c.border),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: QrImageView(
                                    data: 'staynest://checkin/$bookingReference',
                                    version: QrVersions.auto,
                                    size: 180,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF1C2B41),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Color(0xFF1C2B41),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Room ID + Valid Until ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ROOM ID',
                                        style: SNText.caption.copyWith(
                                          color: c.mutedForeground,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3,
                                          fontSize: 8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        roomId.isNotEmpty ? roomId : '---',
                                        style: SNText.bodyBold.copyWith(
                                          color: const Color(0xFF1C2B41),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'VALID UNTIL',
                                        style: SNText.caption.copyWith(
                                          color: c.mutedForeground,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3,
                                          fontSize: 8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        validUntil.isNotEmpty ? validUntil : '---',
                                        style: SNText.bodyBold.copyWith(
                                          color: const Color(0xFF1C2B41),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ── Dashed divider ──
                              Container(height: 1, color: c.border),
                              const SizedBox(height: 16),

                              // ── Student info ──
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: c.muted,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                        ? Image.network(user.avatarUrl!, fit: BoxFit.cover)
                                        : Icon(Icons.person, color: c.mutedForeground, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName.toUpperCase(),
                                        style: SNText.bodyBold.copyWith(
                                          color: const Color(0xFF1C2B41),
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'VERIFIED RESIDENT',
                                        style: SNText.caption.copyWith(
                                          color: const Color(0xFF16A34A),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 3,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Bottom text ──
                  SizedBox(
                    width: 200,
                    child: Text(
                      'PRESENT THIS CODE AT THE SECURITY GATE FOR INSTANT CHECK-IN',
                      style: SNText.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        fontSize: 10,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
