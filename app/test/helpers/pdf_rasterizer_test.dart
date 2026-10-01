import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'pdf_rasterizer.dart';

void main() {
  group('PdfRasterizer', () {
    test('isSupported returns a boolean without throwing', () {
      expect(PdfRasterizer.isSupported, isA<bool>());
    });

    test('rasterizeSync throws ArgumentError when pdfBytes is empty', () {
      expect(
        () => PdfRasterizer.rasterizeSync(Uint8List(0)),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'pdfBytes')
              .having(
                (e) => e.message,
                'message',
                'PDF byte buffer cannot be empty.',
              ),
        ),
      );
    });

    test('rasterize throws ArgumentError when pdfBytes is empty', () async {
      expect(
        () => PdfRasterizer.rasterize(Uint8List(0)),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'pdfBytes')
              .having(
                (e) => e.message,
                'message',
                'PDF byte buffer cannot be empty.',
              ),
        ),
      );
    });

    final validBytes = Uint8List.fromList([1, 2, 3]);

    test('rasterizeSync throws ArgumentError when dpi is non-positive', () {
      for (final dpi in [0, -1]) {
        expect(
          () => PdfRasterizer.rasterizeSync(validBytes, dpi: dpi),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', 'dpi')
                .having(
                  (e) => e.message,
                  'message',
                  'DPI must be greater than zero.',
                ),
          ),
        );
      }
    });

    test('rasterize throws ArgumentError when dpi is non-positive', () async {
      for (final dpi in [0, -1]) {
        expect(
          () => PdfRasterizer.rasterize(validBytes, dpi: dpi),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', 'dpi')
                .having(
                  (e) => e.message,
                  'message',
                  'DPI must be greater than zero.',
                ),
          ),
        );
      }
    });

    group('extractPageNumber', () {
      test('extracts single digit page number', () {
        expect(PdfRasterizer.extractPageNumber('page_1.png'), equals(1));
      });

      test('extracts hyphen-delimited page number used by pdftoppm', () {
        expect(PdfRasterizer.extractPageNumber('page-1.png'), equals(1));
        expect(PdfRasterizer.extractPageNumber('doc-cycle-12.png'), equals(12));
      });

      test('extracts zero-padded page number', () {
        expect(PdfRasterizer.extractPageNumber('page_001.png'), equals(1));
        expect(PdfRasterizer.extractPageNumber('page_042.png'), equals(42));
      });

      test(
        'extracts trailing page number when directory or prefix contains digits',
        () {
          expect(
            PdfRasterizer.extractPageNumber('cycle_2026_page_003.png'),
            equals(3),
          );
          expect(
            PdfRasterizer.extractPageNumber('/tmp/run123/doc_5_page_17.png'),
            equals(17),
          );
        },
      );

      test('returns null when filename has no trailing digits', () {
        expect(PdfRasterizer.extractPageNumber('page.png'), isNull);
        expect(PdfRasterizer.extractPageNumber('output_image.jpg'), isNull);
      });
    });
  });
}
