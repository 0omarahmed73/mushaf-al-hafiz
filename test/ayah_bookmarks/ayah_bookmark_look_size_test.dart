// The new widgets of the ayah bookmark in both looks, at every size (feature 013, task T041; spec FR-017, SC-006, SC-007;
// contracts/ui.md "Accessibility summary"): the ayah sheet's two rows in both states, the note field (its two lines and its
// failure line), an ayah row and a page row of «علامات», and the Settings switch, through the real reader, in Emerald & Gold
// and Night Reader, at 80, 100 and 150 percent, at 412 x 915 and at 320 x 640 with a 2x system font, portrait and
// landscape. Nothing overflows (the bottom bar's known overflow at 320 dp aside), every target is 48 x 48 at least and
// inside the screen, every text and icon reaches 4.5:1, and a look change is followed at once.
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/ayah_tint_settings.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/ayah_bookmark_change.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/ayah_bookmark_harness.dart'
    show ayahBookmarkRow, ayahNoteRow, byKey, seedAyahBookmark;
import '../support/contrast_walk.dart';
import '../support/fake_share.dart';

const baqarah282 = AyahRef(2, 282);
const surah = 'البقرة';

/// A surah with a long name, for the list's ayah row.
const munafiqun11 = AyahRef(63, 11);

/// A note longer than one line of the sheet's row on any of the screens.
const longNote =
    'أراجع هذه الآية مع الحفظ كل يوم بعد صلاة الفجر ثم أكررها في المساء قبل النوم حتى تثبت';

final Finder noteField = byKey('ayah-note-field');
final Finder noteCancel = byKey('ayah-note-cancel');
final Finder noteSave = byKey('ayah-note-save');
final Finder noteDialog = find.byType(AlertDialog);
final Finder tintSwitch = byKey('ayah-tint-switch');
final Finder bookmarkList = byKey('bookmark-list');

class ScreenCase {
  const ScreenCase(this.size, this.textScale);
  final Size size;
  final double textScale;

  @override
  String toString() =>
      '${size.width.toInt()} x ${size.height.toInt()}${textScale == 1 ? '' : ' with a ${textScale.toInt()}x system font'}';
}

/// The usual phone and the narrowest one with a 2x system font, each upright and on its side.
const screens = [
  ScreenCase(Size(412, 915), 1.0),
  ScreenCase(Size(915, 412), 1.0),
  ScreenCase(Size(320, 640), 2.0),
  ScreenCase(Size(640, 320), 2.0),
];
const percents = [80, 100, 150];

/// A repository whose note save always fails (the note field's failure line).
class FailingNoteRepo extends WirdRepository {
  FailingNoteRepo(super.db);

  @override
  Future<AyahBookmarkChange?> saveAyahNote(
    AyahRef ref, {
    required int page,
    int? wirdId,
    String? note,
  }) async => throw StateError('disk full');
}

/// What a test needs once the reader is shown.
class Shown {
  Shown(this.db, this.mushaf, this.meta, this.look, this.errors);

  final AppDatabase db;
  final MushafRepository mushaf;
  final MushafMeta meta;
  final AppLookSettings look;

  /// Every Flutter error reported while the app ran.
  final List<String> errors;

  /// The errors that are not an overflow of the reader's own bars or of the Mushaf page's own lines. Those are not this
  /// test's subject and are older than this feature: at 320 dp the bottom bar overflows, and with a 2x system font the
  /// bars and the page's text do (features 001 and 002; feature 006 T020).
  List<String> get unexpectedErrors => [
    for (final e in errors)
      if (!(e.contains('overflowed') &&
          (e.contains('_BottomBar') ||
              e.contains('lib/mushaf/reader_screen.dart') ||
              e.contains('lib/mushaf/mushaf_page.dart'))))
        e,
  ];
}

