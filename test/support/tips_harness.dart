// Shared by the first-run tips tests (feature 008): pumps the tips dialog, or the gate, in either look, on a given screen
// and system text scale, and finds the parts the tests talk about.
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/models.dart' show MushafMeta;
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/onboarding/tips_store.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/onboarding/tip_steps.dart';
import 'package:mushaf/onboarding/tips_dialog.dart';
import 'package:mushaf/onboarding/tips_gate.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'fake_pdf.dart';
import 'fake_renderer.dart';
import 'fake_share.dart';
import 'reader_harness.dart' show settleReader;

Finder key(String k) => find.byKey(ValueKey(k));

/// What the launcher heard from the dialog it opened.
class TipsProbe {
  /// The route's result; null until it closes, and null when it closed without one.
  TipsOutcome? outcome;

  /// True once the dialog's route has completed.
  bool closed = false;
}

/// Lets the dialog's open and close transitions and any slide finish without `pumpAndSettle` (the long-press ring
/// repeats for ever, so the tree never settles while step 1 is shown).
Future<void> settleTips(WidgetTester t, {int ms = 800}) async {
  await t.pump();
  // In steps, so a change that a frame causes (a dot resizing after the page changed) gets its own frames to run.
  for (var elapsed = 0; elapsed < ms; elapsed += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// A launcher screen with one button, `open-tips`, which opens [TipsDialog] with `showDialog` the way the gate does
/// (`barrierDismissible: false`) and records the result in the returned probe; then taps it.
///
/// [arabic] false builds an app with no locale at all (left-to-right), to prove the dialog is right-to-left by itself.
Future<TipsProbe> pumpTipsDialog(
  WidgetTester t, {
  AppLook look = AppLook.emerald,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
  bool disableAnimations = false,
  bool arabic = true,
  bool open = true,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final probe = TipsProbe();
  await t.pumpWidget(
    MaterialApp(
      locale: arabic ? const Locale('ar') : null,
      supportedLocales: arabic ? const [Locale('ar')] : const [Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(look: look),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: const ValueKey('open-tips'),
              onPressed: () async {
                probe.outcome = await showDialog<TipsOutcome>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const TipsDialog(),
                );
                probe.closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  if (open) {
    await t.tap(key('open-tips'));
    await settleTips(t);
  }
  return probe;
}

/// The widths of the six dots; the current one is the wide one.
List<double> dotWidths(WidgetTester t) => [
  for (var i = 0; i < kTipSteps.length; i++)
    t.getSize(key('tips-dot-$i')).width,
];

/// The step the dots say is shown (0-based), after the slide has finished.
int currentStep(WidgetTester t) {
  final widths = dotWidths(t);
  final widest = widths.reduce((a, b) => a > b ? a : b);
  return widths.indexOf(widest);
}

Finder get nextButton => key('tips-next');
Finder get skipButton => key('tips-skip');
Finder get startButton => key('tips-start');

/// Taps «التالي» and lets the slide finish.
Future<void> tapNext(WidgetTester t) async {
  await t.tap(nextButton);
  await settleTips(t);
}

/// The system back, as a tap on the phone's back button (or a back gesture) would send it.
Future<void> systemBack(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await settleTips(t);
}

// ------------------------------------------------------------------------------------------------ the gate

/// The key of the placeholder the gate shows as its child.
const String kReaderPlaceholder = 'reader-placeholder';

/// An in-memory database and its repository, closed when the test ends (the widgets are unmounted first so nothing
/// listens, then the clock is moved so drift's timers fire, then the database is closed for real).
Future<WirdRepository> openTipsRepository(
  WidgetTester t, {
  WirdRepository Function(AppDatabase db)? make,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  return make?.call(db) ?? WirdRepository(db);
}

/// The app's own `MushafApp` around `TipsGate(child: a placeholder)`, on [repo].
///
/// A different [gateKey] builds a new `TipsGate` state under the same navigator (the app rebuilt around an open popup).
Widget tipsGateApp(
  WirdRepository repo, {
  bool enabled = true,
  AppLook look = AppLook.emerald,
  Widget? child,
  Key? gateKey,
}) => MushafApp(
  wirdRepository: repo,
  mushafRepository: MushafRepository(rootBundle),
  home: TipsGate(
    key: gateKey,
    enabled: enabled,
    child:
        child ??
        const Scaffold(
          body: Center(
            child: Text('reader', key: ValueKey(kReaderPlaceholder)),
          ),
        ),
  ),
);

/// Lets the gate's post-frame check, its one query and the route's transition finish. Drift and the check run outside
/// the fake clock, so real time passes in between.
Future<void> settleGate(WidgetTester t, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// A phone-sized window.
void tipsPhoneScreen(WidgetTester t, {Size size = const Size(412, 915)}) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// Walks the six steps with «التالي» and finishes with «ابدأ».
Future<void> finishTips(WidgetTester t) async {
  for (var i = 1; i < kTipSteps.length; i++) {
    await tapNext(t);
  }
  await t.tap(startButton);
  await settleGate(t, rounds: 4);
}

// ---------------------------------------------------------------------------------------- the real reader

/// The real reader under a [TipsGate], and the fakes it was given.
class TipsReader {
  TipsReader(this.repo, this.mushaf, this.share, this.renderer);

  final WirdRepository repo;
  final MushafRepository mushaf;
  final FakeShareService share;
  final FakePageRenderer renderer;
}

/// `MushafApp(home: TipsGate(child: ReaderScreen()))` on a real page [startPage], with the ayah texts, a share service,
/// a page renderer and a PDF job (all fakes without a disk), so the ayah menu has every row. [seen] stores the flag first,
/// so the popup does not cover the reader; false leaves the database empty of it.
Future<TipsReader> pumpTipsReader(
  WidgetTester t, {
  int startPage = 42,
  bool seen = true,
  Size screen = const Size(412, 915),
}) async {
  tipsPhoneScreen(t, size: screen);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final repo = WirdRepository(db);
  final size = TextSizeSettings(repo);
  addTearDown(size.dispose);
  final look = AppLookSettings(repo);
  addTearDown(look.dispose);
  final mushaf = MushafRepository(rootBundle);
  final renderer = FakePageRenderer();
  final share = FakeShareService();
  late final MushafMeta meta;
  await t.runAsync(() async {
    meta = await mushaf.loadMeta();
    for (var p = startPage - 2; p <= startPage + 2; p++) {
      if (p >= 1 && p <= 604) await mushaf.loadPage(p);
    }
    await repo.ensureDefaults();
    await repo.setPage((await repo.activeWird())!.id, startPage);
    if (seen) await repo.writeSetting(kTipsSeenKey, 'true');
    await look.load();
  });
  final files = MemoryShareFiles();
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: AyahRepository(rootBundle),
      shareService: share,
      pageRenderer: renderer,
      tempShareFiles: files,
      pdfJob: PdfJob(
        renderer: renderer,
        files: files,
        meta: meta,
        writerFactory: (file, {required title, required pageCount}) =>
            NoDiskPdfWriter(file, title: title, pageCount: pageCount),
      ),
      textSize: size,
      appLook: look,
      home: const TipsGate(child: ReaderScreen()),
    ),
  );
  await settleReader(t);
  return TipsReader(repo, mushaf, share, renderer);
}
