import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

class VisitorPassScreen extends StatelessWidget {
  const VisitorPassScreen({
    super.key,
    required this.visitorName,
    required this.hostelName,
    required this.qrToken,
    required this.validUntil,
    this.purpose = '',
    this.visitorPhone = '',
  });

  final String visitorName;
  final String hostelName;
  final String qrToken;
  final String validUntil;
  final String purpose;
  final String visitorPhone;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.primary,
      body: Stack(
        children: [
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 256, height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          Positioned(
            bottom: -80, right: -80,
            child: Container(
              width: 256, height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: SNSpace.screenX,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [c.primary, const Color(0xFFE8A33D)]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                          child: Column(
                            children: [
                              Text(
                                hostelName,
                                style: SNText.headingMd.copyWith(
                                  color: const Color(0xFF1C2B41),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'VISITOR PASS',
                                style: SNText.caption.copyWith(
                                  color: const Color(0xFFE8A33D),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 24),
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
                                    data: qrToken,
                                    version: QrVersions.auto,
                                    size: 180,
                                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1C2B41)),
                                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1C2B41)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('VISITOR', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 8)),
                                      const SizedBox(height: 4),
                                      Text(visitorName, style: SNText.bodyBold.copyWith(color: const Color(0xFF1C2B41), fontWeight: FontWeight.w900, fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('VALID UNTIL', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 8)),
                                      const SizedBox(height: 4),
                                      Text(_formatDateTime(validUntil), style: SNText.bodyBold.copyWith(color: const Color(0xFF1C2B41), fontWeight: FontWeight.w900, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              if (purpose.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(height: 1, color: c.border),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: c.mutedForeground),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(purpose, style: SNText.caption.copyWith(color: c.mutedForeground))),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              Container(height: 1, color: c.border),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8A33D).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE8A33D).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.badge_outlined, size: 16, color: Color(0xFFE8A33D)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Must present valid ID', style: SNText.caption.copyWith(color: const Color(0xFFE8A33D), fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: Text(
                      'PRESENT THIS PASS AT THE SECURITY GATE',
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

  String _formatDateTime(String iso) {
    if (iso.isEmpty) return '---';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}\n$hour:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}
