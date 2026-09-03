import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';

class AIInsightsScreen extends StatelessWidget {
  const AIInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 80, pinned: true,
          backgroundColor: const Color(0xFF1C2B41),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          title: Text('AI Property Insights', style: SNText.headingMd.copyWith(color: Colors.white)),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.primary.withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.psychology_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text('SMART PRICING ALERT', style: SNText.headingMd.copyWith(color: Colors.white, letterSpacing: 1)),
                ]),
                const SizedBox(height: 16),
                Text('Based on search trends near KNUST, we recommend increasing your 2-in-a-room prices by 8% for the next semester.', style: SNText.body.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI pricing coming soon'))),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text('APPLY RECOMMENDATION', style: SNText.bodyBold.copyWith(color: c.primary, fontSize: 12, letterSpacing: 1.5))),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            Text('90-DAY OCCUPANCY FORECAST', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SNCard(child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PREDICTED PEAK', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('Aug 24 \u2013 Sept 12', style: SNText.headingMd.copyWith(color: c.foreground)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('CONFIDENCE', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('94%', style: SNText.headingMd.copyWith(color: c.primary)),
                ]),
              ]),
              const SizedBox(height: 20),
              SizedBox(height: 100, width: double.infinity, child: CustomPaint(painter: _ForecastPainter(c.primary))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['JUNE', 'JULY', 'AUG', 'SEPT'].map((m) => Text(m, style: SNText.microAction.copyWith(color: m == 'AUG' ? c.primary : c.mutedForeground, fontWeight: m == 'AUG' ? FontWeight.w800 : FontWeight.w600))).toList()),
            ])),
            const SizedBox(height: 28),
            Text('HIGH DEMAND AMENITIES', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: SNCard(child: Column(children: [Icon(Icons.wifi, color: c.primary, size: 28), const SizedBox(height: 8), Text('Fast WiFi', style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13)), const SizedBox(height: 4), Text('89% demand', style: SNText.caption.copyWith(color: c.primary, fontWeight: FontWeight.w600))]))),
              const SizedBox(width: 12),
              Expanded(child: SNCard(child: Column(children: [Icon(Icons.bolt, color: c.primary, size: 28), const SizedBox(height: 8), Text('Backup Power', style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13)), const SizedBox(height: 4), Text('76% demand', style: SNText.caption.copyWith(color: c.primary, fontWeight: FontWeight.w600))]))),
            ]),
          ]),
        )),
      ]),
    );
  }
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, size.height * 0.8)..cubicTo(size.width * 0.2, size.height * 0.75, size.width * 0.4, size.height * 0.6, size.width * 0.55, size.height * 0.4)..cubicTo(size.width * 0.65, size.height * 0.25, size.width * 0.75, size.height * 0.15, size.width * 0.8, size.height * 0.1)..cubicTo(size.width * 0.85, size.height * 0.05, size.width * 0.9, size.height * 0.15, size.width, size.height * 0.2);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 5, Paint()..color = color);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 3, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
