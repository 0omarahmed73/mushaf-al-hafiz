// The «عرض الملاحظة» row of the ayah sheet (feature 013, the owner's request of 2026-11-25, spec FR-028, task T050): when
// the ayah's bookmark of the scope has a note, a visible row right after «ملاحظة للآية» opens the whole note to read, with
// «تعديل» (the note field, prefilled) and «إغلاق» (back to the sheet, nothing written). With no note there is no row.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';

import '../support/ayah_sheet_port_harness.dart';

Finder byKey(String k) => find.byKey(ValueKey(k));

const ref = AyahRef(2, 6);
final Finder showRow = byKey('ayah-note-show');
final Finder viewer = byKey('ayah-note-view');

const String longNote =
    'أراجع هذه الآية مع التي قبلها كل يوم، وأنتبه للفرق بين الموضعين في السورة، ثم أعيدها ثلاث مرات قبل النوم '
    'وأكتب ما أخطأت فيه حتى لا يتكرر، وأسأل عنها الشيخ في المجلس القادم إن شاء الله';

Future<AyahSheetWithPort> openSheet(WidgetTester t, FakeAyahPort port) async {
  final h = AyahSheetWithPort(ref: ref, port: port);
  await h.pump(t);
  await h.open(t);
  return h;
}

List<String> rowKeys(WidgetTester t) => [
  for (final e in find.byType(SheetRow).evaluate())
    (e.widget.key as ValueKey<String>).value,
];

void main() {
  test('the strings of the row and of the note to read', () {
    expect(kAyahNoteShowLabel, 'عرض الملاحظة');
    expect(kAyahNoteEdit, 'تعديل');
    expect(kAyahNoteClose, 'إغلاق');
  });

  for (final (name, port) in [
    ('no bookmark', FakeAyahPort()),
    ('a bookmark with no note', FakeAyahPort(bookmarked: true)),
    ('a note of spaces only', FakeAyahPort(bookmarked: true, note: '   ')),
  ]) {
    testWidgets('$name: no «عرض الملاحظة» row', (t) async {
      await openSheet(t, port);
      expect(showRow, findsNothing);
      expect(find.text(kAyahNoteShowLabel), findsNothing);
    });
  }

  testWidgets(
    'a note: the row comes right after «ملاحظة للآية», a full row with its own icon',
    (t) async {
      await openSheet(t, FakeAyahPort(bookmarked: true, note: 'أراجع هنا'));
      final keys = rowKeys(t);
      expect(keys.indexOf('ayah-note-show'), keys.indexOf('ayah-note') + 1);
      final note = t.getRect(byKey('ayah-note'));
      final show = t.getRect(showRow);
      expect(show.top, greaterThan(note.bottom - 0.01));
      expect(show.width, closeTo(note.width, 0.01));
      expect(show.height, greaterThanOrEqualTo(48));
      expect(
        find.descendant(of: showRow, matching: find.text(kAyahNoteShowLabel)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: showRow,
          matching: find.byIcon(Icons.sticky_note_2_outlined),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a tap shows the whole note, not cut, under the ayah\'s title; nothing is written',
    (t) async {
      final port = FakeAyahPort(bookmarked: true, note: longNote);
      await openSheet(t, port);
      await t.tap(showRow);
      await t.pumpAndSettle();
      expect(viewer, findsOneWidget);
      expect(
        find.descendant(
          of: viewer,
          matching: find.textContaining('ملاحظة على سورة'),
        ),
        findsOneWidget,
      );
      final body = t.widget<Text>(byKey('ayah-note-view-text'));
      expect(body.data, longNote);
      expect(body.maxLines, isNull);
      expect(body.overflow, isNot(TextOverflow.ellipsis));
      expect(port.saves, isEmpty);
      expect(port.toggles, isEmpty);
      expect(byKey('ayah-note-field'), findsNothing);
    },
  );

  testWidgets('«إغلاق» goes back to the sheet, which stays open', (t) async {
    final port = FakeAyahPort(bookmarked: true, note: 'أراجع هنا');
    final h = await openSheet(t, port);
    await t.tap(showRow);
    await t.pumpAndSettle();
    await t.tap(byKey('ayah-note-view-close'));
    await t.pumpAndSettle();
    expect(viewer, findsNothing);
    expect(showRow, findsOneWidget);
    expect(h.closed, 0);
    expect(port.saves, isEmpty);
    expect(port.changes, isEmpty);
  });

  testWidgets('the back gesture closes the note and leaves the sheet open', (
    t,
  ) async {
    final h = await openSheet(
      t,
      FakeAyahPort(bookmarked: true, note: 'أراجع هنا'),
    );
    await t.tap(showRow);
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(viewer, findsNothing);
    expect(showRow, findsOneWidget);
    expect(h.closed, 0);
  });

  testWidgets(
    '«تعديل» opens the note field with the note in it, and a save goes through the port as from «ملاحظة للآية»',
    (t) async {
      final port = FakeAyahPort(bookmarked: true, note: 'أراجع هنا');
      final h = await openSheet(t, port);
      await t.tap(showRow);
      await t.pumpAndSettle();
      await t.tap(byKey('ayah-note-view-edit'));
      await t.pumpAndSettle();
      expect(viewer, findsNothing);
      final field = t.widget<TextField>(byKey('ayah-note-field'));
      expect(field.controller!.text, 'أراجع هنا');
      await t.enterText(byKey('ayah-note-field'), 'مراجعة جديدة');
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(port.saves, [(ref, 'مراجعة جديدة')]);
      expect(port.changes, hasLength(1));
      expect(
        h.closed,
        1,
        reason: 'a save closes the sheet, as from the note row',
      );
    },
  );

  testWidgets('«تعديل» then «إلغاء» writes nothing and leaves the sheet open', (
    t,
  ) async {
    final port = FakeAyahPort(bookmarked: true, note: 'أراجع هنا');
    final h = await openSheet(t, port);
    await t.tap(showRow);
    await t.pumpAndSettle();
    await t.tap(byKey('ayah-note-view-edit'));
    await t.pumpAndSettle();
    await t.tap(byKey('ayah-note-cancel'));
    await t.pumpAndSettle();
    expect(port.saves, isEmpty);
    expect(h.closed, 0);
    expect(showRow, findsOneWidget);
  });

  testWidgets(
    'a screen reader hears a button named «عرض الملاحظة» with a tap action',
    (t) async {
      final semantics = t.ensureSemantics();
      await openSheet(t, FakeAyahPort(bookmarked: true, note: 'أراجع هنا'));
      final node = t.getSemantics(
        find.descendant(of: showRow, matching: find.byType(InkWell)),
      );
      expect(node.label, kAyahNoteShowLabel);
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      semantics.dispose();
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets(
      'at ${size.width.toInt()}x${size.height.toInt()} with a 2x font the long note scrolls and both buttons stay reachable',
      (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await openSheet(t, FakeAyahPort(bookmarked: true, note: longNote));
        await t.ensureVisible(showRow);
        await t.pumpAndSettle();
        await t.tap(showRow);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        final screen = Offset.zero & size;
        for (final k in ['ayah-note-view-close', 'ayah-note-view-edit']) {
          final r = t.getRect(byKey(k));
          expect(
            screen.contains(r.topLeft) && screen.contains(r.bottomRight),
            isTrue,
            reason: '$k on the screen',
          );
          expect(r.height, greaterThanOrEqualTo(48));
        }
        await t.tap(byKey('ayah-note-view-close'));
        await t.pumpAndSettle();
        expect(viewer, findsNothing);
      },
    );
  }
}
