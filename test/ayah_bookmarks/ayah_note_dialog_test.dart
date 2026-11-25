// The note field «ملاحظة للآية» (feature 013, task T027; spec FR-015, FR-021; contracts/ui.md §2; research D9): titled with
// the ayah, opened with the current note, at most 200 characters, a line that says what saving does, «حفظ» and «إلغاء»;
// cancel, back and a tap outside change nothing; a failed save keeps the field open with the typed text.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ui/ayah_note_dialog.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/theme.dart';

Finder byKey(String k) => find.byKey(ValueKey(k));

class DialogHarness {
  DialogHarness({
    this.initialNote,
    this.bookmarkExists = false,
    this.fail = false,
  });

  final String? initialNote;
  final bool bookmarkExists;
  bool fail;
  final List<String> saved = [];
  final List<bool?> results = [];

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
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
                  results.add(
                    await showAyahNoteDialog(
                      context,
                      title: kAyahNoteTitle('البقرة', 282),
                      initialNote: initialNote,
                      bookmarkExists: bookmarkExists,
                      onSave: (text) async {
                        saved.add(text);
                        if (fail) throw StateError('disk full');
                      },
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(byKey('open'));
    await t.pumpAndSettle();
  }
}

void main() {
  testWidgets('the title, the label, the current note, focus in the field', (
    t,
  ) async {
    final h = DialogHarness(initialNote: 'أراجع هنا', bookmarkExists: true);
    await h.pump(t);
    expect(find.text('ملاحظة على سورة البقرة · آية 282'), findsOneWidget);
    expect(find.text(kAyahNoteField), findsOneWidget);
    expect(find.text(kAyahNoteFailed), findsNothing);
    final field = t.widget<TextField>(byKey('ayah-note-field'));
    expect(field.controller!.text, 'أراجع هنا');
    expect(field.autofocus, isTrue);
    expect(field.maxLength, 200);
    expect(
      t.testTextInput.isVisible,
      isTrue,
      reason: 'the keyboard is up: the focus is in the field',
    );
  });

  testWidgets('the line under the field says what saving does', (t) async {
    final none = DialogHarness();
    await none.pump(t);
    expect(find.text(kAyahNoteHintNew), findsOneWidget);
    expect(find.text(kAyahNoteHintExisting), findsNothing);
    await t.tap(byKey('ayah-note-cancel'));
    await t.pumpAndSettle();
    final some = DialogHarness(bookmarkExists: true);
    await some.pump(t);
    expect(find.text(kAyahNoteHintExisting), findsOneWidget);
    expect(find.text(kAyahNoteHintNew), findsNothing);
  });

  testWidgets('the field stops at 200 characters', (t) async {
    final h = DialogHarness();
    await h.pump(t);
    await t.enterText(byKey('ayah-note-field'), 'ب' * 250);
    await t.pump();
    expect(
      t.widget<TextField>(byKey('ayah-note-field')).controller!.text.length,
      200,
    );
  });

  testWidgets('«حفظ» hands the typed text to onSave and closes with true', (
    t,
  ) async {
    final h = DialogHarness(initialNote: 'قديمة', bookmarkExists: true);
    await h.pump(t);
    await t.enterText(byKey('ayah-note-field'), 'جديدة');
    await t.tap(byKey('ayah-note-save'));
    await t.pumpAndSettle();
    expect(h.saved, ['جديدة']);
    expect(h.results, [true]);
    expect(byKey('ayah-note-field'), findsNothing);
  });

  testWidgets(
    'an empty field is saved as empty text (the repository decides)',
    (t) async {
      final h = DialogHarness(initialNote: 'قديمة', bookmarkExists: true);
      await h.pump(t);
      await t.enterText(byKey('ayah-note-field'), '');
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(h.saved, ['']);
      expect(h.results, [true]);
    },
  );

  testWidgets(
    '«إلغاء», the back gesture and a tap outside call nothing and do not return true',
    (t) async {
      final h = DialogHarness(initialNote: 'قديمة', bookmarkExists: true);
      await h.pump(t);
      await t.enterText(byKey('ayah-note-field'), 'لن تحفظ');
      await t.tap(byKey('ayah-note-cancel'));
      await t.pumpAndSettle();
      await t.tap(byKey('open'));
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tap(byKey('open'));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(4, 4));
      await t.pumpAndSettle();
      expect(h.saved, isEmpty);
      expect(h.results, hasLength(3));
      expect(h.results.where((r) => r == true), isEmpty);
      expect(byKey('ayah-note-field'), findsNothing);
    },
  );

  testWidgets(
    'a failing save keeps the field open with the typed text and says so',
    (t) async {
      final h = DialogHarness(fail: true);
      await h.pump(t);
      await t.enterText(byKey('ayah-note-field'), 'أراجع هنا');
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(h.saved, ['أراجع هنا']);
      expect(h.results, isEmpty, reason: 'still open');
      expect(
        t.widget<TextField>(byKey('ayah-note-field')).controller!.text,
        'أراجع هنا',
      );
      expect(find.text(kAyahNoteFailed), findsOneWidget);
      expect(
        t.getRect(find.text(kAyahNoteFailed)).top,
        greaterThanOrEqualTo(t.getRect(byKey('ayah-note-field')).bottom - 0.01),
        reason: 'the line is under the field',
      );
      h.fail = false;
      await t.tap(byKey('ayah-note-save'));
      await t.pumpAndSettle();
      expect(h.results, [true]);
    },
  );

  testWidgets('the two buttons are 48 px targets', (t) async {
    final h = DialogHarness();
    await h.pump(t);
    for (final k in ['ayah-note-save', 'ayah-note-cancel']) {
      final size = t.getSize(byKey(k));
      expect(size.height, greaterThanOrEqualTo(48), reason: k);
      expect(size.width, greaterThanOrEqualTo(48), reason: k);
    }
    expect(find.text(kAyahNoteSave), findsOneWidget);
    expect(find.text(kAyahNoteCancel), findsOneWidget);
  });
}
