import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/theme.dart';
import 'package:provider/provider.dart';

import '../support/fake_share.dart';
import '../support/map_bundle.dart';
import '../support/test_meta.dart';

/// Surah 2 with 255 ayahs: ayah 255 is «ٱللَّهُ لَآ إِلَٰهَ», the others one word.
Map<String, String> bundleFiles() => {
  'assets/ayah/text/002.json': jsonEncode({
    'surah': 2,
    'ayahs': [
      for (var a = 1; a < 255; a++) ['x$a'],
      ['ٱللَّهُ', 'لَآ', 'إِلَٰهَ'],
    ],
  }),
};

class Harness {
  Harness({this.ref = const AyahRef(2, 255)});

  final AyahRef ref;
  final FakeShareService share = FakeShareService();
  int closed = 0;

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AyahRepository?>.value(
            value: AyahRepository(MapBundle(bundleFiles())),
          ),
          Provider<ShareService?>.value(value: share),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  key: const ValueKey('open'),
                  onPressed: () async {
                    await showAyahSheet(
                      context,
                      ref: ref,
                      meta: testMeta(),
                      page: 42,
                    );
                    closed++;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('open')));
    await t.pump(); // the route is pushed
    await t.pump(const Duration(milliseconds: 500)); // the sheet has slid in
  }
}

Future<void> settleAsync(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'shows the surah name and ayah number in the header, in the heading font',
    (t) async {
      final h = Harness();
      await h.pump(t);
      await h.open(t);
      final header = find.text('سورة البقرة · آية 255');
      expect(header, findsOneWidget);
      expect(t.widget<Text>(header).style?.fontFamily, kHeadingFont);
    },
  );

  testWidgets(
    'has a «مشاركة» row at least 48 px tall that is a labelled button',
    (t) async {
      final h = Harness();
      await h.pump(t);
      await h.open(t);
      final row = find.byKey(const ValueKey('ayah-share'));
      expect(row, findsOneWidget);
      expect(t.getSize(row).height, greaterThanOrEqualTo(48));
      expect(
        find.descendant(of: row, matching: find.text('مشاركة')),
        findsOneWidget,
      );
      final semantics = t.getSemantics(
        find.descendant(of: row, matching: find.byType(InkWell)),
      );
      expect(semantics.label, contains('مشاركة'));
      expect(semantics.flagsCollection.isButton, isTrue);
    },
  );

  testWidgets(
    'tapping «مشاركة» hands exactly the two lines to the share service',
    (t) async {
      final h = Harness();
      await h.pump(t);
      await h.open(t);
      await t.tap(find.byKey(const ValueKey('ayah-share')));
      await settleAsync(t);
      expect(h.share.texts, ['﴿ ٱللَّهُ لَآ إِلَٰهَ ﴾\n[سورة البقرة: 255]']);
      expect(
        find.text('سورة البقرة · آية 255'),
        findsOneWidget,
        reason: 'the sheet stays open',
      );
    },
  );

  testWidgets('a dismissed share shows nothing', (t) async {
    final h = Harness()..share.outcome = ShareOutcome.dismissed;
    await h.pump(t);
    await h.open(t);
    await t.tap(find.byKey(const ValueKey('ayah-share')));
    await settleAsync(t);
    expect(h.share.texts, hasLength(1));
    expect(find.byKey(const ValueKey('ayah-status')), findsNothing);
  });

  testWidgets(
    'a share failure shows its Arabic message and the sheet stays usable',
    (t) async {
      final h = Harness()
        ..share.failure = const ShareFailure(ShareFailureKind.couldNotShare);
      await h.pump(t);
      await h.open(t);
      await t.tap(find.byKey(const ValueKey('ayah-share')));
      await settleAsync(t);
      expect(find.text('تعذّرت المشاركة'), findsOneWidget);
      expect(find.byKey(const ValueKey('ayah-share')), findsOneWidget);
      h.share.failure = null;
      await t.tap(find.byKey(const ValueKey('ayah-share')));
      await settleAsync(t);
      expect(h.share.texts, hasLength(1));
      expect(
        find.text('تعذّرت المشاركة'),
        findsNothing,
        reason: 'the message is cleared by the next action',
      );
    },
  );

  testWidgets(
    'closing the sheet (tap outside) completes showAyahSheet and nothing else changes',
    (t) async {
      final h = Harness();
      await h.pump(t);
      await h.open(t);
      expect(h.closed, 0);
      await t.tapAt(const Offset(200, 40)); // the barrier above the sheet
      await t.pumpAndSettle();
      expect(find.text('سورة البقرة · آية 255'), findsNothing);
      expect(h.closed, 1);
      expect(h.share.texts, isEmpty);
    },
  );

  testWidgets(
    'does not open when the app has no ayah data or share service (nothing to show)',
    (t) async {
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AyahRepository?>.value(value: null),
            Provider<ShareService?>.value(value: null),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const ValueKey('open'),
                  onPressed: () => showAyahSheet(
                    context,
                    ref: const AyahRef(1, 1),
                    meta: testMeta(),
                    page: 1,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const ValueKey('open')));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('ayah-share')), findsNothing);
    },
  );
}
