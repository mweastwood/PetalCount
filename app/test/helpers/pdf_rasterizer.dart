import 'dart:io';
import 'dart:typed_data';

/// Utility to rasterize PDF documents to PNG images for golden/visual testing.
class PdfRasterizer {
  static const List<String> _gsCommands = ['gs', 'gswin64c', 'gswin32c'];

  /// Indicates whether a supported PDF rasterization utility is installed.
  static bool get isSupported =>
      _findExecutable(_gsCommands) != null ||
      _findExecutable(['pdftoppm']) != null;

  /// Converts a PDF [Uint8List] synchronously into a list of PNG image byte arrays (one per page).
  ///
  /// Uses system utilities `gs` (Ghostscript) or `pdftoppm` (Poppler).
  /// Being synchronous prevents `FakeAsync` deadlocks in Flutter widget tests.
  static List<Uint8List> rasterizeSync(Uint8List pdfBytes, {int dpi = 150}) {
    final tempDir = Directory.systemTemp.createTempSync('pdf_raster_');
    try {
      final pdfFile = File('${tempDir.path}/input.pdf');
      pdfFile.writeAsBytesSync(pdfBytes);

      final gsCmd = _findExecutable(_gsCommands);
      final pdftoppmCmd = gsCmd == null ? _findExecutable(['pdftoppm']) : null;

      if (gsCmd == null && pdftoppmCmd == null) {
        throw UnsupportedError(
          'PDF rasterization requires Ghostscript (gs/gswin64c) or Poppler (pdftoppm) installed on the system.',
        );
      }

      ProcessResult result;
      if (gsCmd != null) {
        result = Process.runSync(gsCmd, [
          '-sDEVICE=png16m',
          '-r$dpi',
          '-dNOPAUSE',
          '-dBATCH',
          '-dSAFER',
          '-sOutputFile=${tempDir.path}/page_%03d.png',
          pdfFile.path,
        ]);
      } else {
        result = Process.runSync(pdftoppmCmd!, [
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
            ..sort((a, b) {
              final aName = a.uri.pathSegments.last;
              final bName = b.uri.pathSegments.last;
              final aNum = int.tryParse(
                RegExp(r'\d+').firstMatch(aName)?.group(0) ?? '',
              );
              final bNum = int.tryParse(
                RegExp(r'\d+').firstMatch(bName)?.group(0) ?? '',
              );
              if (aNum != null && bNum != null) {
                return aNum.compareTo(bNum);
              }
              return aName.compareTo(bName);
            });

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

  static String? _findExecutable(List<String> executables) {
    for (final exe in executables) {
      if (_hasExecutable(exe)) return exe;
    }
    return null;
  }

  static bool _hasExecutable(String executable) {
    try {
      final checkCmd = Platform.isWindows ? 'where' : 'which';
      final res = Process.runSync(checkCmd, [executable]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
