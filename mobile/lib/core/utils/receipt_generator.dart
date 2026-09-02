// core/utils/receipt_generator.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:staynest_mobile/features/payment/data/payments_repository.dart';

class ReceiptGenerator {
  /// Original method used by booking detail & confirmation screens
  static Future<Uint8List> generate({
    required String reference,
    required String hostelName,
    required String roomInfo,
    required int pricePesewas,
    required int platformFeePesewas,
    required int totalPesewas,
    required String status,
    required DateTime createdAt,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('MMMM d, yyyy').format(createdAt);
    final price = _money(pricePesewas);
    final fee = _money(platformFeePesewas);
    final total = _money(totalPesewas);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('StayNest', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green200),
                  ),
                  child: pw.Text(status.toUpperCase(),
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Payment Receipt', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 32),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Column(children: [
                pw.Text('Total Paid', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
                pw.Text(total, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
            pw.SizedBox(height: 32),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 24),
            _row('Date', dateStr),
            _row('Reference', reference),
            _row('Hostel', hostelName),
            _row('Room', roomInfo),
            _row('Rent', price),
            _row('Platform Fee', fee),
            _row('Total', total),
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text('This is a computer-generated receipt and does not require a signature.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  /// New method used by payment history screen
  static Future<Uint8List> generateFromHistory(PaymentHistoryItem payment) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('MMMM d, yyyy \u2022 hh:mm a').format(payment.createdAt);
    final amount = _money(payment.amountPesewas);

    String channelLabel;
    switch (payment.channel) {
      case 'MOBILE_MONEY': channelLabel = 'Mobile Money'; break;
      case 'CARD': channelLabel = 'Card Payment'; break;
      case 'BANK': channelLabel = 'Bank Transfer'; break;
      default: channelLabel = 'Payment';
    }

    final typeLabel = payment.paymentType == 'INSTALLMENT' ? 'Installment Payment' : 'Booking Payment';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('StayNest', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Payment Receipt', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ]),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green200),
                  ),
                  child: pw.Text('PAID',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Column(children: [
                pw.Text('Amount Paid', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
                pw.Text(amount, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
            pw.SizedBox(height: 32),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 24),
            _row('Date', dateStr),
            _row('Type', typeLabel),
            _row('Hostel', payment.hostelName),
            _row('Payment Method', channelLabel),
            _row('Reference', payment.reference),
            _row('Booking ID', payment.bookingId.substring(0, 8).toUpperCase()),
            _row('Status', 'Successful'),
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text('This is a computer-generated receipt and does not require a signature.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text('StayNest \u2022 Campus Hostel Booking Platform',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static String _money(int pesewas) {
    final cedis = pesewas / 100;
    return 'GHC ${cedis.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }
}