/// Real time for the database and the assets, then a frame, until [f] is there (or [gone]); then the slide or fade that
/// brought it finishes.
Future<void> waitFor(WidgetTester t, Finder f, {bool gone = false}) async {
  for (var i = 0; i < 150; i++) {
    if (f.evaluate().isEmpty == gone) break;
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(f, gone ? findsNothing : findsWidgets);
  await t.pump(const Duration(milliseconds: 600));
  await t.pump();
}

/// The reader on page 48 (the whole page is 2:282) following the default wird, with the look, the reading size and the
/// tint switch provided as the app provides them. Seeded: a page bookmark on page 77 with a note and an ayah bookmark on
/// 63:11 with a note, both of the wird. The system font scale is the platform's, so sheets and dialogs get it too.
Future<Shown> pumpReader(
  WidgetTester t, {
  required LookChoice look,
  required ScreenCase screen,
  int percent = 100,
  bool failingNotes = false,
}) async {
  t.view.physicalSize = screen.size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  if (screen.textScale != 1.0) {
    t.platformDispatcher.textScaleFactorTestValue = screen.textScale;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final errors = <String>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString(minLevel: DiagnosticLevel.debug);
    errors.add(text);
    if (!(details.exception is FlutterError && text.contains('overflowed'))) {
      previousOnError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previousOnError);
  final db = AppDatabase(NativeDatabase.memory());
  final repo = failingNotes ? FailingNoteRepo(db) : WirdRepository(db);
  final size = TextSizeSettings(repo);
  final lookSettings = AppLookSettings(repo);
  final tint = AyahTintSettings(repo);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    size.dispose();
    lookSettings.dispose();
    tint.dispose();
    await t.runAsync(db.close);
  });
  final mushaf = MushafRepository(rootBundle);
  late MushafMeta meta;
  late int firstWord;
  await t.runAsync(() async {
    meta = await mushaf.loadMeta();
    // Loaded in real time first: rootBundle remembers the Future of a load started in the fake-async zone.
    for (var p = 46; p <= 51; p++) {
      await mushaf.loadPage(p);
    }
    firstWord = _firstWordOf(await mushaf.loadPage(48), baqarah282);
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    await repo.setPage(id, 48);
    await size.set(percent);
    await tint.load();
    await repo.addBookmark(77, 'صفحة للمراجعة', wirdId: id);
    await seedAyahBookmark(
      db,
      meta,
      munafiqun11,
      wirdId: id,
      note: 'ملاحظة',
      at: DateTime(2026, 11, 1, 8),
    );
    if (look != LookChoice.emerald) await lookSettings.set(look);
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: AyahRepository(rootBundle),
      shareService: FakeShareService(),
      textSize: size,
      ayahTint: tint,
      appLook: lookSettings,
      home: const ReaderScreen(),
    ),
  );
  await waitFor(t, byKey('w$firstWord'));
  return Shown(db, mushaf, meta, lookSettings, errors);
}

int _firstWordOf(PageData page, AyahRef ref) {
  final ids = wordIdsOfAyah(page, ref).toList()..sort();
  return ids.first;
}

/// Long presses a word of 2:282 that a finger can reach (the first one; with a 2x system font the page's lines run off
/// their box, so the first one a touch lands on) and waits for the sheet's bookmark row.
Future<void> openSheet(WidgetTester t, Shown s) async {
  final page = (await t.runAsync(() => s.mushaf.loadPage(48)))!;
  final ids = wordIdsOfAyah(page, baqarah282).toList()..sort();
  bool reachable(int id) {
    final word = byKey('w$id');
    if (word.evaluate().isEmpty) return false;
    final box = t.renderObject(word);
    return t
        .hitTestOnBinding(t.getCenter(word))
        .path
        .any((entry) => entry.target == box);
  }

  final touchable = ids.where(reachable);
  expect(touchable, isNotEmpty, reason: 'no word of 2:282 can be touched');
  await t.longPress(byKey('w${touchable.first}'));
  await waitFor(t, ayahBookmarkRow);
}

