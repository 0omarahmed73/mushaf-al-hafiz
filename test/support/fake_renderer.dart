import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/render/indexed_flate.dart';
import 'package:mushaf/render/page_renderer.dart';

/// A [PageRenderer] for tests: records the pages it was asked for, can take time or fail.
class FakePageRenderer implements PageRenderer {
  final List<int> pictured = [];
  Duration delay = Duration.zero;
  Object? failure;
  Uint8List bytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);

  /// The pages asked for as PDF pages, in order.
  final List<int> pdfPages = [];

  /// The look each picture and each PDF page was asked for in, in order (feature 004).
  final List<PageLook> pictureLooks = [];
  final List<PageLook> pdfLooks = [];

  /// When set, a print page waits for it (a paused app draws no frames) before it is returned.
  Future<void>? gate;

  /// Called with the page number before it is returned; may throw.
  void Function(int page)? onPrint;

  @override
  Future<IndexedPage> pdfPage(int page, {PageLook look = PageLook.screen}) async {
    pdfPages.add(page);
    pdfLooks.add(look);
    if (gate != null) await gate;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    onPrint?.call(page);
    if (failure != null) throw failure!;
    // A 2 x 3 image whose first index is the page number mod 256, so a test can tell the pages apart.
    final indices = Uint8List.fromList([page % 256, 1, 2, 3, 4, 5]);
    return IndexedPage(
      width: 2,
      height: 3,
      palette: Uint8List(768),
      flateBytes: Uint8List.fromList(zlib.encode(indices)),
    );
  }

  @override
  Future<Uint8List> picture(int page, {PageLook look = PageLook.screen}) async {
    pictured.add(page);
    pictureLooks.add(look);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failure != null) throw failure!;
    return bytes;
  }
}

/// A file that keeps what is written in memory, or fails like a full disk.
class MemoryFile extends Fake implements File {
  MemoryFile(this.path, this.owner);

  @override
  final String path;
  final MemoryShareFiles owner;

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    if (owner.diskFull) {
      throw const FileSystemException(
        'write failed',
        '/data',
        OSError('No space left on device', 28),
      );
    }
    owner.written[path] = Uint8List.fromList(bytes);
    return this;
  }
}

/// [TempShareFiles] without a disk: files are kept in [written] unless [diskFull] is set.
class MemoryShareFiles extends TempShareFiles {
  final Map<String, Uint8List> written = {};
  bool diskFull = false;
  int cleaned = 0;

  @override
  Future<File> create(String fileName) async =>
      MemoryFile('/tmp/share/$fileName', this);

  @override
  Future<void> clean() async => cleaned++;
}
