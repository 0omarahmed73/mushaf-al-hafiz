// Feature 010 T021 and T022 (FR-008, FR-009, SC-004): no motion of the bars or of the «ملخص اليوم» card moves the Mushaf
// page, not even by 0 px. The pager and every line and word of the page are read before the motion and again in every
// 16 ms frame of it, on pages 1, 2, 50, 293 and 604 (the two special openings, two ordinary pages and the last).
// T032 adds the jump to this file.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_pdf.dart';
import '../support/fake_renderer.dart';
import '../support/fake_share.dart';
import '../support/motion_geometry.dart';
import '../support/motion_harness.dart';

const _pages = [1, 2, 50, 293, 604];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final page in _pages) {
    testWidgets('page $page: the bars leaving and coming back move nothing', (
      t,
    ) async {
      await pumpMotionReader(t, startPage: page, withWird: false);
      final before = pageRects(t);
      expect(
        before.length,
        greaterThan(10),
        reason: 'the pager, the lines and the words were read',
      );
      final centre = t.getCenter(find.byType(PageView));
      await t.tapAt(centre);
      await expectRectsStable(t, before, reason: 'page $page, bars leaving');
      expect(find.byKey(const ValueKey('top-bar')), findsNothing);
      await t.tapAt(centre);
      await expectRectsStable(t, before, reason: 'page $page, bars arriving');
      expect(find.byKey(const ValueKey('top-bar')), findsOneWidget);
    });

    testWidgets(
      'page $page: the today card opening and closing moves nothing',
      (t) async {
        await pumpMotionReader(t, startPage: page, withWird: true);
        final before = pageRects(t);
        expect(before.length, greaterThan(10));
        await t.tap(find.byKey(const ValueKey('today-chip')));
        await expectRectsStable(t, before, reason: 'page $page, card arriving');
        expect(find.byKey(const ValueKey('today-card')), findsOneWidget);
        await t.tap(find.byKey(const ValueKey('today-close')));
        await expectRectsStable(t, before, reason: 'page $page, card leaving');
        expect(find.byKey(const ValueKey('today-card')), findsNothing);
      },
    );
  }

  testWidgets(
    'the bars and the card together: the card open while the bars leave and come back moves nothing',
    (t) async {
      await pumpMotionReader(t, startPage: 293, withWird: true);
      final before = pageRects(t);
      await t.tap(find.byKey(const ValueKey('today-chip')));
      await expectRectsStable(t, before, reason: 'card arriving');
      // A tap outside the card closes it (the modal barrier); the next tap on the page hides the bars.
      await t.tapAt(const Offset(206, 700));
      await expectRectsStable(
        t,
        before,
        reason: 'card closed by a tap outside',
      );
      await t.tapAt(const Offset(206, 700));
      await expectRectsStable(t, before, reason: 'bars leaving');
      await t.tapAt(const Offset(206, 700));
      await expectRectsStable(t, before, reason: 'bars arriving');
    },
  );

  testWidgets(
    'the surah PDF strip moves with the bottom bar (its duration, not a jump) and the page does not move',
    (t) async {
      t.view.physicalSize = const Size(412, 915);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
        await t.runAsync(db.close);
      });
      final repo = WirdRepository(db);
      final mushaf = MushafRepository(rootBundle);
      await t.runAsync(() async {
        await mushaf.loadMeta();
        for (var p = 49; p <= 51; p++) {
          await mushaf.loadPage(p);
        }
        await repo.ensureDefaults();
        await repo.setPage((await repo.activeWird())!.id, 50);
      });
      final job = fakePdfJob(
        FakePageRenderer()..gate = Completer<void>().future,
      )..start(2);
      addTearDown(job.dispose);
      await t.pumpWidget(
        MushafApp(
          wirdRepository: repo,
          mushafRepository: mushaf,
          ayahRepository: AyahRepository(rootBundle),
          shareService: FakeShareService(),
          pdfJob: job,
          home: const ReaderScreen(),
        ),
      );
      await settleMotion(t, rounds: 16);

      final strip = find.byKey(const ValueKey('pdf-strip'));
      double bottomGap() => 915 - t.getRect(strip).bottom;
      expect(strip, findsOneWidget);
      expect(bottomGap(), 76, reason: '68 dp bar and the 8 dp margin');
      final before = pageRects(t);
      final centre = t.getCenter(find.byType(PageView));

      await t.tapAt(centre);
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(
        bottomGap(),
        allOf(greaterThan(8), lessThan(76)),
        reason: 'the strip is on its way down while the bar fades (no jump)',
      );
      await t.pump(const Duration(milliseconds: 150));
      expect(bottomGap(), 8, reason: 'bars gone: the strip is at the edge');
      await expectRectsStable(t, before, reason: 'bars leaving with the strip');

      await t.tapAt(centre);
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(bottomGap(), allOf(greaterThan(8), lessThan(76)));
      await t.pump(const Duration(milliseconds: 160));
      expect(bottomGap(), 76, reason: 'bars back: the strip is above the bar');
      await expectRectsStable(
        t,
        before,
        reason: 'bars arriving with the strip',
      );
      unawaited(job.cancel());
    },
  );
}
