import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/cycle.dart';
import '../models/daily_entry.dart';
import '../utils/date_utils.dart';
import 'web_download_helper.dart';

class PdfExportService {
  static Future<Uint8List> generatePdfBytes(
    List<Cycle> cycles, {
    DateTime? generatedAt,
  }) async {
    final pdf = pw.Document();
    final effectiveGeneratedAt = generatedAt ?? DateTime.now();

    if (cycles.isEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [_buildTitleHeader(effectiveGeneratedAt)];
          },
        ),
      );
    } else {
      for (final cycle in cycles) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter.landscape,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                _buildTitleHeader(effectiveGeneratedAt),
                pw.SizedBox(height: 16),
                _buildCycleRow(cycle),
              ];
            },
          ),
        );
      }
    }

    return pdf.save();
  }

  static pw.Widget _buildTitleHeader(DateTime generatedAt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Creighton Model Chart',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.pink900,
          ),
        ),
        pw.Text(
          'Generated on: ${generatedAt.dateKey}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static Future<void> exportCyclesToPdf(
    List<Cycle> cycles, {
    DateTime? generatedAt,
  }) async {
    final bytes = await generatePdfBytes(cycles, generatedAt: generatedAt);

    // Save and Share the file
    try {
      final String filename =
          'Creighton_Chart_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        downloadFileWeb(bytes, filename);
        debugPrint('Web PDF generation and download completed');
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

  static pw.Widget _buildCycleRow(Cycle cycle) {
    const int daysPerRow = 14;
    final int cycleMaxDay = cycle.maxDayNumber;
    const int minDisplayDays = 14;
    final int totalDays = cycleMaxDay < minDisplayDays
        ? minDisplayDays
        : cycleMaxDay;
    final int displayDays =
        ((totalDays + daysPerRow - 1) ~/ daysPerRow) * daysPerRow;

    final chunkRows = <pw.Widget>[];

    for (
      int startIndex = 0;
      startIndex < displayDays;
      startIndex += daysPerRow
    ) {
      final int endIndex = (startIndex + daysPerRow < displayDays)
          ? startIndex + daysPerRow
          : displayDays;

      final rowColumns = <pw.Widget>[];
      for (int i = startIndex; i < endIndex; i++) {
        rowColumns.add(_buildDayColumn(cycle, i));
      }

      if (chunkRows.isNotEmpty) {
        chunkRows.add(pw.SizedBox(height: 12));
      }

      chunkRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: rowColumns,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Cycle Metadata Header
        pw.Text(
          'Cycle Starting: ${cycle.startDate.dateKey}',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),

        // Grid rows
        ...chunkRows,
      ],
    );
  }

  static pw.Widget _buildDayColumn(Cycle cycle, int dayIndex) {
    final dayDate = cycle.startDate.addCalendarDays(dayIndex);
    final dateKey = dayDate.dateKey;
    final entry = cycle.dailyEntries[dateKey];
    final dayNum = dayIndex + 1;

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
    }

    // Pain description in English
    final String painDescription = (entry != null && entry.painLevel > 0)
        ? (entry.painTypes.isNotEmpty ? entry.painTypes.join(', ') : 'Pain')
        : '';

    final numColor =
        (cellColor == PdfColors.red || cellColor == PdfColors.green)
        ? PdfColors.white
        : PdfColors.black;

    // Peak label formatting: "Peak" for 'P', "+1", "+2", "+3" for following days
    String peakLabel = '';
    if (entry?.peakDayLabel != null) {
      switch (entry!.peakDayLabel) {
        case 'P':
        case 'Peak':
          peakLabel = 'Peak';
          break;
        case '1':
        case '+1':
          peakLabel = '+1';
          break;
        case '2':
        case '+2':
          peakLabel = '+2';
          break;
        case '3':
        case '+3':
          peakLabel = '+3';
          break;
        default:
          peakLabel = entry.peakDayLabel!;
      }
    }

    const double cellWidth = 51;

    return pw.Container(
      width: cellWidth,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // 1. Peak Day label above stamp
          pw.Container(
            height: 14,
            child: pw.Text(
              peakLabel,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: peakLabel == 'Peak' ? PdfColors.red900 : PdfColors.black,
              ),
            ),
          ),

          // 2. The Stamp with inset cycle day number in top-left
          pw.Container(
            width: 48,
            height: 38,
            decoration: pw.BoxDecoration(
              color: cellColor,
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Stack(
              children: [
                pw.Positioned(
                  top: 2,
                  left: 3,
                  child: pw.Text(
                    '$dayNum',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: numColor,
                    ),
                  ),
                ),
                pw.Center(
                  child: drawBaby
                      ? _buildBabySymbol(PdfColors.black)
                      : (drawGreenBaby
                            ? _buildBabySymbol(PdfColors.white)
                            : (entry == null
                                  ? pw.Text(
                                      '?',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.grey600,
                                      ),
                                    )
                                  : pw.SizedBox())),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 3),

          // 3. Date in black
          pw.Text(
            AppDateFormats.shortMonthDay.format(dayDate),
            style: const pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 3),

          // 4. Resolved VDRS Code in serif font (size 12) with frequency count
          pw.Text(
            entry != null ? formatObservationCode(entry) : '?',
            style: pw.TextStyle(
              font: pw.Font.timesBold(),
              fontSize: 12,
              color: entry != null ? PdfColors.black : PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),

          // 5. Pain in English (size 10)
          if (painDescription.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              painDescription,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],

          // 6. Daily notes directly under day (size 10)
          if (entry != null && entry.comments.trim().isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              entry.comments.trim(),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Formats the observation code ensuring that frequency count (e.g., x1, x2, x3, AD) is effectively included
  static String formatObservationCode(DailyEntry? entry) {
    if (entry == null) return '?';
    final code = entry.resolvedVdrsCode.trim();
    if (code.isEmpty || code == '?') return code;

    // If code already contains a frequency code (x1, x2, x3, AD, etc.), return as is
    final hasFrequency = RegExp(r'\b(x\d+|AD)\b').hasMatch(code);
    if (hasFrequency) return code;

    // Check if it's pure menstrual flow (H, M, L without mucus or sensation)
    if (RegExp(r'^[HML](-[A-Z]+)?(\s+I)?$').hasMatch(code)) {
      return code;
    }

    // Determine count from matching observations if available
    int count = 1;
    if (entry.observations.isNotEmpty) {
      final codeParts = code.split(' ').where((p) => p != 'I').toList();
      final baseCode = codeParts.isNotEmpty ? codeParts.last : code;

      final matching = entry.observations.where((obs) {
        if (obs.hasMucus) {
          return obs.mucusPart() == baseCode;
        }
        return obs.sensation.code == baseCode || obs.mucusPart() == baseCode;
      }).length;

      if (matching > 0) {
        count = matching;
      }
    }

    final freqStr = count == 1
        ? 'x1'
        : (count == 2 ? 'x2' : (count == 3 ? 'x3' : 'AD'));

    if (code.endsWith(' I')) {
      final withoutI = code.substring(0, code.length - 2);
      return '$withoutI $freqStr I';
    } else if (code == 'I') {
      return '$freqStr I';
    } else {
      return '$code $freqStr';
    }
  }

  // Draw a simple vector stick baby outline to represent the baby symbol
  static pw.Widget _buildBabySymbol(PdfColor color) {
    return pw.CustomPaint(
      size: const PdfPoint(10, 15),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas
          ..setColor(color)
          ..setLineWidth(0.8)
          // Head (Circle)
          ..drawEllipse(5, 11.5, 2.5, 2.5)
          ..strokePath()
          // Body (Line/Oval)
          ..moveTo(5, 9.0)
          ..lineTo(5, 3.5)
          ..strokePath()
          // Arms
          ..moveTo(2.0, 6.5)
          ..lineTo(8.0, 6.5)
          ..strokePath()
          // Legs
          ..moveTo(5, 3.5)
          ..lineTo(2.5, 1.0)
          ..moveTo(5, 3.5)
          ..lineTo(7.5, 1.0)
          ..strokePath();
      },
    );
  }
}
