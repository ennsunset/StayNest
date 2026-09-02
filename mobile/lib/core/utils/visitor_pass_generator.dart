import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class VisitorPassGenerator {
  static Future<Uint8List> generate({
    required String visitorName,
    required String hostelName,
    required String qrToken,
    required String validUntil,
    String purpose = '',
    String visitorPhone = '',
    String studentName = '',
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#4F46E5');
    final amberColor = PdfColor.fromHex('#E8A33D');
    final mutedColor = PdfColor.fromHex('#64748B');
    final borderColor = PdfColor.fromHex('#E2E8F0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 2),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Text('StayNest',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF7ED'),
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: amberColor),
                  ),
                  child: pw.Text('VISITOR PASS', style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold, color: amberColor, letterSpacing: 3)),
                ),
                pw.SizedBox(height: 20),

                // Hostel name
                pw.Text(hostelName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 24),

                // QR Code
                pw.BarcodeWidget(
                  data: qrToken,
                  barcode: pw.Barcode.qrCode(),
                  width: 160,
                  height: 160,
                ),
                pw.SizedBox(height: 12),
                pw.Text(qrToken, style: pw.TextStyle(fontSize: 8, color: mutedColor, letterSpacing: 1)),
                pw.SizedBox(height: 24),

                // Divider
                pw.Container(height: 1, color: borderColor),
                pw.SizedBox(height: 16),

                // Details
                _row('Visitor', visitorName),
                if (visitorPhone.isNotEmpty) _row('Phone', visitorPhone),
                if (purpose.isNotEmpty) _row('Purpose', purpose),
                _row('Valid Until', _formatDateTime(validUntil)),
                if (studentName.isNotEmpty) _row('Hosted By', studentName),

                pw.SizedBox(height: 20),

                // Warning banner
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF7ED'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: amberColor),
                  ),
                  child: pw.Text(
                    'Visitor must present a valid ID at the security gate.',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: amberColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                pw.SizedBox(height: 16),
                pw.Text('Present this pass at the security gate for entry.',
                    style: pw.TextStyle(fontSize: 9, color: mutedColor), textAlign: pw.TextAlign.center),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: pw.TextStyle(
              fontSize: 10, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(String iso) {
    if (iso.isEmpty) return '---';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${m[d.month - 1]} ${d.day}, ${d.year} at $hour:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}
