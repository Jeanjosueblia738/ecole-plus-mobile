import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../features/finance/data/finance_model.dart';

class ReceiptPdfService {
  static Future<Uint8List> generate(Payment payment) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(payment.date);
    final isSuccess = payment.status == PaymentStatus.valide;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ECOLE+',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                    pw.Text('Plateforme Éducative',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: isSuccess ? PdfColors.green100 : PdfColors.red100,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    payment.status.label.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: isSuccess ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 4),

            pw.Center(
              child: pw.Text('REÇU DE PAIEMENT',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text('N° ${payment.receiptNumber}',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey600)),
            ),

            pw.SizedBox(height: 14),

            // ── Infos élève ───────────────────────────────────────
            _section('INFORMATIONS ÉLÈVE'),
            _row('Nom', payment.studentName),
            _row('Classe', payment.className),

            pw.SizedBox(height: 10),

            // ── Détail paiement ───────────────────────────────────
            _section('DÉTAIL DU PAIEMENT'),
            _row('Libellé', payment.feeLabel),
            _row('Méthode', payment.method.label),
            _row('Date', dateStr),
            if (payment.operatorName != null)
              _row('Opérateur', payment.operatorName!),
            if (payment.phoneNumber != null)
              _row('N° Mobile', payment.phoneNumber!),
            if (payment.transactionId != null)
              _row('Réf. transaction', payment.transactionId!),
            if (payment.chequeNumber != null)
              _row('N° chèque', payment.chequeNumber!),

            pw.SizedBox(height: 14),

            // ── Montant ───────────────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: isSuccess ? PdfColors.green50 : PdfColors.red50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(
                  color: isSuccess ? PdfColors.green300 : PdfColors.red300,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MONTANT PAYÉ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    payment.montantFormate,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: isSuccess ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              'Document officiel ECOLE+ — Conservez ce reçu',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _section(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800)),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ),
          pw.Text(': ',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