/// Brings [target] into view inside what scrolls it.
Future<void> show(WidgetTester t, Finder target) async {
  await t.ensureVisible(target);
  await t.pump();
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> openNote(WidgetTester t) async {
  await show(t, ayahNoteRow);
  await t.tap(ayahNoteRow);
  await waitFor(t, noteField);
  // the focus brings the field into view where the title above it is taller than the dialog
  await t.pump(const Duration(seconds: 1));
  await t.pump();
}

/// Types [text] in the open note field and brings the field, grown to its three lines, whole into the dialog's window
/// (a test's typing does not move the caret into view as a keyboard does).
Future<void> typeNote(WidgetTester t, String text) async {
  await t.enterText(noteField, text);
  await t.pump();
  await show(t, noteField);
}

/// The system back: closes the sheet, the list or Settings.
Future<void> back(WidgetTester t, Finder gone) async {
  await t.binding.handlePopRoute();
  await waitFor(t, gone, gone: true);
}

/// Presses a button of the reader's bottom bar: a tap where a finger reaches it; where the bar's known overflow (320 dp
/// with a 2x system font) leaves it outside the screen, what its tap does.
Future<void> pressBar(WidgetTester t, Finder label) async {
  final center = t.getCenter(label);
  final box = t.renderObject(label);
  if (t.hitTestOnBinding(center).path.any((e) => e.target == box)) {
    await t.tap(label);
    return;
  }
  final inkWell = find.ancestor(of: label, matching: find.byType(InkWell));
  if (inkWell.evaluate().isNotEmpty) {
    t.widget<InkWell>(inkWell.first).onTap!();
  } else {
    t.widget<IconButton>(label).onPressed!();
  }
}

Future<void> openList(WidgetTester t) async {
  await pressBar(
    t,
    find.descendant(of: byKey('bottom-bar'), matching: find.text('علامات')),
  );
  await waitFor(t, bookmarkList);
}

/// Settings over the reader, by the bottom bar's button, with the switch brought into view.
Future<void> openSettings(WidgetTester t) async {
  await pressBar(t, byKey('open-settings'));
  await waitFor(t, find.byType(SettingsScreen));
  await t.scrollUntilVisible(
    tintSwitch,
    120,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await show(t, tintSwitch);
}

/// A row of «علامات» scrolled into the list's window, looked for from the top of the list.
Future<Finder> showTile(WidgetTester t, int id) async {
  final tile = byKey('bookmark-$id');
  final scrollable = find
      .descendant(of: bookmarkList, matching: find.byType(Scrollable))
      .first;
  t.state<ScrollableState>(scrollable).position.jumpTo(0);
  await t.pump();
  await t.scrollUntilVisible(tile, 40, scrollable: scrollable);
  await t.pump();
  return tile;
}

Size screenOf(WidgetTester t) => t.view.physicalSize / t.view.devicePixelRatio;

/// Every text and icon inside [within] reaches 4.5:1 on what is painted behind it.
void expectReadable(WidgetTester t, Finder within, String what) {
  expect(within, findsOneWidget, reason: what);
  final issues = contrastIssues(t, within: within, largeMin: 4.5);
  expect(issues, isEmpty, reason: '$what: ${issues.join('\n')}');
}

/// [target] is 48 wide and [minHeight] high at least and inside the screen's width; [whole] also inside its height.
void expectTarget(
  WidgetTester t,
  Finder target,
  String what, {
  double minHeight = 48,
  bool whole = true,
}) {
  expect(target, findsOneWidget, reason: what);
  final rect = t.getRect(target);
  final screen = screenOf(t);
  expect(rect.width, greaterThanOrEqualTo(48), reason: '$what width $rect');
  expect(
    rect.height,
    greaterThanOrEqualTo(minHeight),
    reason: '$what height $rect',
  );
  expect(rect.left, greaterThanOrEqualTo(-0.01), reason: '$what $rect');
  expect(
    rect.right,
    lessThanOrEqualTo(screen.width + 0.01),
    reason: '$what $rect in $screen',
  );
  if (whole) {
    expect(rect.top, greaterThanOrEqualTo(-0.01), reason: '$what $rect');
    expect(
      rect.bottom,
      lessThanOrEqualTo(screen.height + 0.01),
      reason: '$what $rect in $screen',
    );
  }
}

/// A touch on the middle of [target] lands on it: it is not cut off or covered.
void expectTouchable(WidgetTester t, Finder target, String what) {
  expect(target, findsOneWidget, reason: what);
  final box = t.renderObject(target);
  expect(
    t.hitTestOnBinding(t.getCenter(target)).path.any((e) => e.target == box),
    isTrue,
    reason: '$what cannot be touched at ${t.getCenter(target)}',
  );
}

/// No text of [box] is drawn outside it (nothing is cut off by the row's edge).
void expectTextsInside(WidgetTester t, Finder box, String what) {
  final outer = t.getRect(box);
  final texts = find.descendant(of: box, matching: find.byType(Text));
  expect(texts, findsWidgets, reason: what);
  for (final e in texts.evaluate()) {
    final r = t.getRect(find.byElementPredicate((x) => x == e));
    final words = (e.widget as Text).data;
    expect(
      r.left >= outer.left - 0.01 &&
          r.right <= outer.right + 0.01 &&
          r.top >= outer.top - 0.01 &&
          r.bottom <= outer.bottom + 0.01,
      isTrue,
      reason: '$what: «$words» $r is outside $outer',
    );
  }
}

/// The card a tap lands on inside a sheet row or a list row.
Finder cardOf(Finder row) =>
    find.descendant(of: row, matching: find.byType(InkWell));

/// The colours of every text inside [within], in order: what a look change must change.
List<Color?> inks(WidgetTester t, Finder within) => [
  for (final e
      in find
          .descendant(of: within, matching: find.byType(RichText))
          .evaluate())
    (e.widget as RichText).text.style?.color,
];

/// The two rows of the open sheet: their words for the state, 48 px cards inside the screen, readable, nothing cut off.
Future<void> expectSheetRows(
  WidgetTester t, {
  required bool bookmarked,
  String? note,
  required String reason,
}) async {
  await show(t, ayahBookmarkRow);
  expect(
    find.descendant(
      of: ayahBookmarkRow,
      matching: find.text(
        bookmarked ? kAyahBookmarkRemoveLabel : kAyahBookmarkAddLabel,
      ),
    ),
    findsOneWidget,
    reason: reason,
  );
  expect(
    find.descendant(
      of: ayahBookmarkRow,
      matching: find.byIcon(
        bookmarked
            ? Icons.bookmark_remove_outlined
            : Icons.bookmark_add_outlined,
      ),
    ),
    findsOneWidget,
    reason: reason,
  );
  expectTarget(t, cardOf(ayahBookmarkRow), 'the bookmark row, $reason');
  expectTouchable(t, cardOf(ayahBookmarkRow), 'the bookmark row, $reason');
  expectReadable(t, ayahBookmarkRow, 'the bookmark row, $reason');
  expectTextsInside(t, cardOf(ayahBookmarkRow), 'the bookmark row, $reason');

  await show(t, ayahNoteRow);
  expect(
    find.descendant(of: ayahNoteRow, matching: find.text(kAyahNoteLabel)),
    findsOneWidget,
    reason: reason,
  );
  final line = find.descendant(
    of: ayahNoteRow,
    matching: find.text(note ?? ''),
  );
  if (note == null) {
    expect(
      find.descendant(of: ayahNoteRow, matching: find.byType(Text)),
      findsOneWidget,
      reason: 'no line under the label, $reason',
    );
  } else {
    expect(line, findsOneWidget, reason: reason);
    // the start of the note on one line
    expect(
      t.getSize(line).height,
      lessThan(
        t
                .getSize(
                  find.descendant(
                    of: ayahNoteRow,
                    matching: find.text(kAyahNoteLabel),
                  ),
                )
                .height *
            1.5,
      ),
      reason: 'the note takes one line, $reason',
    );
  }
  expectTarget(t, cardOf(ayahNoteRow), 'the note row, $reason');
  expectTouchable(t, cardOf(ayahNoteRow), 'the note row, $reason');
  expectReadable(t, ayahNoteRow, 'the note row, $reason');
  expectTextsInside(t, cardOf(ayahNoteRow), 'the note row, $reason');
}

/// The open note field: its title, label and [hint], the two buttons 48 px and inside the screen, everything readable.
void expectNoteField(
  WidgetTester t, {
  required String hint,
  bool failed = false,
  required String reason,
}) {
  expect(
    find.descendant(
      of: noteDialog,
      matching: find.text(kAyahNoteTitle(surah, 282)),
    ),
    findsOneWidget,
    reason: reason,
  );
  expect(
    find.descendant(of: noteDialog, matching: find.text(kAyahNoteField)),
    findsOneWidget,
    reason: reason,
  );
  expect(
    find.descendant(of: noteDialog, matching: find.text(hint)),
    findsOneWidget,
    reason: reason,
  );
  expect(
    find.descendant(of: noteDialog, matching: find.text(kAyahNoteFailed)),
    failed ? findsOneWidget : findsNothing,
    reason: reason,
  );
  expectTarget(t, noteDialog, 'the note dialog, $reason');
  expectTarget(t, noteCancel, '«إلغاء», $reason');
  expectTarget(t, noteSave, '«حفظ», $reason');
  expectTouchable(t, noteCancel, '«إلغاء», $reason');
  expectTouchable(t, noteSave, '«حفظ», $reason');
  expectTouchable(t, noteField, 'the field, $reason');
  expect(
    t.getSize(noteField).height,
    greaterThanOrEqualTo(48),
    reason: 'the field, $reason',
  );
  final field = t.getRect(noteField);
  final screen = screenOf(t);
  expect(field.left, greaterThanOrEqualTo(-0.01), reason: reason);
  expect(field.right, lessThanOrEqualTo(screen.width + 0.01), reason: reason);
  expectReadable(t, noteDialog, 'the note field, $reason');
}

void main() {
  for (final look in LookChoice.values) {
    group(look.name, () {
      for (final screen in screens) {
        for (final percent in percents) {
          testWidgets(
            '$screen at $percent %: the sheet\'s rows, the note field, the list rows and the switch',
            (t) async {
              final s = await pumpReader(
                t,
                look: look,
                screen: screen,
                percent: percent,
              );
              final where = '${look.name}, $screen, $percent %';

              // the sheet: no bookmark, no note
              await openSheet(t, s);
              expect(
                MediaQuery.textScalerOf(t.element(ayahBookmarkRow)).scale(10),
                10 * screen.textScale,
                reason: 'the sheet gets the system font scale',
              );
              await expectSheetRows(
                t,
                bookmarked: false,
                reason: 'no bookmark, $where',
              );

              // the note field on an ayah with no bookmark; a long note is saved
              await openNote(t);
              expectNoteField(
                t,
                hint: kAyahNoteHintNew,
                reason: 'no bookmark, $where',
              );
              await typeNote(t, longNote);
              expectNoteField(
                t,
                hint: kAyahNoteHintNew,
                reason: 'a long note typed, $where',
              );
              await show(t, noteSave);
              await t.tap(noteSave);
              await waitFor(t, find.byType(SnackBar));
              expect(ayahNoteRow, findsNothing);
              // the message goes after its usual 4 s
              await t.pump(const Duration(seconds: 5));
              await waitFor(t, find.byType(SnackBar), gone: true);

              // the sheet: a bookmark with a note
              await openSheet(t, s);
              await expectSheetRows(
                t,
                bookmarked: true,
                note: longNote,
                reason: 'a bookmark with a note, $where',
              );
              await openNote(t);
              expectNoteField(
                t,
                hint: kAyahNoteHintExisting,
                reason: 'a bookmark with a note, $where',
              );
              await show(t, noteCancel);
              await t.tap(noteCancel);
              await waitFor(t, noteField, gone: true);
              expect(ayahNoteRow, findsOneWidget);
              await back(t, ayahNoteRow);

              // «علامات»: two ayah rows and a page row
              final all = (await t.runAsync(
                () => s.db.select(s.db.bookmarks).get(),
              ))!;
              expect(all, hasLength(3));
              await openList(t);
              for (final b in all) {
                final tile = await showTile(t, b.id);
                final isAyah = b.ayah != null;
                final what =
                    '${isAyah ? 'the ayah row ${b.surah}:${b.ayah}' : 'the page row'}, $where';
                // told apart without colour: the icon and the word «آية» (SC-006)
                expect(
                  find.descendant(
                    of: tile,
                    matching: find.byIcon(Icons.auto_stories_outlined),
                  ),
                  isAyah ? findsOneWidget : findsNothing,
                  reason: what,
                );
                if (isAyah) {
                  final title = kAyahRowTitle(
                    s.meta.surah(b.surah!).name,
                    b.ayah!,
                  );
                  expect(title, contains(kAyahRowWord));
                  expect(
                    find.descendant(of: tile, matching: find.text(title)),
                    findsOneWidget,
                    reason: what,
                  );
                }
                expect(
                  find.descendant(
                    of: tile,
                    matching: find.text(kAyahRowPage(b.page)),
                  ),
                  findsOneWidget,
                  reason: what,
                );
                // the list's own window is short on a small screen on its side: the row is whole inside the list
                expectTarget(
                  t,
                  cardOf(tile),
                  what,
                  minHeight: 56,
                  whole: false,
                );
                expectReadable(t, tile, what);
                expectTextsInside(t, cardOf(tile), what);
              }
              await back(t, bookmarkList);

              // Settings: the switch, on and off
              await openSettings(t);
              for (final value in const [true, false]) {
                final what = 'the switch ${value ? 'on' : 'off'}, $where';
                expect(
                  t.widget<SwitchListTile>(tintSwitch).value,
                  value,
                  reason: what,
                );
                expect(
                  find.descendant(
                    of: tintSwitch,
                    matching: find.text(kAyahTintTitle),
                  ),
                  findsOneWidget,
                  reason: what,
                );
                expect(
                  find.descendant(
                    of: tintSwitch,
                    matching: find.text(kAyahTintSubtitle),
                  ),
                  findsOneWidget,
                  reason: what,
                );
                expectTarget(t, tintSwitch, what);
                expectTouchable(t, tintSwitch, what);
                expectReadable(t, tintSwitch, what);
                expectTextsInside(t, tintSwitch, what);
                if (value) {
                  await t.tap(tintSwitch);
                  for (var i = 0; i < 4; i++) {
                    await t.runAsync(
                      () => Future<void>.delayed(
                        const Duration(milliseconds: 20),
                      ),
                    );
                    await t.pump(const Duration(milliseconds: 100));
                  }
                }
              }

              expect(
                s.unexpectedErrors,
                isEmpty,
                reason: '$where:\n${s.unexpectedErrors.join('\n')}',
              );
            },
          );
        }
      }

      for (final screen in const [
        ScreenCase(Size(412, 915), 1.0),
        ScreenCase(Size(320, 640), 2.0),
        ScreenCase(Size(640, 320), 2.0),
      ]) {
        testWidgets(
          '$screen: a save that fails shows its line in the field, readable, nothing overflows',
          (t) async {
            final s = await pumpReader(
              t,
              look: look,
              screen: screen,
              failingNotes: true,
            );
            await openSheet(t, s);
            await openNote(t);
            await typeNote(t, longNote);
            await t.tap(noteSave);
            await waitFor(
              t,
              find.descendant(
                of: noteDialog,
                matching: find.text(kAyahNoteFailed),
              ),
            );
            expectNoteField(
              t,
              hint: kAyahNoteHintNew,
              failed: true,
              reason: 'a failed save, ${look.name}, $screen',
            );
            expect(
              s.unexpectedErrors,
              isEmpty,
              reason: s.unexpectedErrors.join('\n'),
            );
          },
        );
      }
    });
  }

  testWidgets(
    'a look change is followed at once by the open sheet, the note field, the list and the switch',
    (t) async {
      final s = await pumpReader(
        t,
        look: LookChoice.emerald,
        screen: const ScreenCase(Size(412, 915), 1.0),
      );

      /// Chooses [next] as Settings does, lets one frame pass, and expects [within] in the new look: other colours
      /// than before, the new look's card where it has one, readable.
      Future<void> change(
        LookChoice next,
        Finder within,
        String what, {
        Iterable<Finder> cards = const [],
      }) async {
        final before = inks(t, within);
        expect(before, isNotEmpty, reason: what);
        await t.runAsync(() => s.look.set(next));
        await t.pump();
        final after = inks(t, within);
        expect(after, hasLength(before.length), reason: what);
        expect(after, isNot(before), reason: '$what keeps the old colours');
        for (final card in cards) {
          expect(
            t
                .widget<Material>(
                  find.descendant(of: card, matching: find.byType(Material)),
                )
                .color,
            next.look.cardFill,
            reason: what,
          );
        }
        expectReadable(t, within, '$what after the change to ${next.name}');
      }

      await openSheet(t, s);
      await change(
        LookChoice.night,
        ayahBookmarkRow,
        'the bookmark row',
        cards: [ayahBookmarkRow],
      );
      await change(
        LookChoice.emerald,
        ayahNoteRow,
        'the note row',
        cards: [ayahNoteRow],
      );

      await openNote(t);
      await change(LookChoice.night, noteDialog, 'the note field');
      await t.tap(noteCancel);
      await waitFor(t, noteField, gone: true);
      await back(t, ayahNoteRow);

      final all = (await t.runAsync(() => s.db.select(s.db.bookmarks).get()))!;
      await openList(t);
      var next = LookChoice.emerald;
      for (final b in all) {
        final tile = await showTile(t, b.id);
        await change(
          next,
          tile,
          b.ayah == null ? 'the page row' : 'the ayah row',
          cards: [tile],
        );
        next = next == LookChoice.emerald
            ? LookChoice.night
            : LookChoice.emerald;
      }
      await back(t, bookmarkList);

      await openSettings(t);
      await change(next, tintSwitch, 'the switch');

      expect(
        s.unexpectedErrors,
        isEmpty,
        reason: s.unexpectedErrors.join('\n'),
      );
    },
  );
}
