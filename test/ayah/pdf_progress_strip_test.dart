// The strip above the bottom bar while a surah PDF is prepared (spec FR-016, FR-018; contracts/ui.md).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/ui/pdf_progress_strip.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/theme.dart';

import '../support/fake_pdf.dart';
import '../support/fake_renderer.dart';
import '../support/fake_share.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  late FakePageRenderer renderer;
  late PdfJob job;
  late FakeShareService share;

  setUp(() {
    renderer = FakePageRenderer();
    job = fakePdfJob(renderer);
    share = FakeShareService();
  });

  tearDown(() => job.dispose());

  Future<void> pump(WidgetTester t) => t.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: PdfProgressStrip(job: job, share: share),
        ),
      ),
    ),
  );

  /// Lets the job run until [done] says so.
  Future<void> until(WidgetTester t, bool Function(PdfJobState s) done) async {
    for (var i = 0; i < 400 && !done(job.state); i++) {
      await t.pump(const Duration(milliseconds: 10));
    }
    expect(
      done(job.state),
      isTrue,
      reason: 'the job did not get there: ${job.state}',
    );
  }

  testWidgets('shows nothing while idle', (t) async {
    await pump(t);
    expect(key('pdf-strip'), findsNothing);
  });

  testWidgets('preparing: surah name, «صفحة N من M», «إلغاء», 56 px high', (
    t,
  ) async {
    final gate = Completer<void>();
    renderer.gate = gate.future;
    await pump(t);
    job.start(2);
    await t.pump();
    expect(find.text('جارٍ تجهيز سورة البقرة'), findsOneWidget);
    expect(find.text('صفحة 1 من 48'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(t.getSize(key('pdf-strip')).height, 56);
    expect(t.getSize(key('pdf-cancel')).height, greaterThanOrEqualTo(48));
    gate.complete();
    unawaited(job.cancel());
    await t.pump();
  });

  testWidgets('the page counter follows the job: N is the page being drawn', (
    t,
  ) async {
    await pump(t);
    // Pages 2, 3 and 4 are finished; page 5 waits (a pump runs every page that is not held back).
    renderer.onPrint = (page) {
      if (page == 4) renderer.gate = Completer<void>().future;
    };
    job.start(2);
    await until(t, (s) => s is PdfPreparing && s.done >= 3);
    await t.pump(const Duration(milliseconds: 50));
    final s = job.state as PdfPreparing;
    expect(s.done, 3);
    expect(find.text('صفحة 4 من 48'), findsOneWidget);
    unawaited(job.cancel());
    await t.pump();
  });

  testWidgets('«إلغاء» cancels the job and the strip goes away', (t) async {
    renderer.gate = Completer<void>().future;
    await pump(t);
    job.start(2);
    await t.pump();
    await t.tap(key('pdf-cancel'));
    await t.pump();
    expect(job.state, isA<PdfIdle>());
    expect(key('pdf-strip'), findsNothing);
  });

  testWidgets(
    'ready: «تم تجهيز الملف» and «مشاركة» hands the PDF over and the strip goes away',
    (t) async {
      await pump(t);
      job.start(1);
      await until(t, (s) => s is PdfReady);
      await t.pump();
      expect(find.text('تم تجهيز الملف'), findsOneWidget);
      expect(find.text('سورة الفاتحة.pdf'), findsOneWidget);
      await t.tap(key('pdf-share'));
      await t.pump();
      await t.pump();
      final shared = share.files.single;
      expect(
        (shared.fileName, shared.mimeType),
        ('سورة الفاتحة.pdf', 'application/pdf'),
      );
      expect(key('pdf-strip'), findsNothing);
    },
  );

  testWidgets('ready can be closed without sharing', (t) async {
    await pump(t);
    job.start(1);
    await until(t, (s) => s is PdfReady);
    await t.pump();
    await t.tap(key('pdf-close'));
    await t.pump();
    expect(job.state, isA<PdfIdle>());
    expect(share.files, isEmpty);
  });

  testWidgets('failed: the Arabic message and «إغلاق»', (t) async {
    renderer.failure = StateError('boom');
    await pump(t);
    job.start(1);
    await until(t, (s) => s is PdfFailed);
    await t.pump();
    expect(
      find.text(const ShareFailure(ShareFailureKind.couldNotPrepare).message),
      findsOneWidget,
    );
    expect(find.text('إغلاق'), findsOneWidget);
    await t.tap(key('pdf-close'));
    await t.pump();
    expect(job.state, isA<PdfIdle>());
    expect(key('pdf-strip'), findsNothing);
  });

  testWidgets('a share failure after ready shows «تعذّرت المشاركة»', (t) async {
    share.failure = const ShareFailure(ShareFailureKind.couldNotShare);
    await pump(t);
    job.start(1);
    await until(t, (s) => s is PdfReady);
    await t.pump();
    await t.tap(key('pdf-share'));
    await t.pump();
    await t.pump();
    expect(find.text('تعذّرت المشاركة'), findsOneWidget);
  });

  testWidgets(
    'preparing is announced to screen readers once, ready and failed as live messages',
    (t) async {
      final handle = t.ensureSemantics();
      renderer.gate = Completer<void>().future;
      await pump(t);
      job.start(2);
      await t.pump();
      expect(
        find.bySemanticsLabel(RegExp('جارٍ تجهيز سورة البقرة')),
        findsOneWidget,
      );
      unawaited(job.cancel());
      await t.pump();
      handle.dispose();
    },
  );
}
