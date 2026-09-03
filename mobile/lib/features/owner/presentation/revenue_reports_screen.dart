import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';

class RevenueReportsScreen extends StatelessWidget {
  const RevenueReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Revenue Reports',
        onBack: () => context.pop(),
        trailing: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export coming soon'))),
          child: Icon(Icons.download_outlined, color: c.foreground, size: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SNCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.primary.withValues(alpha: 0.05), c.primary.withValues(alpha: 0.15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: CustomPaint(painter: _ChartPainter(c.primary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Annual Revenue Growth', style: SNText.headingMd.copyWith(color: c.foreground)),
                        const SizedBox(height: 4),
                        Text('Showing total collections across all properties for 2025 vs 2026 academic cycle.', style: SNText.caption.copyWith(color: c.mutedForeground)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('2026 (+18%)', style: SNText.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 20),
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: c.mutedForeground, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('2025', style: SNText.caption.copyWith(color: c.mutedForeground)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('BREAKDOWN BY PROPERTY', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _PropertyRow(c: c, name: 'Anglican Hostel', units: 11, revenue: 'GH\u20B5 27.5k', collection: '94%'),
            const SizedBox(height: 12),
            _PropertyRow(c: c, name: 'Prestige Hall', units: 8, revenue: 'GH\u20B5 20.0k', collection: '82%'),
          ],
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.c, required this.name, required this.units, required this.revenue, required this.collection});
  final SNColorTokens c;
  final String name;
  final int units;
  final String revenue;
  final String collection;

  @override
  Widget build(BuildContext context) {
    return SNCard(
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: SNText.bodyBold.copyWith(color: c.foreground)),
          const SizedBox(height: 2),
          Text('${units} UNITS', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(revenue, style: SNText.bodyBold.copyWith(color: c.foreground)),
          const SizedBox(height: 2),
          Text('${collection} Collection', style: SNText.caption.copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.4)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, size.height * 0.7)..cubicTo(size.width * 0.2, size.height * 0.6, size.width * 0.4, size.height * 0.5, size.width * 0.5, size.height * 0.45)..cubicTo(size.width * 0.6, size.height * 0.4, size.width * 0.8, size.height * 0.25, size.width, size.height * 0.2);
    canvas.drawPath(path, paint);
    final paintOld = Paint()..color = color.withValues(alpha: 0.15)..strokeWidth = 2..style = PaintingStyle.stroke;
    final pathOld = Path()..moveTo(0, size.height * 0.8)..cubicTo(size.width * 0.25, size.height * 0.75, size.width * 0.5, size.height * 0.65, size.width * 0.75, size.height * 0.55)..lineTo(size.width, size.height * 0.45);
    canvas.drawPath(pathOld, paintOld);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
