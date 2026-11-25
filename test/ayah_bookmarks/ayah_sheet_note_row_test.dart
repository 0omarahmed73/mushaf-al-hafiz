// The note row «ملاحظة للآية» of the ayah sheet (feature 013, task T029; spec FR-001, FR-015, FR-021; contracts/ui.md §1): a
// full visible row right after the bookmark row, with the start of the note and the state a screen reader hears; a tap
// opens the note field prefilled; cancel leaves the sheet open; a save closes the sheet and hands the change to the reader;
// a save that wrote nothing (case d) closes the sheet and hands nothing.
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/wirds/ayah_bookmark_change.dart';

import '../support/ayah_sheet_port_harness.dart';

Finder byKey(String k) => find.byKey(ValueKey(k));

const ref = AyahRef(2, 6);
final Finder noteRow = byKey('ayah-note');
final Finder noteField = byKey('ayah-note-field');

Future<AyahSheetWithPort> openSheet(WidgetTester t, FakeAyahPort port) async {
  final h = AyahSheetWithPort(ref: ref, port: port);
  await h.pump(t);
  await h.open(t);
  return h;
}

Future<void> tapNoteRow(WidgetTester t) async {
  await t.tap(noteRow);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'the row comes right after the bookmark row, a visible full row with no gesture needed',
    (t) async {
      await openSheet(t, FakeAyahPort());
      expect(
        [
          for (final e in find.byType(SheetRow).evaluate())
            (e.widget.key as ValueKey<String>).value,
        ],
        [
          'ayah-share',
          'ayah-tafsir',
          'ayah-translation',
          'ayah-meanings',
          'ayah-bookmark',
          'ayah-note',
          'ayah-page-picture',
        ],
      );
      final bookmark = t.getRect(byKey('ayah-bookmark'));
      final note = t.getRect(noteRow);
      final section = t.getRect(find.text('الصفحة والسورة'));
      expect(note.top, greaterThan(bookmark.bottom - 0.01));
      expect(note.bottom, lessThan(section.top + 0.01));
      expect(note.width, closeTo(bookmark.width, 0.01));
      expect(note.height, greaterThanOrEqualTo(48));
      final screen =
          Offset.zero & t.view.physicalSize / t.view.devicePixelRatio;
      expect(
        screen.contains(note.topLeft) && screen.contains(note.bottomRight),
        isTrue,
        reason: 'on the screen as the sheet opens, no scroll needed',
      );
      expect(
        find.descendant(of: noteRow, matching: find.text(kAyahNoteLabel)),
        findsOneWidget,
      );
      expect(kAyahNoteLabel, 'ملاحظة للآية');
      expect(
        find.descendant(of: noteRow, matching: find.byIcon(Icons.edit_note)),
        findsOneWidget,
      );
      final ink = t.widget<InkWell>(
        find.descendant(of: noteRow, matching: find.byType(InkWell)),
      );
      expect(ink.onTap, isNotNull);
      expect(ink.onLongPress, isNull);
      expect(ink.onDoubleTap, isNull);
    },
  );

  for (final note in [null, 'أراجع هنا']) {
    testWidgets(
      '${note == null ? 'no note' : 'a note'}: the line under the label and the value heard, in the first frame',
      (t) async {
        final semantics = t.ensureSemantics();
        final h = AyahSheetWithPort(
          ref: ref,
          port: FakeAyahPort(bookmarked: note != null, note: note),
        );
        await h.pump(t);
        await t.tap(byKey('open'));
        await t.pump(); // the first frame of the sheet
        expect(noteRow, findsOneWidget);
        final texts = [
          for (final w in t.widgetList<Text>(
            find.descendant(of: noteRow, matching: find.byType(Text)),
          ))
            w.data,
        ];
        expect(texts, note == null ? [kAyahNoteLabel] : [kAyahNoteLabel, note]);
        await t.pump(const Duration(milliseconds: 500));
        final node = t.getSemantics(
          find.descendant(of: noteRow, matching: find.byType(InkWell)),
        );
        expect(node.label, startsWith(kAyahNoteLabel));
        expect(node.value, note == null ? kAyahNoteNone : kAyahNoteHas);
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        semantics.dispose();
      },
    );
  }

  testWidgets('a bookmark with no note reads «ليس عليها ملاحظة» and no line', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await openSheet(t, FakeAyahPort(bookmarked: true));
    expect(
      find.descendant(of: noteRow, matching: find.byType(Text)),
      findsOneWidget,
    );
    expect(
      t
          .getSemantics(
            find.descendant(of: noteRow, matching: find.byType(InkWell)),
          )
          .value,
      kAyahNoteNone,
    );
    semantics.dispose();
  });

  testWidgets('a long note shows its start on one line with an ellipsis', (
    t,
  ) async {
    await openSheet(t, FakeAyahPort());
    final plain = t.getSize(noteRow).height;
    await t.tapAt(const Offset(4, 4));
    await t.pumpAndSettle();
    final long = ('ملاحظة طويلة جدا ' * 11).trim();
    await openSheet(t, FakeAyahPort(bookmarked: true, note: long));
    final line = t.widget<Text>(
      find.descendant(of: noteRow, matching: find.text(long)),
    );
    expect(line.maxLines, 1);
    expect(line.overflow, TextOverflow.ellipsis);
    expect(
      t.getSize(noteRow).height,
      lessThan(plain + 24),
      reason: 'one more line, not the whole note',
    );
    final row = t.getRect(noteRow);
    final text = t.getRect(
      find.descendant(of: noteRow, matching: find.text(long)),
    );
    expect(text.left, greaterThanOrEqualTo(row.left));
    expect(text.right, lessThanOrEqualTo(row.right));
  });

  testWidgets(
    'a tap opens the note field over the sheet, titled with the ayah and prefilled',
    (t) async {
      final port = FakeAyahPort(bookmarked: true, note: 'أراجع هنا');
      final h = await openSheet(t, port);
      await tapNoteRow(t);
      expect(find.text(kAyahNoteTitle('البقرة', 6)), findsOneWidget);
      expect(t.widget<TextField>(noteField).controller!.text, 'أراجع هنا');
      expect(find.text(kAyahNoteHintExisting), findsOneWidget);
      expect(noteRow, findsOneWidget, reason: 'the sheet is still under it');
      expect(h.closed, 0);
      expect(port.saves, isEmpty);
    },
  );

  testWidgets(
    'no bookmark: the field is empty and says a bookmark will be added',
    (t) async {
      await openSheet(t, FakeAyahPort());
      await tapNoteRow(t);
      expect(t.widget<TextField>(noteField).controller!.text, '');
      expect(find.text(kAyahNoteHintNew), findsOneWidget);
    },
  );

  testWidgets(
    '«إلغاء», back and a tap outside leave the sheet open and write nothing',
    (t) async {
      final port = FakeAyahPort(bookmarked: true, note: 'أراجع هنا');
      final h = await openSheet(t, port);
      for (final cancel in <Future<void> Function()>[
        () => t.tap(byKey('ayah-note-cancel')),
        () async => t.binding.handlePopRoute(),
        () => t.tapAt(const Offset(4, 4)),
      ]) {
        await tapNoteRow(t);
        await t.enterText(noteField, 'لن تحفظ');
        await cancel();
        await t.pumpAndSettle();
        expect(noteField, findsNothing, reason: 'the field closed');
        expect(noteRow, findsOneWidget, reason: 'the sheet stays open');
      }
      expect(h.closed, 0);
      expect(port.saves, isEmpty);
      expect(port.changes, isEmpty);
      expect(port.toggles, isEmpty);
    },
  );

  testWidgets(
    'a save writes the typed text once, closes the field and the sheet and hands the change to the reader',
    (t) async {
      final port = FakeAyahPort(bookmarked: true, note: 'قديمة');
      final h = await openSheet(t, port);
      await tapNoteRow(t);
      await t.enterText(noteField, 'جديدة');
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(port.saves, [(ref, 'جديدة')]);
      expect(noteField, findsNothing);
      expect(noteRow, findsNothing);
      expect(h.closed, 1, reason: 'the sheet closed');
      expect(port.changes, hasLength(1));
      final change = port.changes.single;
      expect(change.kind, AyahChangeKind.noteReplaced);
      expect(change.ref, ref);
      expect(change.before, [(id: 1, note: 'قديمة')]);
      expect(port.toggles, isEmpty);
    },
  );

  testWidgets(
    'a note on an ayah with no bookmark hands «created with a note»',
    (t) async {
      final port = FakeAyahPort();
      final h = await openSheet(t, port);
      await tapNoteRow(t);
      await t.enterText(noteField, 'أراجع هنا');
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(port.saves, [(ref, 'أراجع هنا')]);
      expect(h.closed, 1);
      expect(port.changes.single.kind, AyahChangeKind.createdWithNote);
    },
  );

  testWidgets(
    'case (d), a save that wrote nothing: the sheet closes and nothing is handed to the reader',
    (t) async {
      final port = FakeAyahPort()..saveReturnsNull = true;
      final h = await openSheet(t, port);
      await tapNoteRow(t);
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(port.saves, [(ref, '')]);
      expect(noteField, findsNothing);
      expect(h.closed, 1, reason: 'the sheet closed');
      expect(port.changes, isEmpty);
    },
  );

  testWidgets(
    'a failing save keeps the field and the sheet open with the typed text',
    (t) async {
      final port = FakeAyahPort()..saveError = StateError('disk full');
      final h = await openSheet(t, port);
      await tapNoteRow(t);
      await t.enterText(noteField, 'أراجع هنا');
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(find.text(kAyahNoteFailed), findsOneWidget);
      expect(t.widget<TextField>(noteField).controller!.text, 'أراجع هنا');
      expect(h.closed, 0);
      expect(port.changes, isEmpty);
      port.saveError = null;
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(h.closed, 1);
      expect(port.changes, hasLength(1));
    },
  );
}
