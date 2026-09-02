// features/booking/presentation/digital_agreement_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';

class DigitalAgreementScreen extends ConsumerStatefulWidget {
  const DigitalAgreementScreen({
    super.key,
    required this.bookingId,
    this.bookingReference = '',
    this.hostelName = '',
    this.roomLabel = '',
  });

  final String bookingId;
  final String bookingReference;
  final String hostelName;
  final String roomLabel;

  @override
  ConsumerState<DigitalAgreementScreen> createState() => _DigitalAgreementScreenState();
}

class _DigitalAgreementScreenState extends ConsumerState<DigitalAgreementScreen> {
  bool _agreedToRules = false;
  bool _loading = true;
  bool _signing = false;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // Agreement data
  String _contractId = '';
  String _studentName = '';
  String _hostelName = '';
  String _property = '';
  String _termStart = '';
  String _termEnd = '';
  String _houseRules = '';
  bool _alreadySigned = false;
  String _signedAt = '';

  bool get _hasSigned => _strokes.isNotEmpty;
  bool get _canSubmit => _hasSigned && _agreedToRules && !_signing && !_alreadySigned;

  @override
  void initState() {
    super.initState();
    _fetchAgreement();
  }

  Future<void> _fetchAgreement() async {
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final data = await repo.getAgreement(widget.bookingId);
      setState(() {
        _contractId = data['contractId'] ?? widget.bookingReference;
        _studentName = data['studentName'] ?? '';
        _hostelName = data['hostelName'] ?? widget.hostelName;
        _property = data['property'] ?? widget.roomLabel;
        _termStart = data['termStart'] ?? '';
        _termEnd = data['termEnd'] ?? '';
        _houseRules = data['houseRules'] ?? '';
        _alreadySigned = data['signedAt'] != null;
        _signedAt = data['signedAt']?.toString() ?? '';
        if (_alreadySigned) _agreedToRules = true;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _contractId = widget.bookingReference;
        _hostelName = widget.hostelName;
        _property = widget.roomLabel;
        _houseRules = 'I agree to the House Rules, including visitor curfew and noise policies as set by the hostel management.';
        _loading = false;
      });
    }
  }

  Future<void> _submitSignature() async {
    setState(() => _signing = true);
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      await repo.signAgreement(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agreement signed successfully!')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign agreement')),
        );
      }
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 16,
              left: SNSpace.screenX,
              right: SNSpace.screenX,
            ),
            decoration: BoxDecoration(
              color: c.card,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_back, color: c.foreground, size: 22),
                  ),
                ),
                const SizedBox(width: SNSpace.x4),
                Text('Lease Agreement', style: SNText.headingMd.copyWith(color: c.foreground)),
              ],
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SNSpace.screenX),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Title ──
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'STAYNEST DIGITAL LEASE',
                              style: SNText.headingMd.copyWith(
                                color: c.foreground, fontWeight: FontWeight.w900,
                                letterSpacing: 4, fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CONTRACT ID: $_contractId',
                              style: SNText.caption.copyWith(
                                color: c.mutedForeground, fontWeight: FontWeight.w900,
                                letterSpacing: 3, fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildClause(c, label: 'I. PARTIES:', body: [
                        const TextSpan(text: 'This Agreement is made between '),
                        TextSpan(text: _hostelName.isNotEmpty ? _hostelName : 'Hostel',
                            style: TextStyle(fontWeight: FontWeight.w700, color: c.foreground)),
                        const TextSpan(text: ' (Lessor) and '),
                        TextSpan(text: _studentName.isNotEmpty ? _studentName : 'Student',
                            style: TextStyle(fontWeight: FontWeight.w700, color: c.foreground)),
                        const TextSpan(text: ' (Lessee).'),
                      ]),
                      const SizedBox(height: 16),

                      _buildClause(c, label: 'II. PROPERTY:', body: [
                        TextSpan(text: _property.isNotEmpty ? '$_property.' : 'Property details pending.'),
                      ]),
                      const SizedBox(height: 16),

                      _buildClause(c, label: 'III. TERM:', body: [
                        TextSpan(
                          text: _termStart.isNotEmpty && _termEnd.isNotEmpty
                              ? 'The lease shall begin on $_termStart and end on $_termEnd.'
                              : 'Term dates pending.',
                        ),
                      ]),
                      const SizedBox(height: 32),

                      // ── Signature area ──
                      if (_alreadySigned) ...[
                        // Signed state
                        Container(
                          height: 128,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: c.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.success.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 36, color: c.success),
                              const SizedBox(height: 8),
                              Text(
                                'AGREEMENT SIGNED',
                                style: SNText.caption.copyWith(
                                  color: c.success, fontWeight: FontWeight.w900,
                                  letterSpacing: 3, fontSize: 10,
                                ),
                              ),
                              if (_signedAt.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _signedAt.length > 10 ? _signedAt.substring(0, 10) : _signedAt,
                                  style: SNText.caption.copyWith(color: c.mutedForeground, fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        // Signature pad
                        Stack(
                          children: [
                            GestureDetector(
                              onPanStart: (d) => setState(() {
                                _currentStroke = [d.localPosition];
                                _strokes.add(_currentStroke);
                              }),
                              onPanUpdate: (d) => setState(() => _currentStroke.add(d.localPosition)),
                              onPanEnd: (_) => _currentStroke = [],
                              child: Container(
                                height: 128,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: c.muted.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: c.border, width: 2),
                                ),
                                child: CustomPaint(
                                  painter: _SignaturePainter(strokes: _strokes, color: c.foreground),
                                  child: !_hasSigned
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.edit, size: 32, color: c.mutedForeground.withValues(alpha: 0.3)),
                                            const SizedBox(height: 8),
                                            Text(
                                              'SIGN HERE WITH FINGER',
                                              style: SNText.caption.copyWith(
                                                color: c.mutedForeground, fontWeight: FontWeight.w900,
                                                letterSpacing: 3, fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.expand(),
                                ),
                              ),
                            ),
                            if (_hasSigned)
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: _clearSignature,
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
                                    child: Icon(Icons.close, size: 16, color: c.mutedForeground),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),

                      // ── Checkbox ──
                      GestureDetector(
                        onTap: _alreadySigned ? null : () => setState(() => _agreedToRules = !_agreedToRules),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: _agreedToRules ? c.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _agreedToRules ? c.primary : c.border, width: 1.5),
                              ),
                              child: _agreedToRules ? Icon(Icons.check, size: 14, color: c.primaryForeground) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _houseRules.isNotEmpty ? _houseRules : 'I agree to the House Rules.',
                                style: SNText.caption.copyWith(color: c.foreground, fontWeight: FontWeight.w700, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom CTA ──
          if (!_alreadySigned)
            Container(
              padding: const EdgeInsets.all(SNSpace.screenX),
              decoration: BoxDecoration(
                color: c.card.withValues(alpha: 0.9),
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SafeArea(
                top: false,
                child: SNButton(
                  label: 'Sign & Complete Booking',
                  icon: Icons.verified,
                  isLoading: _signing,
                  onPressed: _canSubmit ? _submitSignature : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClause(SNColorTokens c, {required String label, required List<TextSpan> body}) {
    return RichText(
      text: TextSpan(
        style: SNText.body.copyWith(color: c.mutedForeground, fontSize: 12, height: 1.6),
        children: [
          TextSpan(text: '$label ', style: TextStyle(fontWeight: FontWeight.w900, color: c.foreground, letterSpacing: -0.5)),
          ...body,
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.0 ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) path.lineTo(stroke[i].dx, stroke[i].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
