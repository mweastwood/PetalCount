import 'dart:io';
import 'dart:typed_data';

/// Utility to rasterize PDF documents to PNG images for golden/visual testing.
class PdfRasterizer {
  /// Converts a PDF [Uint8List] synchronously into a list of PNG image byte arrays (one per page).
  ///
  /// Uses system utilities `gs` (Ghostscript) or `pdftoppm` (Poppler).
  /// Being synchronous prevents `FakeAsync` deadlocks in Flutter widget tests.
  static List<Uint8List> rasterizeSync(Uint8List pdfBytes, {int dpi = 150}) {
    final tempDir = Directory.systemTemp.createTempSync('pdf_raster_');
    try {
      final pdfFile = File('${tempDir.path}/input.pdf');
      pdfFile.writeAsBytesSync(pdfBytes);

      final hasGs = _hasExecutable('gs');
      final hasPdftoppm = !hasGs && _hasExecutable('pdftoppm');

      if (!hasGs && !hasPdftoppm) {
        throw UnsupportedError(
          'PDF rasterization requires Ghostscript (gs) or Poppler (pdftoppm) installed on the system.',
        );
      }

      ProcessResult result;
      if (hasGs) {
        result = Process.runSync('gs', [
          '-sDEVICE=png16m',
          '-r$dpi',
          '-dNOPAUSE',
          '-dBATCH',
          '-dSAFER',
          '-sOutputFile=${tempDir.path}/page_%03d.png',
          pdfFile.path,
        ]);
      } else {
        result = Process.runSync('pdftoppm', [
          '-png',
          '-r',
          '$dpi',
          pdfFile.path,
          '${tempDir.path}/page',
        ]);
      }

      if (result.exitCode != 0) {
        throw StateError(
          'Failed to rasterize PDF: exitCode=${result.exitCode}\n${result.stderr}',
        );
      }

      final pageFiles =
          tempDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.png'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      if (pageFiles.isEmpty) {
        throw StateError('No output image files generated from PDF.');
      }

      final pages = <Uint8List>[];
      for (final file in pageFiles) {
        pages.add(file.readAsBytesSync());
      }
      return pages;
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  /// Asynchronous wrapper around [rasterizeSync].
  static Future<List<Uint8List>> rasterize(
    Uint8List pdfBytes, {
    int dpi = 150,
  }) async {
    return rasterizeSync(pdfBytes, dpi: dpi);
  }

  static bool _hasExecutable(String executable) {
    try {
      final res = Process.runSync('which', [executable]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
