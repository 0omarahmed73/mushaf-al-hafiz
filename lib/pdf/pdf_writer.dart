import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart' show Color;

import '../mushaf/page_look.dart';
import '../render/indexed_flate.dart';
import 'a4_layout.dart';

/// Writes a PDF of page images, one A4 sheet per image, straight to a file so a 48-page document is never held
/// in memory. Each sheet is filled edge to edge with [sheet] (the app's green) and carries the page image,
/// a 256-colour indexed picture of the page as the app draws it, centred inside the margin. The file has no
/// text, fonts, annotations, attachments, scripts or metadata other than its title (spec FR-015, FR-017).
///
/// Object numbers are fixed by the page count: 1 catalog, 2 page tree, 3 info (the title), then for page `i`
/// (from 0) the image `4 + 3i`, its content stream `5 + 3i` and the page `6 + 3i`. The three header objects
/// are written last, when the page count is known to have been reached.
class PdfWriter {
  PdfWriter(
    this.file, {
    required this.title,
    required this.pageCount,
    Color? sheet,
  }) : sheet = sheet ?? PageLook.screen.background {
    if (pageCount < 1) throw ArgumentError.value(pageCount, 'pageCount');
  }

  final File file;
  final String title;
  final int pageCount;

  /// The colour of the whole sheet, behind the page image: the image's own background, so the join is invisible.
  final Color sheet;

  RandomAccessFile? _raf;
  int _position = 0;
  int _added = 0;

  /// Byte offset of each object, index = object number.
  final List<int> _offsets = [0];

  bool _closed = false;

  int get _objectCount => 3 + 3 * pageCount;

  Future<void> _write(List<int> bytes) async {
    final raf = _raf ??= await file.open(mode: FileMode.write);
    await raf.writeFrom(bytes);
    _position += bytes.length;
  }

  Future<void> _writeText(String s) => _write(latin1.encode(s));

  Future<void> _header() async {
    // The second line holds four bytes above 127 so tools treat the file as binary.
    await _write([
      ...latin1.encode('%PDF-1.4\n%'),
      0xE2,
      0xE3,
      0xCF,
      0xD3,
      0x0A,
    ]);
  }

  void _noteObject(int number) {
    while (_offsets.length <= number) {
      _offsets.add(0);
    }
    _offsets[number] = _position;
  }

  static String _n(double v) => v.toStringAsFixed(2);

  Future<void> addPage(IndexedPage page) async {
    _checkOpen();
    if (_added >= pageCount) {
      throw StateError('the document was declared with $pageCount pages');
    }
    if (_raf == null) await _header();
    final image = 4 + 3 * _added;
    final content = image + 1;
    final pageObj = image + 2;

    _noteObject(image);
    await _writeText(
      '$image 0 obj\n'
      '<< /Type /XObject /Subtype /Image /Width ${page.width} /Height ${page.height} '
      '/ColorSpace [/Indexed /DeviceRGB 255 <${_hex(page.palette)}>] /BitsPerComponent 8 /Filter /FlateDecode '
      '/Length ${page.flateBytes.length} >>\nstream\n',
    );
    await _write(page.flateBytes);
    await _writeText('\nendstream\nendobj\n');

    final spot = A4Layout.place(page.width, page.height);
    String c(double v) => v.toStringAsFixed(4);
    final draw =
        'q ${c(sheet.r)} ${c(sheet.g)} ${c(sheet.b)} rg 0 0 ${_n(A4Layout.width)} ${_n(A4Layout.height)} re f Q '
        'q ${_n(spot.w)} 0 0 ${_n(spot.h)} ${_n(spot.x)} ${_n(spot.y)} cm /Im0 Do Q';
    _noteObject(content);
    await _writeText(
      '$content 0 obj\n<< /Length ${draw.length} >>\nstream\n$draw\nendstream\nendobj\n',
    );

    _noteObject(pageObj);
    await _writeText(
      '$pageObj 0 obj\n'
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${_n(A4Layout.width)} ${_n(A4Layout.height)}] '
      '/Resources << /XObject << /Im0 $image 0 R >> >> /Contents $content 0 R >>\n'
      'endobj\n',
    );
    _added++;
  }

  Future<void> finish() async {
    _checkOpen();
    if (_added != pageCount) {
      throw StateError('only $_added of $pageCount pages were added');
    }
    final kids = [for (var i = 0; i < pageCount; i++) '${6 + 3 * i} 0 R'];
    _noteObject(2);
    await _writeText(
      '2 0 obj\n<< /Type /Pages /Kids [${kids.join(' ')}] /Count $pageCount >>\nendobj\n',
    );
    _noteObject(1);
    await _writeText('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    _noteObject(3);
    await _writeText('3 0 obj\n<< /Title <${_utf16beHex(title)}> >>\nendobj\n');

    final xrefAt = _position;
    final xref = StringBuffer('xref\n0 ${_objectCount + 1}\n')
      ..write('0000000000 65535 f \n');
    for (var i = 1; i <= _objectCount; i++) {
      xref.write('${_offsets[i].toString().padLeft(10, '0')} 00000 n \n');
    }
    xref
      ..write(
        'trailer\n<< /Size ${_objectCount + 1} /Root 1 0 R /Info 3 0 R >>\n',
      )
      ..write('startxref\n$xrefAt\n%%EOF\n');
    await _writeText(xref.toString());
    await _raf!.flush();
    await _raf!.close();
    _raf = null;
    _closed = true;
  }

  /// Closes the file and deletes it. Safe to call at any point, also twice.
  Future<void> abort() async {
    _closed = true;
    final raf = _raf;
    _raf = null;
    try {
      await raf?.close();
    } on FileSystemException {
      // The file is being thrown away; a failed close does not matter.
    }
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Nothing more can be done; the caller removes the share folder at the next start.
    }
  }

  void _checkOpen() {
    if (_closed) {
      throw StateError('the PDF writer is already finished or aborted');
    }
  }

  static String _hex(List<int> bytes) {
    final out = StringBuffer();
    for (final v in bytes) {
      out.write(v.toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
    return out.toString();
  }

  static String _utf16beHex(String s) {
    final out = StringBuffer('FEFF');
    for (final unit in s.codeUnits) {
      out.write(unit.toRadixString(16).toUpperCase().padLeft(4, '0'));
    }
    return out.toString();
  }
}
