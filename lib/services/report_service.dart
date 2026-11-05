import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/disease_info.dart';
import '../models/prediction.dart';
import 'app_localizations.dart';
import 'language_service.dart';

class ReportService {
  static const String _bengaliFontAsset =
      'assets/fonts/NotoSansBengali-Regular.ttf';
  static const String _arabicFontAsset =
      'assets/fonts/NotoSansArabic-Regular.ttf';

  pw.Font? _bengaliFont;
  pw.Font? _arabicFont;

  Future<void> shareScanReport({
    required Uint8List imageBytes,
    required Prediction prediction,
    required DiseaseInfo diseaseInfo,
    AppLanguage language = AppLanguage.english,
  }) async {
    final document = pw.Document(theme: await _documentTheme());
    final strings = AppLocalizations(language);

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) {
          return [
            pw.Text(
              strings.text('report_title'),
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(strings.text('app_title')),
            pw.SizedBox(height: 20),
            if (imageBytes.isNotEmpty)
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
            _labelValue(strings, 'disease', diseaseInfo.displayName),
            _labelValue(strings, 'crop', diseaseInfo.crop),
            _labelValue(strings, 'confidence', prediction.confidencePercent),
            _labelValue(
              strings,
              'severity_label_value',
              diseaseInfo.severity,
            ),
            _section(strings, 'description', [diseaseInfo.description]),
            _section(strings, 'symptoms', diseaseInfo.symptoms),
            _section(strings, 'cultural_control', diseaseInfo.culturalControl),
            _section(strings, 'chemical_control', diseaseInfo.chemicalControl),
            _section(
              strings,
              'biological_control',
              diseaseInfo.biologicalControl,
            ),
            _section(strings, 'prevention_tips', diseaseInfo.preventionTips),
            _section(
              strings,
              'favorable_conditions',
              diseaseInfo.favorableConditions,
            ),
            if (diseaseInfo.spread.isNotEmpty)
              _section(strings, 'spread', [diseaseInfo.spread]),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey200,
              child: pw.Text(
                strings.text('disclaimer'),
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

  Future<pw.ThemeData> _documentTheme() async {
    // Default Helvetica cannot encode Bengali or Arabic script; load the
    // bundled Noto fonts as fallbacks so bn/ur report values stay readable.
    try {
      _bengaliFont ??= pw.Font.ttf(
        await rootBundle.load(_bengaliFontAsset),
      );
      _arabicFont ??= pw.Font.ttf(
        await rootBundle.load(_arabicFontAsset),
      );
    } catch (error) {
      assert(() {
        debugPrint('Report font fallback unavailable: $error');
        return true;
      }());
    }

    final fallback = [
      ?_bengaliFont,
      ?_arabicFont,
    ];

    return pw.ThemeData.withFont(
      fontFallback: fallback,
      bold: pw.Font.helveticaBold(),
    );
  }

  pw.Widget _labelValue(AppLocalizations strings, String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            strings.text(key),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(value, style: const pw.TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  pw.Widget _section(
    AppLocalizations strings,
    String key,
    List<String> items,
  ) {
    if (items.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            strings.text(key),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
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
