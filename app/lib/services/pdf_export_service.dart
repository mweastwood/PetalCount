import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/cycle.dart';
import '../models/daily_entry.dart';

class PdfExportService {
  static Future<void> exportCyclesToPdf(List<Cycle> cycles) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Creighton Model FertilityCare Chart',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink900,
                  ),
                ),
                pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Loop through each cycle and draw a row
            for (var cycle in cycles) ...[
              _buildCycleRow(cycle, dateFormat),
              pw.SizedBox(height: 24),
            ],

            // Legend / Key
            pw.SizedBox(height: 16),
            _buildLegend(),
          ];
        },
      ),
    );

    // Save and Share the file
    try {
      final bytes = await pdf.save();

      final String filename =
          'Creighton_Chart_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        // Sharing on Web is handled differently, but we can write to a file or share it.
        // For standard Flutter execution, let's save to documents and share.
        debugPrint('Web PDF generation completed');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'My Creighton Model Fertility Chart',
        ),
      );
    } catch (e) {
      debugPrint('Error generating or sharing PDF: $e');
    }
  }

  static pw.Widget _buildCycleRow(Cycle cycle, DateFormat dateFormat) {
    final entries = cycle.sortedEntries;

    // We break the cycle into rows of 35 days (like a standard Creighton paper chart page)
    const int daysPerRow = 35;
    final int totalDays = entries.length;

    // Ensure we display at least 35 days, or pad the cycle
    final int displayDays = totalDays < daysPerRow ? daysPerRow : totalDays;

    final columns = <pw.Widget>[];

    // Collect comments to print at the bottom of the cycle row
    final commentsList = <Map<String, String>>[];

    for (int i = 0; i < displayDays; i++) {
      DailyEntry? entry;
      if (i < totalDays) {
        entry = entries[i];
      }

      final dayNum = i + 1;

      // Determine Stamp Color & Baby Symbol
      PdfColor cellColor = PdfColors.white;
      bool drawBaby = false;
      bool drawGreenBaby = false;

      if (entry != null) {
        switch (entry.stampType) {
          case StampType.red:
            cellColor = PdfColors.red;
            break;
          case StampType.green:
            cellColor = PdfColors.green;
            break;
          case StampType.whiteBaby:
            cellColor = PdfColors.white;
            drawBaby = true;
            break;
          case StampType.greenBaby:
            cellColor = PdfColors.green;
            drawGreenBaby = true;
            break;
          case StampType.yellow:
            cellColor = PdfColors.yellow;
            break;
          case StampType.yellowBaby:
            cellColor = PdfColors.yellow;
            drawBaby = true;
            break;
        }

        // Add comments if they exist
        if (entry.comments.trim().isNotEmpty) {
          commentsList.add({
            'day': dayNum.toString(),
            'comment': entry.comments,
          });
        }
      }

      // Check for pain
      final hasPain = entry != null && entry.painLevel > 0;
      final String painSymbol = hasPain
          ? (entry.painTypes.contains('Cramps')
                ? 'C'
                : (entry.painTypes.contains('Ovulation') ? 'O' : 'P'))
          : '';

      columns.add(
        pw.Container(
          width: 20,
          child: pw.Column(
            children: [
              // 1. Peak Day label above stamp
              pw.Container(
                height: 12,
                child: pw.Text(
                  entry?.peakDayLabel ?? '',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: entry?.peakDayLabel == 'P'
                        ? PdfColors.red900
                        : PdfColors.black,
                  ),
                ),
              ),

              // 2. The Stamp itself
              pw.Container(
                width: 18,
                height: 22,
                decoration: pw.BoxDecoration(
                  color: cellColor,
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Center(
                  child: drawBaby
                      ? _buildBabySymbol(PdfColors.black)
                      : (drawGreenBaby
                            ? _buildBabySymbol(PdfColors.white)
                            : pw.SizedBox()),
                ),
              ),

              pw.SizedBox(height: 2),

              // 3. Cycle Day number
              pw.Text(
                '$dayNum',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),

              // 4. Date
              pw.Text(
                entry != null ? dateFormat.format(entry.date) : '',
                style: const pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.grey500,
                ),
              ),

              // 5. Resolved VDRS Code
              pw.Container(
                height: 20,
                alignment: pw.Alignment.topCenter,
                child: pw.Text(
                  entry != null ? entry.resolvedVdrsCode : '',
                  style: const pw.TextStyle(
                    fontSize: 5,
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              // 6. Pain symbol / Asterisk for comments
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (painSymbol.isNotEmpty)
                    pw.Text(
                      painSymbol,
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.red700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (entry != null && entry.comments.isNotEmpty) ...[
                    pw.SizedBox(width: 1),
                    pw.Text(
                      '*',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.blue700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Cycle Metadata Header
        pw.Text(
          'Cycle Starting: ${DateFormat('yyyy-MM-dd').format(cycle.startDate)}  |  BIP: ${cycle.bipCodes.isEmpty ? 'None' : cycle.bipCodes.join(', ')}',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 6),

        // Grid row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: columns,
        ),

        // Comments list below the row
        if (commentsList.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Daily Notes:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: commentsList.map((c) {
                    return pw.Text(
                      '* Day ${c['day']}: ${c['comment']}',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey700,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Draw a simple vector stick baby outline to represent the baby symbol
  static pw.Widget _buildBabySymbol(PdfColor color) {
    return pw.CustomPaint(
      size: const PdfPoint(8, 12),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas
          ..setColor(color)
          ..setLineWidth(0.7)
          // Head (Circle)
          ..drawEllipse(4, 9, 2.2, 2.2)
          ..strokePath()
          // Body (Line/Oval)
          ..moveTo(4, 6.8)
          ..lineTo(4, 2.5)
          ..strokePath()
          // Arms
          ..moveTo(1.5, 5.0)
          ..lineTo(6.5, 5.0)
          ..strokePath()
          // Legs
          ..moveTo(4, 2.5)
          ..lineTo(2.0, 0.5)
          ..moveTo(4, 2.5)
          ..lineTo(6.0, 0.5)
          ..strokePath();
      },
    );
  }

  static pw.Widget _buildLegend() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Chart Legend & Key:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              _buildLegendItem(
                PdfColors.red,
                'Bleeding Day (Menstruation/Spotting)',
                hasBaby: false,
              ),
              pw.SizedBox(width: 12),
              _buildLegendItem(
                PdfColors.green,
                'Dry Day (Infertile)',
                hasBaby: false,
              ),
              pw.SizedBox(width: 12),
              _buildLegendItem(
                PdfColors.white,
                'Mucus Day (Potentially Fertile)',
                hasBaby: true,
              ),
              pw.SizedBox(width: 12),
              _buildLegendItem(
                PdfColors.green,
                'Post-Peak Dry Day (Fertile window)',
                hasBaby: true,
                babyColor: PdfColors.white,
              ),
              pw.SizedBox(width: 12),
              _buildLegendItem(
                PdfColors.yellow,
                'Continuous BIP Mucus (Infertile)',
                hasBaby: false,
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'VDRS Symbols: K = Clear | C = Cloudy | Y = Yellow | W = White | L = Lubricative | G = Gummy | P = Pasty | 0/2/4 = Dry/Damp/Shiny Sensation. Pain Indicators: C = Cramps | O = Ovulation Pain | P = Other Pain.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLegendItem(
    PdfColor color,
    String description, {
    required bool hasBaby,
    PdfColor babyColor = PdfColors.black,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: 10,
          height: 12,
          decoration: pw.BoxDecoration(
            color: color,
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Center(
            child: hasBaby ? _buildBabySymbol(babyColor) : pw.SizedBox(),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(description, style: const pw.TextStyle(fontSize: 7)),
      ],
    );
  }
}
