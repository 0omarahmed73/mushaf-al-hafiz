// The bookmark row of the ayah sheet (feature 013, task T018; spec FR-001, FR-002, FR-017, SC-002; contracts/ui.md §1): a
// full visible row in the ayah's group, its label, icon and state right in the first frame, a 48 px target, one tap = one
// toggle, then the sheet closes and the change goes to the reader. No port: the sheet is exactly as before.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';

import '../support/ayah_sheet_port_harness.dart';

Finder byKey(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets(
    'the row sits in the ayah\'s group, after «معاني الكلمات», before «الصفحة والسورة»',
    (t) async {
      final h = AyahSheetWithPort(port: FakeAyahPort());
      await h.pump(t);
      await h.open(t);
      final meanings = t.getRect(byKey('ayah-meanings'));
      final row = t.getRect(byKey('ayah-bookmark'));
      final section = t.getRect(find.text('الصفحة والسورة'));
      expect(row.top, greaterThan(meanings.bottom - 0.01));
      expect(row.bottom, lessThan(section.top + 0.01));
      expect(
        row.width,
        closeTo(meanings.width, 0.01),
        reason: 'a full-width row like the others',
      );
    },
  );

  for (final bookmarked in [false, true]) {
    testWidgets(
      'state ${bookmarked ? 'remove' : 'add'}: label, icon and value in the first frame',
      (t) async {
        final semantics = t.ensureSemantics();
        final h = AyahSheetWithPort(port: FakeAyahPort(bookmarked: bookmarked));
        await h.pump(t);
        await t.tap(byKey('open'));
        await t.pump(); // the first frame of the sheet
        final label = bookmarked
            ? kAyahBookmarkRemoveLabel
            : kAyahBookmarkAddLabel;
        final icon = bookmarked
            ? Icons.bookmark_remove_outlined
            : Icons.bookmark_add_outlined;
        final row = byKey('ayah-bookmark');
        expect(row, findsOneWidget);
        expect(
          find.descendant(of: row, matching: find.text(label)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row, matching: find.byIcon(icon)),
          findsOneWidget,
        );
        await t.pump(const Duration(milliseconds: 500));
        // The semantics tree is read once the sheet has slid in.
        expect(
          t.getSemantics(
            find.descendant(of: row, matching: find.byType(InkWell)),
          ),
          isSemantics(
            isButton: true,
            hasTapAction: true,
            hasEnabledState: true,
            isEnabled: true,
            label: label,
            value: bookmarked ? kAyahStateOn : kAyahStateOff,
          ),
        );
        final size = t.getSize(row);
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'a tap calls toggle once, closes the sheet and hands the change to the reader',
    (t) async {
      final port = FakeAyahPort();
      final h = AyahSheetWithPort(ref: const AyahRef(2, 6), port: port);
      await h.pump(t);
      await h.open(t);
      await t.tap(byKey('ayah-bookmark'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(port.toggles, [const AyahRef(2, 6)]);
      expect(h.closed, 1, reason: 'the sheet closed');
      expect(byKey('ayah-bookmark'), findsNothing);
      expect(port.changes, hasLength(1));
      expect(port.changes.single.ref, const AyahRef(2, 6));
    },
  );

  testWidgets('with no port the sheet has exactly the rows it has today', (
    t,
  ) async {
    final h = AyahSheetWithPort();
    await h.pump(t);
    await h.open(t);
    expect(byKey('ayah-bookmark'), findsNothing);
    expect(byKey('ayah-note'), findsNothing);
    final rows = find.byType(SheetRow);
    expect(
      [
        for (final e in rows.evaluate())
          (e.widget.key as ValueKey<String>).value,
      ],
      [
        'ayah-share',
        'ayah-tafsir',
        'ayah-translation',
        'ayah-meanings',
        'ayah-page-picture',
      ],
    );
  });

  testWidgets('no row needs a long press: none has a long-press handler', (
    t,
  ) async {
    final h = AyahSheetWithPort(port: FakeAyahPort());
    await h.pump(t);
    await h.open(t);
    for (final w in t.widgetList<InkWell>(find.byType(InkWell))) {
      expect(w.onLongPress, isNull);
    }
    for (final w in t.widgetList<GestureDetector>(
      find.byType(GestureDetector),
    )) {
      expect(w.onLongPress, isNull);
    }
  });
}
