// Checks the PDF the app writes by reading its bytes back, with no PDF package: header, page objects,
// image XObjects, the content stream that places each image, the xref table, the trailer, the title and
// the absence of metadata, text, annotations, attachments and scripts (spec FR-017).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Color;
import 'package:mushaf/pdf/a4_layout.dart';
import 'package:mushaf/pdf/pdf_writer.dart';
import 'package:mushaf/render/indexed_flate.dart';
import 'package:mushaf/theme.dart';

IndexedPage tinyPage(int seed, {int width = 4, int height = 6}) {
  final indices = Uint8List.fromList([
    for (var i = 0; i < width * height; i++) (i * 7 + seed * 31) % 256,
  ]);
  final palette = Uint8List.fromList([
    for (var i = 0; i < 768; i++) (i * 5 + seed * 3) % 256,
  ]);
  return IndexedPage(
    width: width,
    height: height,
    palette: palette,
    flateBytes: Uint8List.fromList(zlib.encode(indices)),
  );
}

String paletteHex(Uint8List palette) =>
    [for (final v in palette) v.toRadixString(16).toUpperCase().padLeft(2, '0')]
        .join();

/// The bytes read as Latin-1, so every byte is one character and offsets are string indexes.
String latin1Of(File f) => latin1.decode(f.readAsBytesSync());

/// The text of a PDF with the bodies of its streams cut out (they are binary).
String withoutStreams(String pdf) =>
    pdf.replaceAll(RegExp(r'stream\n[\s\S]*?\nendstream'), 'stream\nendstream');

String utf16beHex(String s) {
  final b = StringBuffer('FEFF');
  for (final unit in s.codeUnits) {
    b.write(unit.toRadixString(16).toUpperCase().padLeft(4, '0'));
  }
  return b.toString();
}

