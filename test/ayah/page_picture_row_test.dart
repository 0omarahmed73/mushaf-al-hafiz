import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/share_service.dart';

import '../support/ayah_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets(
    'the menu has «مشاركة الصفحة كصورة» under its own group label, a button at least 48 px tall',
    (t) async {
      final h = AyahHarness();
      await h.pump(t);
      await h.open(t);
      expect(key('ayah-page-picture'), findsOneWidget);
      expect(
        t.getSize(key('ayah-page-picture')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        find.descendant(
          of: key('ayah-page-picture'),
          matching: find.text('مشاركة الصفحة كصورة'),
        ),
        findsOneWidget,
      );
      expect(find.text('الصفحة والسورة'), findsOneWidget);
    },
  );

  testWidgets('without a page renderer the row is not offered', (t) async {
    final h = AyahHarness(withPicture: false);
    await h.pump(t);
    await h.open(t);
    expect(key('ayah-page-picture'), findsNothing);
    expect(key('ayah-share'), findsOneWidget);
  });

  testWidgets(
    'tapping it renders the page the menu was opened on and hands one PNG to the share sheet',
    (t) async {
      final h = AyahHarness(page: 293);
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-page-picture');
      expect(h.renderer.pictured, [293]);
      final shared = h.share.files.single;
      expect(
        (shared.fileName, shared.mimeType),
        ('مصحف - صفحة 293.png', 'image/png'),
      );
      expect(h.pictureFiles.written.values.single, h.renderer.bytes);
      expect(key('ayah-status'), findsNothing);
      expect(
        find.text('سورة البقرة · آية 6'),
        findsOneWidget,
        reason: 'the sheet stays open',
      );
    },
  );

  testWidgets(
    'says «جارٍ تجهيز الصورة» while a slow render runs, and a second tap does nothing',
    (t) async {
      final h = AyahHarness();
      h.renderer.delay = const Duration(seconds: 2);
      await h.pump(t);
      await h.open(t);
      await t.tap(key('ayah-page-picture'));
      await t.pump(const Duration(milliseconds: 700));
      expect(find.text('جارٍ تجهيز الصورة'), findsOneWidget);
      await t.tap(key('ayah-page-picture'), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(h.renderer.pictured, hasLength(1));
      await t.pump(const Duration(seconds: 3));
      await settleAsync(t);
      expect(find.text('جارٍ تجهيز الصورة'), findsNothing);
      expect(h.share.files, hasLength(1));
    },
  );

  testWidgets('a quick render shows no «جارٍ تجهيز الصورة»', (t) async {
    final h = AyahHarness();
    await h.pump(t);
    await h.open(t);
    await h.tapRow(t, 'ayah-page-picture');
    expect(find.text('جارٍ تجهيز الصورة'), findsNothing);
  });

  for (final (name, setup, message)
      in <(String, void Function(AyahHarness), String)>[
        (
          'no room to write',
          (h) => h.pictureFiles.diskFull = true,
          'لا توجد مساحة كافية على الهاتف لتجهيز الملف',
        ),
        (
          'a render failure',
          (h) => h.renderer.failure = const ShareFailure(
            ShareFailureKind.couldNotPrepare,
          ),
          'تعذّر تجهيز الملف',
        ),
        (
          'a failing share sheet',
          (h) => h.share.failure = const ShareFailure(
            ShareFailureKind.couldNotShare,
          ),
          'تعذّرت المشاركة',
        ),
      ]) {
    testWidgets('$name shows its Arabic message and the sheet keeps working', (
      t,
    ) async {
      final h = AyahHarness();
      setup(h);
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-page-picture');
      expect(find.text(message), findsOneWidget);
      expect(key('ayah-page-picture'), findsOneWidget);
      expect(key('ayah-share'), findsOneWidget);
    });
  }

  testWidgets('closing the share sheet without sharing shows no message', (
    t,
  ) async {
    final h = AyahHarness();
    h.share.outcome = ShareOutcome.dismissed;
    await h.pump(t);
    await h.open(t);
    await h.tapRow(t, 'ayah-page-picture');
    expect(key('ayah-status'), findsNothing);
  });
}
