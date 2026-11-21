// The ayah menu and its three views in both looks (spec FR-004, FR-005, FR-012, FR-014; contracts/ui.md ayah menu).
// Emerald keeps its ivory rows and panels; Night wears charcoal ones on the dark sheet.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/ayah/ui/reading_text.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:provider/provider.dart';

import '../support/ayah_harness.dart' show settleAsync, viewFiles;
import '../support/contrast_walk.dart';
import '../support/fake_pdf.dart';
import '../support/fake_renderer.dart';
import '../support/fake_share.dart';
import '../support/map_bundle.dart';
import '../support/test_meta.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// The menu of 2:6 opened over a page in [look] on a [screen]-sized window with a system text scale.
Future<void> openSheet(
  WidgetTester t,
  LookChoice look, {
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final renderer = FakePageRenderer();
  await t.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AyahRepository?>.value(
          value: AyahRepository(MapBundle(viewFiles())),
        ),
        Provider<ShareService?>.value(value: FakeShareService()),
        Provider<PageRenderer?>.value(value: renderer),
        Provider<TempShareFiles?>.value(value: MemoryShareFiles()),
        ListenableProvider<PdfJob?>.value(value: fakePdfJob(renderer)),
        ListenableProvider<TextSizeSettings?>.value(value: null),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildAppTheme(look: look.look),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: const ValueKey('open'),
                onPressed: () => showAyahSheet(
                  context,
                  ref: const AyahRef(2, 6),
                  meta: testMeta(),
                  page: 42,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(key('open'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

Material rowMaterial(WidgetTester t, String k) => t.widget<Material>(
  find.descendant(of: key(k), matching: find.byType(Material)).first,
);

/// The panel behind the reading text of a view.
BoxDecoration panel(WidgetTester t) =>
    t
            .widget<DecoratedBox>(
              find
                  .ancestor(
                    of: key('ayah-detail-body'),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Future<void> openView(WidgetTester t, String row) async {
  // On a small phone with large text the menu scrolls: bring the row into view first.
  await t.ensureVisible(key(row));
  await t.pump();
  await t.tap(key(row));
  await settleAsync(t);
}

/// Every block drawn in a bright colour (an ivory card on a dark page).
List<Color> brightBlocks(WidgetTester t) => [
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox)))
    if ((d.decoration as BoxDecoration).color case final c?
        when c.computeLuminance() > 0.5)
      c,
  for (final m in t.widgetList<Material>(find.byType(Material)))
    if (m.color case final c? when c.computeLuminance() > 0.5) c,
];

const views = {
  'ayah-tafsir': 'تفسير السعدي',
  'ayah-translation': 'الترجمة',
  'ayah-meanings': 'معاني الكلمات',
};

void main() {
  group('Emerald stays as it was', () {
    testWidgets('green sheet, ivory rows with their radius, gold heading', (
      t,
    ) async {
      await openSheet(t, LookChoice.emerald);
      expect(
        t.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
        AppColors.green,
      );
      final row = rowMaterial(t, 'ayah-share');
      expect(row.color, AppColors.paper);
      final shape = row.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(14));
      expect(shape.side.color, const Color(0xFFCDBE8E));
      final heading = t.widget<Text>(find.textContaining('آية 6'));
      expect(heading.style!.color, AppColors.gold);
    });

    testWidgets('the reading panel is ivory with a gold-dark border', (
      t,
    ) async {
      await openSheet(t, LookChoice.emerald);
      await openView(t, 'ayah-tafsir');
      final p = panel(t);
      expect(p.color, AppColors.paper);
      expect((p.border as Border).top.color, AppColors.goldDark);
      expect(p.borderRadius, BorderRadius.circular(14));
    });
  });

  group('Night', () {
    testWidgets(
      'dark sheet, charcoal rows with a hairline and radius 20, light heading',
      (t) async {
        await openSheet(t, LookChoice.night);
        expect(
          t.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
          AppLook.night.background,
        );
        final row = rowMaterial(t, 'ayah-share');
        expect(row.color, AppLook.night.cardFill);
        final shape = row.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(20));
        expect(shape.side.color, AppLook.night.cardBorder);
        final heading = t.widget<Text>(find.textContaining('آية 6'));
        expect(heading.style!.color, AppLook.night.heading);
        expect(brightBlocks(t), isEmpty);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('the menu passes the contrast walk', (t) async {
      await openSheet(t, LookChoice.night);
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });

    for (final v in views.entries) {
      testWidgets('${v.value}: charcoal panel, no bright block, contrast met', (
        t,
      ) async {
        await openSheet(t, LookChoice.night);
        await openView(t, v.key);
        final p = panel(t);
        expect(p.color, AppLook.night.cardFill);
        expect((p.border as Border).top.color, AppLook.night.cardBorderStrong);
        expect(p.borderRadius, BorderRadius.circular(20));
        expect(
          t.widget<Text>(find.text(v.value)).style!.color,
          AppLook.night.heading,
        );
        expect(brightBlocks(t), isEmpty);
        final issues = contrastIssues(t);
        expect(issues, isEmpty, reason: issues.join('\n'));
      });
    }

    testWidgets('the meanings divider is the card divider', (t) async {
      await openSheet(t, LookChoice.night);
      await openView(t, 'ayah-meanings');
      final divider = t.widget<Divider>(find.byType(Divider).first);
      expect(divider.color, AppLook.night.cardDivider);
    });
  });

  group('parts on their own', () {
    Future<void> pumpPart(WidgetTester t, LookChoice look, Widget part) =>
        t.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(look: look.look),
            themeAnimationDuration: Duration.zero,
            home: Scaffold(body: part),
          ),
        );

    testWidgets(
      'a disabled row and its subtitle use the card\'s quiet colours',
      (t) async {
        for (final look in LookChoice.values) {
          await pumpPart(
            t,
            look,
            const SheetRow(
              icon: Icons.share_outlined,
              label: 'مشاركة',
              subtitle: 'يتم تجهيز ملف الآن',
              onTap: null,
            ),
          );
          final icon = t.widget<Icon>(find.byType(Icon));
          expect(icon.color, look.look.cardDisabled, reason: look.name);
          final subtitle = t.widget<Text>(find.text('يتم تجهيز ملف الآن'));
          expect(subtitle.style!.color, look.look.cardMuted, reason: look.name);
        }
      },
    );

    testWidgets('the status line is a card with the strong border', (t) async {
      for (final look in LookChoice.values) {
        await pumpPart(t, look, const StatusLine(message: 'تعذّر'));
        final box =
            t
                    .widget<DecoratedBox>(
                      find
                          .ancestor(
                            of: find.text('تعذّر'),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(box.color, look.look.cardFill, reason: look.name);
        expect(
          (box.border as Border).top.color,
          look.look.cardBorderStrong,
          reason: look.name,
        );
        expect(
          box.borderRadius,
          BorderRadius.circular(look.look.rowRadius(12)),
          reason: look.name,
        );
      }
    });

    testWidgets('the quiet reading text follows the card\'s muted colour', (
      t,
    ) async {
      for (final look in LookChoice.values) {
        late ReadingStyles styles;
        await pumpPart(
          t,
          look,
          Builder(
            builder: (context) {
              styles = ReadingScope.of(context);
              return const SizedBox();
            },
          ),
        );
        expect(styles.note.color, look.look.cardMuted, reason: look.name);
        expect(styles.source.color, look.look.cardMuted, reason: look.name);
      }
    });
  });

  for (final look in LookChoice.values) {
    testWidgets(
      '${look.name}: the menu and the views do not overflow on 320 dp with a 2x font',
      (t) async {
        await openSheet(t, look, screen: const Size(320, 640), textScale: 2.0);
        expect(t.takeException(), isNull, reason: 'menu');
        for (final v in views.keys) {
          await openView(t, v);
          expect(t.takeException(), isNull, reason: v);
          await t.tap(key('ayah-back'));
          await t.pump(const Duration(milliseconds: 300));
        }
      },
    );
  }
}
