import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/disease_info.dart';
import '../models/prediction.dart';

class ReportService {
  Future<void> shareScanReport({
    required String imagePath,
    required Prediction prediction,
    required DiseaseInfo diseaseInfo,
  }) async {
    final document = pw.Document();
    final imageFile = File(imagePath);
    final imageBytes = imageFile.existsSync()
        ? await imageFile.readAsBytes()
        : null;

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) {
          return [
            pw.Text(
              'Scan Report',
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Multi Crop Disease Detector'),
            pw.SizedBox(height: 20),
            if (imageBytes != null)
              pw.Container(
                height: 180,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            pw.SizedBox(height: 20),
            _labelValue('Disease', diseaseInfo.displayName),
            _labelValue('Crop', diseaseInfo.crop),
            _labelValue('Confidence', prediction.confidencePercent),
            _labelValue('Severity', diseaseInfo.severity),
            _section('Description', [diseaseInfo.description]),
            _section('Symptoms', diseaseInfo.symptoms),
            _section('Recommendations', diseaseInfo.recommendations),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey200,
              child: pw.Text(
                'Disclaimer: This application provides AI-assisted disease '
                'detection and should not replace professional agricultural '
                'consultation.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'scan_report.pdf',
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(value, style: const pw.TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  pw.Widget _section(String title, List<String> items) {
    if (items.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          for (final item in items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text('- $item'),
            ),
        ],
      ),
    );
  }
}
