// The tafsir, translation and word meanings follow the owner's text size; their headers, the menu rows and
// everything else do not (spec FR-005, FR-006, SC-004).
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/ayah_harness.dart';

double? sizeOf(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.fontSize;

void main() {
  late AppDatabase db;
  late TextSizeSettings size;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    size = TextSizeSettings(WirdRepository(db));
  });
  tearDown(() async {
    size.dispose();
    await db.close();
  });

  Future<AyahHarness> open(
    WidgetTester t,
    int percent,
    String row, {
    Map<String, String>? files,
    bool useSetting = true,
  }) async {
    await t.runAsync(() => size.set(percent));
    final h = AyahHarness(textSize: useSetting ? size : null, files: files);
    await h.pump(t);
    await h.open(t);
    await h.tapRow(t, row);
    return h;
  }

  for (final (percent, factor) in [(150, 1.5), (80, 0.8)]) {
    testWidgets(
      'tafsir at $percent%: the panel text and its note scale, the header does not',
      (t) async {
        await open(t, percent, 'ayah-tafsir');
        expect(sizeOf(t, 'تفسير الآيتين'), closeTo(17 * factor, 1e-9));
        expect(sizeOf(t, 'فقرة ثانية'), closeTo(17 * factor, 1e-9));
        expect(
          sizeOf(t, 'يشمل التفسير الآيات 6–7'),
          closeTo(13 * factor, 1e-9),
        );
        expect(
          sizeOf(t, 'شرح بشري وليس من نص القرآن'),
          12,
          reason: 'the header note keeps its size',
        );
        expect(t.widget<Text>(find.text('تفسير السعدي')).style?.fontSize, 20);
      },
    );

    testWidgets(
      'translation at $percent%: the English text scales, the header does not',
      (t) async {
        await open(t, percent, 'ayah-translation');
        expect(sizeOf(t, 'English verse 6'), closeTo(17 * factor, 1e-9));
        expect(
          sizeOf(t, 'Saheeh International'),
          13,
          reason: 'the source line under the title keeps its size',
        );
        expect(t.widget<Text>(find.text('الترجمة')).style?.fontSize, 20);
      },
    );

    testWidgets(
      'meanings at $percent%: the word, its meaning and its source scale',
      (t) async {
        await open(t, percent, 'ayah-meanings');
        expect(sizeOf(t, 'كلمة'), closeTo(18 * factor, 1e-9));
        expect(sizeOf(t, 'معنى الكلمة'), closeTo(16 * factor, 1e-9));
        expect(
          sizeOf(t, 'ابن الهائم · التبيان في تفسير غريب القرآن'),
          closeTo(12 * factor, 1e-9),
        );
        expect(t.widget<Text>(find.text('معاني الكلمات')).style?.fontSize, 20);
      },
    );
  }

  testWidgets('the line that says an ayah has no difficult words scales too', (
    t,
  ) async {
    await open(t, 150, 'ayah-meanings', files: viewFilesWithout('gharib'));
    expect(sizeOf(t, 'لا توجد كلمات غريبة في هذه الآية'), closeTo(24, 1e-9));
  });

  testWidgets('the menu rows keep their size at 150%', (t) async {
    await t.runAsync(() => size.set(150));
    final h = AyahHarness(textSize: size);
    await h.pump(t);
    await h.open(t);
    final label = find.descendant(
      of: find.byKey(const ValueKey('ayah-tafsir')),
      matching: find.text('التفسير'),
    );
    expect(t.widget<Text>(label).style?.fontSize, 16);
  });

  testWidgets(
    'at 100%, and with no setting in the app, the views look exactly as before',
    (t) async {
      await open(t, 100, 'ayah-tafsir');
      expect(sizeOf(t, 'تفسير الآيتين'), 17);
      await t.pumpWidget(const SizedBox());
      await open(t, 100, 'ayah-translation', useSetting: false);
      expect(sizeOf(t, 'English verse 6'), 17);
    },
  );

  testWidgets('the longest text at 150% scrolls to its last line', (t) async {
    final paragraphs = [for (var i = 0; i < 60; i++) 'فقرة رقم $i'];
    final files = {
      ...viewFiles(),
      'assets/ayah/tafsir/002.json': jsonEncode({
        'surah': 2,
        'entries': [
          {'from': 1, 'to': 9, 'text': paragraphs.join('\n\n')},
        ],
        'without': [],
      }),
    };
    await open(t, 150, 'ayah-tafsir', files: files);
    expect(
      find.text('فقرة رقم 59').hitTestable(),
      findsNothing,
      reason: 'below the panel until it is scrolled to',
    );
    await t.dragUntilVisible(
      find.text('فقرة رقم 59'),
      find.byKey(const ValueKey('ayah-detail-body')),
      const Offset(0, -300),
    );
    expect(find.text('فقرة رقم 59'), findsOneWidget);
  });

  testWidgets(
    'a phone text scale of 3x with 150% is cut so that the result stays at 3x',
    (t) async {
      // A tall screen, so the menu itself has room at a 3x phone text scale.
      t.view.physicalSize = const Size(1200, 3600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      t.platformDispatcher.textScaleFactorTestValue = 3.0;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await open(t, 150, 'ayah-translation');
      final paragraph = t.renderObject<RenderParagraph>(
        find.text('English verse 6'),
      );
      expect(
        paragraph.textScaler.scale(10),
        20,
        reason: 'system 2.0 x size 1.5 = 3.0',
      );
      await t.pumpWidget(const SizedBox());
      await open(t, 100, 'ayah-translation');
      final plain = t.renderObject<RenderParagraph>(
        find.text('English verse 6'),
      );
      expect(
        plain.textScaler.scale(10),
        30,
        reason: 'at 100% the phone setting is untouched',
      );
    },
  );
}

/// The ayah files with the [kind] data of surah 2 emptied (no difficult words).
Map<String, String> viewFilesWithout(String kind) => {
  ...viewFiles(),
  'assets/ayah/$kind/002.json': jsonEncode({'surah': 2, 'ayahs': {}}),
};
