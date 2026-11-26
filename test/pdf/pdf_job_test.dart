// The surah PDF job: one at a time, page by page, with progress, cancel, and the three failures (spec
// FR-016, FR-018), over a fake renderer and a real temporary folder.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/pdf/pdf_writer.dart';
import 'package:mushaf/render/indexed_flate.dart';

import '../support/fake_renderer.dart';
import '../support/fake_share.dart';
import '../support/test_meta.dart';

/// A writer whose disk is full from the [failAt]th page on.
class FullDiskWriter extends PdfWriter {
  FullDiskWriter(
    super.file, {
    required super.title,
    required super.pageCount,
    required this.failAt,
  });

  final int failAt;
  int _count = 0;

  @override
  Future<void> addPage(IndexedPage page) async {
    if (++_count >= failAt) {
      throw const FileSystemException(
        'write failed',
        '/data',
        OSError('No space left on device', 28),
      );
    }
    await super.addPage(page);
  }
}

void main() {
  late Directory dir;
  late FakePageRenderer renderer;
  late FakeShareService share;
  late PdfJob job;
  late List<PdfJobState> seen;

  PdfJob make({
    PdfWriter Function(File, {required String title, required int pageCount})?
    writer,
  }) {
    final j = PdfJob(
      renderer: renderer,
      files: TempShareFiles(baseDir: () async => dir),
      meta: pdfMeta(),
      writerFactory: writer,
    );
    j.addListener(() => seen.add(j.state));
    return j;
  }

  File folderFile(String name) => File('${dir.path}/share/$name');

  /// Lets the job run until [done] holds, checked now and after each state the job announces (the job
  /// announces after every page and at the end). The job writes a real file, so this waits on the job itself
  /// with a generous real-time limit, never a fixed count of event-loop turns, which a busy machine outruns.
  /// On the limit it returns, and the test's own expectations report what was missing.
  Future<void> until(
    bool Function() done, {
    Duration limit = const Duration(seconds: 20),
  }) async {
    if (done()) return;
    final reached = Completer<void>();
    void check() {
      if (!reached.isCompleted && done()) reached.complete();
    }

    job.addListener(check);
    try {
      await reached.future.timeout(limit, onTimeout: () {});
    } finally {
      job.removeListener(check);
    }
  }

  /// Lets the job run until it is no longer preparing.
  Future<void> untilSettled() => until(() => job.state is! PdfPreparing);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pdf_job_test');
    renderer = FakePageRenderer();
    share = FakeShareService();
    seen = [];
    job = make();
  });

  tearDown(() {
    job.dispose();
    dir.deleteSync(recursive: true);
  });

  test('starts idle', () {
    expect(job.state, isA<PdfIdle>());
  });

  test('start(2) renders pages 2..49 in order and ends ready with the Arabic file name', () async {
    expect(job.start(2), isTrue);
    await untilSettled();
    expect(renderer.pdfPages, [for (var p = 2; p <= 49; p++) p]);
    final ready = job.state as PdfReady;
    expect(ready.fileName, 'سورة البقرة.pdf');
    expect(ready.path, folderFile('سورة البقرة.pdf').path);
    expect(File(ready.path).existsSync(), isTrue);
    expect(File(ready.path).readAsBytesSync().sublist(0, 5), '%PDF-'.codeUnits);
  });

  test('the file holds one A4 page per Mushaf page', () async {
    job.start(2);
    await untilSettled();
    final text = String.fromCharCodes(
      File((job.state as PdfReady).path).readAsBytesSync(),
    );
    expect(RegExp(r'/Type /Page\b').allMatches(text).length, 48);
    expect(text, contains('/Count 48'));
  });

  test(
    'progress is announced after every page: done counts finished pages',
    () async {
      job.start(2);
      await untilSettled();
      final progress = seen.whereType<PdfPreparing>().toList();
      expect(progress.map((p) => p.done), [for (var d = 0; d <= 48; d++) d]);
      expect(progress.every((p) => p.total == 48), isTrue);
      expect(progress.first.surahName, 'البقرة');
    },
  );

  test('a one-page surah and a surah on page 604 work', () async {
    job.start(1);
    await untilSettled();
    expect(renderer.pdfPages, [1]);
    expect((job.state as PdfReady).fileName, 'سورة الفاتحة.pdf');
    job.dismiss();
    renderer.pdfPages.clear();
    job.start(3);
    await untilSettled();
    expect(renderer.pdfPages, [604]);
  });

  test(
    'start while a job is preparing returns false and changes nothing',
    () async {
      final gate = Completer<void>();
      renderer.gate = gate.future;
      expect(job.start(2), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(job.start(1), isFalse);
      expect(job.state, isA<PdfPreparing>());
      expect((job.state as PdfPreparing).total, 48);
      gate.complete();
      await untilSettled();
      expect(
        renderer.pdfPages.first,
        2,
        reason: 'the first job went on, the second never started',
      );
    },
  );

  test('cancel stops within one step, leaves no file and ends idle', () async {
    job.start(2);
    await until(() => renderer.pdfPages.length >= 5);
    expect(renderer.pdfPages.length, greaterThanOrEqualTo(5));
    await job.cancel();
    final drawn = renderer.pdfPages.length;
    expect(job.state, isA<PdfIdle>());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(
      renderer.pdfPages.length,
      drawn,
      reason: 'no page is drawn after the cancel',
    );
    expect(
      drawn,
      lessThan(10),
      reason: 'it stopped within a step or two of the cancel',
    );
    final folder = Directory('${dir.path}/share');
    expect(folder.existsSync() ? folder.listSync() : [], isEmpty);
  });

  test('a cancelled job can be followed by a new one', () async {
    final gate = Completer<void>();
    renderer.gate = gate.future;
    job.start(2);
    await Future<void>.delayed(Duration.zero);
    final cancelled = job.cancel();
    expect(job.state, isA<PdfIdle>());
    renderer.gate = null;
    gate.complete();
    await cancelled;
    expect(job.start(1), isTrue);
    await untilSettled();
    expect(job.state, isA<PdfReady>());
    expect(File((job.state as PdfReady).path).existsSync(), isTrue);
  });

  test(
    'no space on the phone ends failed(noSpace) and removes the file',
    () async {
      job.dispose();
      job = make(
        writer: (file, {required title, required pageCount}) =>
            FullDiskWriter(file, title: title, pageCount: pageCount, failAt: 3),
      );
      job.start(2);
      await untilSettled();
      expect((job.state as PdfFailed).kind, ShareFailureKind.noSpace);
      final folder = Directory('${dir.path}/share');
      expect(folder.listSync(), isEmpty);
    },
  );

  test('a page that cannot be drawn ends failed(couldNotPrepare) and removes the file', () async {
    renderer.onPrint = (page) {
      if (page == 4) throw const ShareFailure(ShareFailureKind.couldNotPrepare);
    };
    job.start(2);
    await untilSettled();
    expect((job.state as PdfFailed).kind, ShareFailureKind.couldNotPrepare);
    expect(Directory('${dir.path}/share').listSync(), isEmpty);
  });

  test('an unexpected error while drawing is couldNotPrepare', () async {
    renderer.failure = StateError('boom');
    job.start(1);
    await untilSettled();
    expect((job.state as PdfFailed).kind, ShareFailureKind.couldNotPrepare);
  });

  test('dismiss turns failed back into idle and a new job can start', () async {
    renderer.failure = StateError('boom');
    job.start(1);
    await untilSettled();
    job.dismiss();
    expect(job.state, isA<PdfIdle>());
    renderer.failure = null;
    expect(job.start(1), isTrue);
    await untilSettled();
    expect(job.state, isA<PdfReady>());
  });

  test(
    'shareReady hands over the PDF as application/pdf and returns to idle',
    () async {
      job.start(1);
      await untilSettled();
      final path = (job.state as PdfReady).path;
      await job.shareReady(share);
      final shared = share.files.single;
      expect(
        (shared.path, shared.fileName, shared.mimeType),
        (path, 'سورة الفاتحة.pdf', 'application/pdf'),
      );
      expect(job.state, isA<PdfIdle>());
      expect(
        File(path).existsSync(),
        isTrue,
        reason: 'the share target may still be reading it',
      );
    },
  );

  test('a dismissed share sheet is silent', () async {
    share.outcome = ShareOutcome.dismissed;
    job.start(1);
    await untilSettled();
    await job.shareReady(share);
    expect(job.state, isA<PdfIdle>());
  });

  test('a share failure shows failed(couldNotShare)', () async {
    share.failure = const ShareFailure(ShareFailureKind.couldNotShare);
    job.start(1);
    await untilSettled();
    await job.shareReady(share);
    expect((job.state as PdfFailed).kind, ShareFailureKind.couldNotShare);
  });

  test(
    'dismiss on a ready file removes it; shareReady outside ready does nothing',
    () async {
      await job.shareReady(share);
      expect(share.files, isEmpty);
      job.start(1);
      await untilSettled();
      final path = (job.state as PdfReady).path;
      job.dismiss();
      expect(job.state, isA<PdfIdle>());
      expect(File(path).existsSync(), isFalse);
    },
  );

  test(
    'a pause while no frames are drawn resumes without losing a page',
    () async {
      final gate = Completer<void>();
      job.start(2);
      await until(() => renderer.pdfPages.length >= 3);
      renderer.gate = gate.future; // the app goes to the background: no frames
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final stuckAt = (job.state as PdfPreparing).done;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        (job.state as PdfPreparing).done,
        stuckAt,
        reason: 'nothing moves while paused',
      );
      gate.complete(); // the app is back
      await untilSettled();
      final ready = job.state as PdfReady;
      final text = String.fromCharCodes(File(ready.path).readAsBytesSync());
      expect(RegExp(r'/Type /Page\b').allMatches(text).length, 48);
      final asked = renderer.pdfPages.toSet().toList()..sort();
      expect(asked, [for (var p = 2; p <= 49; p++) p]);
    },
  );
}
