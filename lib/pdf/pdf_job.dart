import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../ayah/failures.dart';
import '../ayah/file_names.dart';
import '../ayah/share_service.dart';
import '../ayah/surah_pages.dart';
import '../mushaf/models.dart';
import '../mushaf/page_look.dart';
import '../render/indexed_flate.dart';
import '../render/page_renderer.dart';
import 'pdf_writer.dart';

/// A flag the job checks before and after every await; setting it stops the job at its next step.
class CancelToken {
  bool _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// What the surah PDF job is doing (data-model.md, PdfJob.state).
sealed class PdfJobState {
  const PdfJobState();
}

class PdfIdle extends PdfJobState {
  const PdfIdle();
}

/// [done] pages are finished out of [total]; the page being drawn is `done + 1`.
class PdfPreparing extends PdfJobState {
  const PdfPreparing({
    required this.surahName,
    required this.done,
    required this.total,
  });

  final String surahName;
  final int done;
  final int total;
}

class PdfReady extends PdfJobState {
  const PdfReady({
    required this.surahName,
    required this.path,
    required this.fileName,
  });

  final String surahName;
  final String path;
  final String fileName;
}

class PdfFailed extends PdfJobState {
  const PdfFailed(this.kind);

  final ShareFailureKind kind;

  String get message => ShareFailure(kind).message;
}

typedef PdfWriterFactory = PdfWriter Function(
  File file, {
  required String title,
  required int pageCount,
});

/// Prepares the PDF of one surah, page by page, in the background of the reader: draws a page, adds it to
/// the file, tells its listeners, and lets the event loop run before the next one so the reader stays smooth.
/// Only one job runs at a time (spec FR-016). The partial file is deleted on cancel and on failure.
class PdfJob extends ChangeNotifier {
  PdfJob({
    required this.renderer,
    required this.files,
    required this.meta,
    this.writerFactory,
  });

  final PageRenderer renderer;
  final TempShareFiles files;
  final MushafMeta meta;

  /// A writer supplied by a test; null builds the real one with the sheet in the job's look.
  final PdfWriterFactory? writerFactory;

  /// Built with `--dart-define=AYAH_MENU_TRACE=true`, a finished job logs its time and size (spec SC-005).
  static const bool _trace = bool.fromEnvironment('AYAH_MENU_TRACE');
  final Stopwatch _stopwatch = Stopwatch();

  PdfJobState _state = const PdfIdle();
  CancelToken _token = CancelToken();
  // Created by the first start, in the zone of its caller (a Future built earlier in another zone would
  // resume its waiter on that zone's event loop).
  Future<void>? _running;
  bool _sharing = false;
  bool _disposed = false;

  PdfJobState get state => _state;

  void _set(PdfJobState next) {
    _state = next;
    if (!_disposed) notifyListeners();
  }

  /// Starts the PDF of [surah] in [look] (the app's look when the owner asked); false (and nothing changes) while
  /// another job is preparing. A finished or failed job that was not shared or closed is replaced. The look is the
  /// job's own from here on: every page and the sheet use it, whatever the app's look becomes meanwhile.
  bool start(int surah, {PageLook look = PageLook.screen}) {
    if (_state is PdfPreparing) return false;
    final pages = SurahPages.of(meta, surah);
    final name = meta.surah(surah).name;
    final token = _token = CancelToken();
    _stopwatch
      ..reset()
      ..start();
    final previous = _running;
    _set(PdfPreparing(surahName: name, done: 0, total: pages.count));
    _running = _run(previous, token, surah, name, pages, look);
    return true;
  }

  Future<void> _run(
    Future<void>? previous,
    CancelToken token,
    int surah,
    String name,
    SurahPages pages,
    PageLook look,
  ) async {
    // A cancelled job may still be removing its file; never start over it.
    if (previous != null) await previous;
    PdfWriter? writer;
    try {
      if (token.cancelled) return;
      await files.clean();
      final fileName = FileNames.surah(name);
      final file = await files.create(fileName);
      final factory = writerFactory;
      writer = factory != null
          ? factory(file, title: 'سورة $name', pageCount: pages.count)
          : PdfWriter(
              file,
              title: 'سورة $name',
              pageCount: pages.count,
              sheet: look.background,
            );
      for (var i = 0; i < pages.count; i++) {
        if (token.cancelled) return await writer.abort();
        final IndexedPage page = await renderer.pdfPage(
          pages.first + i,
          look: look,
        );
        if (token.cancelled) return await writer.abort();
        await writer.addPage(page);
        if (token.cancelled) return await writer.abort();
        _set(PdfPreparing(surahName: name, done: i + 1, total: pages.count));
        // Let the reader handle touches and frames before the next page.
        await Future<void>.delayed(Duration.zero);
      }
      await writer.finish();
      if (token.cancelled) {
        await _delete(file);
        return;
      }
      if (_trace) {
        debugPrint(
          'PDF surah=$surah pages=${pages.count} ms=${_stopwatch.elapsedMilliseconds} bytes=${await _lengthOf(file)}',
        );
      }
      _set(PdfReady(surahName: name, path: file.path, fileName: fileName));
    } catch (error) {
      await writer?.abort();
      if (!token.cancelled) {
        _set(PdfFailed(ShareFailure.fromError(error).kind));
      }
    }
  }

  /// Stops the job within one step and deletes its partial file. Completes when the file is gone; the state
  /// is [PdfIdle] at once.
  Future<void> cancel() {
    if (_state is! PdfPreparing) return Future<void>.value();
    _token.cancel();
    _set(const PdfIdle());
    return _running ?? Future<void>.value();
  }

  /// Hands the finished PDF to the share sheet, then returns to idle. A dismissed sheet is silent; a failure
  /// to share is [PdfFailed] (`couldNotShare`). The file stays until the next job so the receiving app can
  /// finish reading it.
  Future<void> shareReady(ShareService share) async {
    final ready = _state;
    if (ready is! PdfReady || _sharing) return;
    _sharing = true;
    try {
      await share.shareFile(
        path: ready.path,
        fileName: ready.fileName,
        mimeType: 'application/pdf',
      );
      if (identical(_state, ready)) _set(const PdfIdle());
    } on ShareFailure catch (failure) {
      if (identical(_state, ready)) _set(PdfFailed(failure.kind));
    } finally {
      _sharing = false;
    }
  }

  /// Closes a finished or failed job. The file of a finished job is removed unless the share sheet has it.
  void dismiss() {
    final current = _state;
    if (current is! PdfReady && current is! PdfFailed) return;
    if (current is PdfReady && !_sharing) {
      try {
        final file = File(current.path);
        if (file.existsSync()) file.deleteSync();
      } on FileSystemException {
        // The folder is emptied at the next job and at the next start.
      }
    }
    _set(const PdfIdle());
  }

  Future<int> _lengthOf(File file) async {
    try {
      return await file.length();
    } on FileSystemException {
      return -1;
    }
  }

  Future<void> _delete(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // The folder is emptied at the next job and at the next start.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _token.cancel();
    super.dispose();
  }
}
