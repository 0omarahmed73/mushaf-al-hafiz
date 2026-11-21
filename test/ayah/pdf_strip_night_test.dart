// The surah PDF strip in both looks, in its three states (spec FR-004, FR-012, FR-014; contracts/ui.md PDF strip).
// Emerald keeps its ivory card; Night draws a charcoal pill with the second accent for progress.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ui/pdf_progress_strip.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/theme.dart';

import '../support/contrast_walk.dart';
import '../support/fake_pdf.dart';
import '../support/fake_renderer.dart';
import '../support/fake_share.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  late FakePageRenderer renderer;
  late PdfJob job;

  setUp(() {
    renderer = FakePageRenderer();
    job = fakePdfJob(renderer);
  });
  tearDown(() => job.dispose());

  Future<void> pump(
    WidgetTester t,
    LookChoice look, {
    Size screen = const Size(412, 915),
    double textScale = 1.0,
  }) {
    t.view.physicalSize = screen;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    return t.pumpWidget(
      MaterialApp(
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
          body: Align(
            alignment: Alignment.bottomCenter,
            child: PdfProgressStrip(job: job, share: FakeShareService()),
          ),
        ),
      ),
    );
  }

  Future<void> until(WidgetTester t, bool Function(PdfJobState s) done) async {
    for (var i = 0; i < 400 && !done(job.state); i++) {
      await t.pump(const Duration(milliseconds: 10));
    }
    expect(done(job.state), isTrue, reason: '${job.state}');
  }

  /// Gets the job into [state] and the strip drawn for it.
  Future<void> reach(WidgetTester t, String state) async {
    switch (state) {
      case 'preparing':
        renderer.gate = Completer<void>().future;
        job.start(2);
        await t.pump();
      case 'ready':
        job.start(2);
        await until(t, (s) => s is PdfReady);
        await t.pump();
      case 'failed':
        renderer.failure = StateError('boom');
        job.start(2);
        await until(t, (s) => s is PdfFailed);
        await t.pump();
    }
  }

  Material strip(WidgetTester t) => t.widget<Material>(key('pdf-strip'));

  testWidgets(
    'Emerald: ivory card with a gold-dark border, radius 14, bar in gold-dark',
    (t) async {
      await pump(t, LookChoice.emerald);
      await reach(t, 'preparing');
      final card = strip(t);
      expect(card.color, AppColors.paper);
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.goldDark);
      expect(shape.borderRadius, BorderRadius.circular(14));
      final bar = t.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.color, AppColors.goldDark);
      expect(bar.backgroundColor, AppColors.greenLine);
      final title = t.widget<Text>(find.text('جارٍ تجهيز سورة البقرة'));
      expect(title.style!.color, AppColors.ink);
      final subtitle = t.widget<Text>(find.text('صفحة 1 من 48'));
      expect(subtitle.style!.color, const Color(0xFF2C4A3F));
      final cancel = t.widget<TextButton>(
        find.descendant(
          of: key('pdf-cancel'),
          matching: find.byType(TextButton),
        ),
      );
      expect(cancel.style!.foregroundColor!.resolve({}), AppColors.green);
    },
  );

  group('Night', () {
    testWidgets(
      'preparing: a charcoal pill, amber progress on the hairline, teal button',
      (t) async {
        await pump(t, LookChoice.night);
        await reach(t, 'preparing');
        final card = strip(t);
        expect(card.color, AppLook.night.cardFill);
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side.color, AppLook.night.cardBorderStrong);
        expect(shape.borderRadius, BorderRadius.circular(999));
        expect(t.getSize(key('pdf-strip')).height, 56);
        final bar = t.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.color, AppLook.night.accentAlt);
        expect(bar.backgroundColor, AppLook.night.line);
        final title = t.widget<Text>(find.text('جارٍ تجهيز سورة البقرة'));
        expect(title.style!.color, AppLook.night.cardInk);
        final subtitle = t.widget<Text>(find.text('صفحة 1 من 48'));
        expect(subtitle.style!.color, AppLook.night.cardMuted);
        final cancel = t.widget<TextButton>(
          find.descendant(
            of: key('pdf-cancel'),
            matching: find.byType(TextButton),
          ),
        );
        expect(
          cancel.style!.foregroundColor!.resolve({}),
          AppLook.night.doneFill,
        );
      },
    );

    for (final state in ['preparing', 'ready', 'failed']) {
      testWidgets(
        '$state: every text meets the contrast and the strip is 56 px',
        (t) async {
          await pump(t, LookChoice.night);
          await reach(t, state);
          expect(t.getSize(key('pdf-strip')).height, 56);
          final issues = contrastIssues(t);
          expect(issues, isEmpty, reason: issues.join('\n'));
        },
      );
    }
  });

  for (final look in LookChoice.values) {
    for (final state in ['preparing', 'ready', 'failed']) {
      testWidgets(
        '${look.name} $state: nothing overflows on 320 dp with a 2x font',
        (t) async {
          await pump(t, look, screen: const Size(320, 640), textScale: 2.0);
          await reach(t, state);
          expect(t.takeException(), isNull);
          expect(t.getSize(key('pdf-strip')).height, 56);
        },
      );
    }
  }
}
