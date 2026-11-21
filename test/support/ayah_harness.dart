import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:provider/provider.dart';

import 'fake_pdf.dart';
import 'fake_renderer.dart';
import 'fake_share.dart';
import 'map_bundle.dart';
import 'test_meta.dart';

/// Small ayah assets for surah 2 (nine ayahs) used by the sheet and view tests:
/// tafsir entries 1–5, 6–7 (two paragraphs) and 9; ayah 8 has none of its own; translations
/// «English verse N»; the Quran words of ayah N are «كلمةقرآنية N».
Map<String, String> viewFiles() => {
  'assets/ayah/text/002.json': jsonEncode({
    'surah': 2,
    'ayahs': [
      for (var a = 1; a <= 9; a++) ['كلمةقرآنية$a'],
    ],
  }),
  'assets/ayah/tafsir/002.json': jsonEncode({
    'surah': 2,
    'entries': [
      {'from': 1, 'to': 5, 'text': 'تفسير الآيات الأولى'},
      {'from': 6, 'to': 7, 'text': 'تفسير الآيتين\n\nفقرة ثانية'},
      {'from': 9, 'to': 9, 'text': 'تفسير التاسعة'},
    ],
    'without': [8],
  }),
  'assets/ayah/translation/002.json': jsonEncode({
    'surah': 2,
    'ayahs': [for (var a = 1; a <= 9; a++) 'English verse $a'],
  }),
  'assets/ayah/gharib/002.json': jsonEncode({
    'surah': 2,
    'ayahs': {
      '6': [
        {'w': 'كلمة', 'm': 'معنى الكلمة', 'b': 327},
        {'w': 'عبارة', 'm': 'معنى العبارة', 'b': 208},
      ],
    },
  }),
  'assets/ayah/sources.json': jsonEncode({
    'sources': [
      {
        'id': 327,
        'kind': 'gharib',
        'title': 'التبيان في تفسير غريب القرآن',
        'author': 'ابن الهائم',
        'provider': 'Quranpedia',
        'link': 'https://quranpedia.net/dumps',
        'version': '2026-11-14',
      },
      {
        'id': 208,
        'kind': 'gharib',
        'title': 'تذكرة الأريب في تفسير الغريب',
        'author': 'ابن الجوزي',
        'provider': 'Quranpedia',
        'link': 'https://quranpedia.net/dumps',
        'version': '2026-11-14',
      },
    ],
  }),
};

/// Opens [showAyahSheet] for [ref] over a bundle of [files] with a [FakeShareService].
class AyahHarness {
  AyahHarness({
    this.ref = const AyahRef(2, 6),
    this.page = 42,
    Map<String, String>? files,
    this.withPicture = true,
    this.withPdf = false,
    this.textSize,
  }) : files = files ?? viewFiles();

  final AyahRef ref;

  /// The page the menu is opened on.
  final int page;
  final Map<String, String> files;

  /// Whether the app has a page renderer (the picture row needs one).
  final bool withPicture;

  /// Whether the app has a surah PDF job (the PDF row needs one).
  final bool withPdf;

  /// The owner's text size; null means 100% (no setting in the app).
  final TextSizeSettings? textSize;
  late final PdfJob pdfJob = fakePdfJob(renderer);
  final FakeShareService share = FakeShareService();
  final FakePageRenderer renderer = FakePageRenderer();
  final MemoryShareFiles pictureFiles = MemoryShareFiles();
  int closed = 0;

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AyahRepository?>.value(
            value: AyahRepository(MapBundle(files)),
          ),
          Provider<ShareService?>.value(value: share),
          Provider<PageRenderer?>.value(value: withPicture ? renderer : null),
          Provider<TempShareFiles?>.value(
            value: withPicture ? pictureFiles : null,
          ),
          ListenableProvider<PdfJob?>.value(value: withPdf ? pdfJob : null),
          ListenableProvider<TextSizeSettings?>.value(value: textSize),
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
                      page: page,
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

  /// Taps the button, lets the sheet slide in.
  Future<void> open(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('open')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  /// Taps the row with [key] and lets the real asset futures and animations finish.
  Future<void> tapRow(WidgetTester t, String key) async {
    await t.tap(find.byKey(ValueKey(key)));
    await settleAsync(t);
  }
}

/// Lets futures that run in real time (assets, isolates) finish, with frames in between.
Future<void> settleAsync(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}