Future<File> writeDoc(
  Directory dir, {
  required int pages,
  String title = 'سورة الفاتحة',
}) async {
  final file = File('${dir.path}/doc.pdf');
  final writer = PdfWriter(file, title: title, pageCount: pages);
  for (var i = 0; i < pages; i++) {
    await writer.addPage(tinyPage(i));
  }
  await writer.finish();
  return file;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('pdf_writer_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('the file starts with the PDF header and ends with %%EOF', () async {
    final pdf = latin1Of(await writeDoc(dir, pages: 2));
    expect(pdf, startsWith('%PDF-1.'));
    expect(pdf.trimRight(), endsWith('%%EOF'));
  });

  test(
    'it has one page object per page, A4 sized, in order, under one Pages node',
    () async {
      final pdf = withoutStreams(latin1Of(await writeDoc(dir, pages: 3)));
      final pages = RegExp(r'/Type /Page\b').allMatches(pdf).length;
      expect(pages, 3);
      expect(
        RegExp(r'/MediaBox \[0 0 595\.28 841\.89\]').allMatches(pdf).length,
        3,
      );
      expect(pdf, contains('/Type /Pages'));
      expect(pdf, contains('/Count 3'));
      final kids = RegExp(r'/Kids \[([^\]]*)\]').firstMatch(pdf)!.group(1)!;
      final refs = RegExp(r'(\d+) 0 R')
          .allMatches(kids)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      expect(refs, hasLength(3));
      expect(refs, [...refs]..sort(), reason: 'pages are listed in order');
    },
  );

  test('each page has one 8-bit 256-colour Flate image of its own size, palette and bytes', () async {
    final file = await writeDoc(dir, pages: 2);
    final pdf = latin1Of(file);
    final heads = RegExp(
      r'<< /Type /XObject /Subtype /Image /Width (\d+) /Height (\d+) /ColorSpace \[/Indexed /DeviceRGB 255 <([0-9A-F]{1536})>\] /BitsPerComponent 8 /Filter /FlateDecode /Length (\d+) >>\nstream\n',
    ).allMatches(pdf).toList();
    expect(heads, hasLength(2));
    for (var i = 0; i < 2; i++) {
      final m = heads[i];
      expect((m.group(1), m.group(2)), ('4', '6'));
      expect(m.group(3), paletteHex(tinyPage(i).palette));
      final length = int.parse(m.group(4)!);
      final start = m.end;
      final body = latin1.encode(pdf.substring(start, start + length));
      expect(body, tinyPage(i).flateBytes);
      expect(pdf.substring(start + length), startsWith('\nendstream'));
    }
  });

  test('the content stream of each page fills the sheet with the app\'s green, then places the image where A4Layout says', () async {
    final pdf = latin1Of(await writeDoc(dir, pages: 2));
    final spot = A4Layout.place(4, 6);
    String n(double v) => v.toStringAsFixed(2);
    String c(double v) => v.toStringAsFixed(4);
    final green = AppColors.green;
    final expected =
        'q ${c(green.r)} ${c(green.g)} ${c(green.b)} rg 0 0 ${n(A4Layout.width)} ${n(A4Layout.height)} re f Q '
        'q ${n(spot.w)} 0 0 ${n(spot.h)} ${n(spot.x)} ${n(spot.y)} cm /Im0 Do Q';
    expect(RegExp(RegExp.escape(expected)).allMatches(pdf).length, 2);
    expect(c(green.r), '0.0549', reason: 'the green is 0E3B30');
  });

  test('the sheet colour can be given, and defaults to the page background of the app\'s look', () async {
    final file = File('${dir.path}/white.pdf');
    final writer = PdfWriter(
      file,
      title: 'x',
      pageCount: 1,
      sheet: const Color(0xFFFFFFFF),
    );
    await writer.addPage(tinyPage(0));
    await writer.finish();
    expect(
      latin1Of(file),
      contains('q 1.0000 1.0000 1.0000 rg 0 0 595.28 841.89 re f Q'),
    );
  });

  test(
    'every xref offset points at its "N 0 obj" and the trailer is right',
    () async {
      final pdf = latin1Of(await writeDoc(dir, pages: 3));
      final startxref = int.parse(
        RegExp(r'startxref\n(\d+)\n%%EOF').firstMatch(pdf)!.group(1)!,
      );
      expect(pdf.substring(startxref), startsWith('xref\n'));
      final table = RegExp(r'xref\n0 (\d+)\n((?:\d{10} \d{5} [nf] \n)+)')
          .firstMatch(pdf.substring(startxref))!;
      final size = int.parse(table.group(1)!);
      final entries = RegExp(r'(\d{10}) (\d{5}) ([nf]) \n')
          .allMatches(table.group(2)!)
          .toList();
      expect(entries, hasLength(size));
      expect(entries.first.group(3), 'f');
      for (var i = 1; i < size; i++) {
        final offset = int.parse(entries[i].group(1)!);
        expect(entries[i].group(3), 'n');
        expect(
          pdf.substring(offset),
          startsWith('$i 0 obj\n'),
          reason: 'object $i',
        );
      }
      final trailer = RegExp(r'trailer\n<< ([^\n]*) >>')
          .firstMatch(pdf)!
          .group(1)!;
      expect(trailer, contains('/Size $size'));
      final root = int.parse(
        RegExp(r'/Root (\d+) 0 R').firstMatch(trailer)!.group(1)!,
      );
      expect(
        pdf.substring(int.parse(entries[root].group(1)!)),
        contains('/Type /Catalog'),
      );
    },
  );

  test('the title is UTF-16BE and nothing else describes the file', () async {
    final pdf = withoutStreams(latin1Of(await writeDoc(dir, pages: 1)));
    expect(pdf, contains('/Title <${utf16beHex('سورة الفاتحة')}>'));
    for (final key in const [
      '/Author',
      '/Producer',
      '/Creator',
      '/CreationDate',
      '/ModDate',
      '/Subject',
      '/Keywords',
      '/Metadata',
    ]) {
      expect(pdf, isNot(contains(key)), reason: key);
    }
  });

  test('it has no text, fonts, annotations, attachments or scripts', () async {
    final pdf = withoutStreams(latin1Of(await writeDoc(dir, pages: 2)));
    for (final key in const [
      '/Font',
      '/Annots',
      '/Annot',
      '/Link',
      '/EmbeddedFile',
      '/Filespec',
      '/JS',
      '/JavaScript',
      '/OpenAction',
      '/AA',
      '/Names',
      '/URI',
      'BT\n',
      ' Tj',
      ' TJ',
    ]) {
      expect(pdf, isNot(contains(key)), reason: key);
    }
  });

  test('abort deletes the file at any point', () async {
    final file = File('${dir.path}/partial.pdf');
    final writer = PdfWriter(file, title: 'x', pageCount: 3);
    await writer.addPage(tinyPage(0));
    expect(file.existsSync(), isTrue);
    await writer.abort();
    expect(file.existsSync(), isFalse);
  });

  test('abort before any page is harmless', () async {
    final file = File('${dir.path}/never.pdf');
    final writer = PdfWriter(file, title: 'x', pageCount: 3);
    await writer.abort();
    expect(file.existsSync(), isFalse);
  });

  test(
    'finishing early or adding too many pages is a programming error',
    () async {
      final file = File('${dir.path}/bad.pdf');
      final writer = PdfWriter(file, title: 'x', pageCount: 1);
      await expectLater(writer.finish(), throwsStateError);
      await writer.addPage(tinyPage(0));
      await expectLater(writer.addPage(tinyPage(1)), throwsStateError);
      await writer.abort();
    },
  );

  test(
    'a document of 48 pages is valid and about as big as its images',
    () async {
      final file = await writeDoc(dir, pages: 48);
      final pdf = latin1Of(file);
      expect(
        RegExp(r'/Type /Page\b').allMatches(withoutStreams(pdf)).length,
        48,
      );
      final images = 48 * tinyPage(0).flateBytes.length;
      expect(file.lengthSync(), lessThan(images + 48 * (1536 + 800) + 2000));
    },
  );
}
