import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/pdf/pdf_job.dart';

import '../support/ayah_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets(
    'the menu has «مشاركة السورة PDF» under «الصفحة والسورة», a button at least 48 px tall',
    (t) async {
      final h = AyahHarness(withPdf: true);
      await h.pump(t);
      await h.open(t);
      expect(key('ayah-surah-pdf'), findsOneWidget);
      expect(t.getSize(key('ayah-surah-pdf')).height, greaterThanOrEqualTo(48));
      expect(
        find.descendant(
          of: key('ayah-surah-pdf'),
          matching: find.text('مشاركة السورة PDF'),
        ),
        findsOneWidget,
      );
      expect(find.text('الصفحة والسورة'), findsOneWidget);
    },
  );

  testWidgets('without a PDF job the row is not offered', (t) async {
    final h = AyahHarness();
    await h.pump(t);
    await h.open(t);
    expect(key('ayah-surah-pdf'), findsNothing);
    expect(key('ayah-page-picture'), findsOneWidget);
  });

  testWidgets(
    'tapping it starts the PDF of the ayah\'s surah and closes the menu',
    (t) async {
      final h = AyahHarness(withPdf: true);
      h.renderer.gate = Completer<void>().future;
      await h.pump(t);
      await h.open(t);
      await t.tap(key('ayah-surah-pdf'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      final state = h.pdfJob.state;
      expect(state, isA<PdfPreparing>());
      expect((state as PdfPreparing).surahName, 'البقرة');
      expect(state.total, 48);
      expect(
        find.text('سورة البقرة · آية 6'),
        findsNothing,
        reason: 'the menu closed',
      );
      expect(h.closed, 1);
      unawaited(h.pdfJob.cancel());
    await t.pump();
    },
  );

  testWidgets(
    'while a job is preparing the row is off and says «يتم تجهيز ملف الآن»',
    (t) async {
      final h = AyahHarness(withPdf: true);
      h.renderer.gate = Completer<void>().future;
      h.pdfJob.start(1);
      await h.pump(t);
      await h.open(t);
      expect(find.text('يتم تجهيز ملف الآن'), findsOneWidget);
      await t.tap(key('ayah-surah-pdf'));
      await t.pump(const Duration(milliseconds: 300));
      expect(
        (h.pdfJob.state as PdfPreparing).surahName,
        'الفاتحة',
        reason: 'the running job is untouched',
      );
      expect(
        find.text('سورة البقرة · آية 6'),
        findsOneWidget,
        reason: 'the menu stays',
      );
      unawaited(h.pdfJob.cancel());
    await t.pump();
    },
  );

  testWidgets('the picture row still works while a PDF is being prepared', (
    t,
  ) async {
    final h = AyahHarness(withPdf: true, page: 5);
    h.renderer.gate = Completer<void>().future;
    h.pdfJob.start(2);
    await h.pump(t);
    await h.open(t);
    await h.tapRow(t, 'ayah-page-picture');
    expect(h.renderer.pictured, [5]);
    unawaited(h.pdfJob.cancel());
    await t.pump();
  });
}
