import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/share_service.dart';

import '../support/ayah_harness.dart';

const header6 = 'سورة البقرة · آية 6';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  group('the menu gains the tafsir and translation rows', () {
    testWidgets(
      '«التفسير» and «الترجمة» are labelled buttons at least 48 px tall',
      (t) async {
        final h = AyahHarness();
        await h.pump(t);
        await h.open(t);
        for (final (k, label) in [
          ('ayah-tafsir', 'التفسير'),
          ('ayah-translation', 'الترجمة'),
        ]) {
          expect(key(k), findsOneWidget, reason: label);
          expect(
            t.getSize(key(k)).height,
            greaterThanOrEqualTo(48),
            reason: label,
          );
          expect(
            find.descendant(of: key(k), matching: find.text(label)),
            findsOneWidget,
          );
        }
      },
    );
  });

  group('tafsir view', () {
    testWidgets(
      'shows the entry labelled as a human work, inside the same sheet with a back arrow',
      (t) async {
        final h = AyahHarness();
        await h.pump(t);
        await h.open(t);
        await h.tapRow(t, 'ayah-tafsir');
        expect(find.text('تفسير السعدي'), findsOneWidget);
        expect(find.text('شرح بشري وليس من نص القرآن'), findsOneWidget);
        expect(find.textContaining('تفسير الآيتين'), findsOneWidget);
        expect(find.textContaining('فقرة ثانية'), findsOneWidget);
        expect(key('ayah-back'), findsOneWidget);
        expect(
          key('ayah-share'),
          findsNothing,
          reason: 'the menu rows are replaced by the view',
        );
      },
    );

    testWidgets('does not repeat the Quran words of the ayah', (t) async {
      final h = AyahHarness();
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-tafsir');
      expect(find.textContaining('كلمةقرآنية'), findsNothing);
    });

    testWidgets('an entry that covers several ayahs says which ones', (
      t,
    ) async {
      final h = AyahHarness();
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-tafsir');
      expect(find.text('يشمل التفسير الآيات 6–7'), findsOneWidget);
    });

    testWidgets('an entry for one ayah has no covers line', (t) async {
      final h = AyahHarness(ref: const AyahRef(2, 9));
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-tafsir');
      expect(find.textContaining('تفسير التاسعة'), findsOneWidget);
      expect(find.textContaining('يشمل التفسير'), findsNothing);
    });

    testWidgets(
      'an ayah with no commentary of its own shows the earlier entry with a note',
      (t) async {
        final h = AyahHarness(ref: const AyahRef(2, 8));
        await h.pump(t);
        await h.open(t);
        await h.tapRow(t, 'ayah-tafsir');
        expect(
          find.text(
            'لا يوجد في هذا النص تعليق مستقل على هذه الآية، وهذا تفسير الآيات 6–7',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('تفسير الآيتين'), findsOneWidget);
        expect(
          find.textContaining('يشمل التفسير'),
          findsNothing,
          reason: 'the note already names the ayahs',
        );
      },
    );

    testWidgets('a very long entry scrolls inside its panel', (t) async {
      final long = List.generate(120, (i) => 'فقرة طويلة رقم $i').join('\n\n');
      final files = viewFiles()
        ..['assets/ayah/tafsir/002.json'] =
            '{"surah":2,"entries":[{"from":1,"to":9,"text":${_jsonString(long)}}],"without":[]}';
      final h = AyahHarness(files: files);
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-tafsir');
      final body = find.descendant(
        of: key('ayah-detail-body'),
        matching: find.byType(Scrollable),
      );
      expect(
        t.state<ScrollableState>(body).position.maxScrollExtent,
        greaterThan(0),
        reason: 'the entry is longer than the panel',
      );
      final last = find.textContaining('فقرة طويلة رقم 119');
      expect(
        last.hitTestable(),
        findsNothing,
        reason: 'the end is below the panel',
      );
      await t.scrollUntilVisible(last, 300, scrollable: body);
      expect(last.hitTestable(), findsOneWidget);
    });

    testWidgets(
      'its share button hands the entry, the reference and the source name to the share sheet',
      (t) async {
        final h = AyahHarness();
        await h.pump(t);
        await h.open(t);
        await h.tapRow(t, 'ayah-tafsir');
        await h.tapRow(t, 'tafsir-share');
        expect(h.share.texts, [
          'تفسير الآيتين\n\nفقرة ثانية\n\n[سورة البقرة: 6]\nتفسير السعدي',
        ]);
      },
    );

    testWidgets(
      'a dismissed share shows nothing; a failed one shows its message',
      (t) async {
        final h = AyahHarness()..share.outcome = ShareOutcome.dismissed;
        await h.pump(t);
        await h.open(t);
        await h.tapRow(t, 'ayah-tafsir');
        await h.tapRow(t, 'tafsir-share');
        expect(key('ayah-status'), findsNothing);
        h.share.failure = const ShareFailure(ShareFailureKind.couldNotShare);
        await h.tapRow(t, 'tafsir-share');
        expect(find.text('تعذّرت المشاركة'), findsOneWidget);
      },
    );
  });

  group('translation view', () {
    testWidgets('shows the English text left to right under its labels', (
      t,
    ) async {
      final h = AyahHarness();
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-translation');
      expect(find.text('الترجمة'), findsWidgets);
      expect(find.text('Saheeh International'), findsOneWidget);
      expect(find.text('شرح بشري وليس من نص القرآن'), findsOneWidget);
      final english = find.text('English verse 6');
      expect(english, findsOneWidget);
      expect(Directionality.of(t.element(english)), TextDirection.ltr);
      expect(t.widget<Text>(english).textAlign, TextAlign.left);
      expect(find.textContaining('كلمةقرآنية'), findsNothing);
    });

    testWidgets(
      'its share button hands the English text, the reference and the source name to the share sheet',
      (t) async {
        final h = AyahHarness();
        await h.pump(t);
        await h.open(t);
        await h.tapRow(t, 'ayah-translation');
        await h.tapRow(t, 'translation-share');
        expect(h.share.texts, [
          'English verse 6\n\n[سورة البقرة: 6]\nSaheeh International',
        ]);
      },
    );
  });

  group('moving between the menu and the views', () {
    testWidgets('the back arrow returns to the menu', (t) async {
      final h = AyahHarness();
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-translation');
      await h.tapRow(t, 'ayah-back');
      expect(find.text(header6), findsOneWidget);
      expect(key('ayah-share'), findsOneWidget);
      expect(find.text('English verse 6'), findsNothing);
    });

    testWidgets(
      'system back leaves the view first and closes the sheet only from the menu',
      (t) async {
        final h = AyahHarness();
        await h.pump(t);
        await h.open(t);
        await h.tapRow(t, 'ayah-tafsir');
        await t.binding.handlePopRoute();
        await settleAsync(t);
        expect(
          key('ayah-share'),
          findsOneWidget,
          reason: 'back to the menu, sheet still open',
        );
        expect(h.closed, 0);
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(h.closed, 1);
        expect(find.text(header6), findsNothing);
      },
    );

    testWidgets(
      'a view that cannot load its data says so and the sheet keeps working',
      (t) async {
        final files = viewFiles()..remove('assets/ayah/translation/002.json');
        final h = AyahHarness(files: files);
        await h.pump(t);
        await h.open(t);
        await h.tapRow(t, 'ayah-translation');
        expect(find.text('تعذّر تحميل هذا القسم'), findsOneWidget);
        await h.tapRow(t, 'ayah-back');
        expect(key('ayah-share'), findsOneWidget);
      },
    );
  });
}

String _jsonString(String s) => '"${s.replaceAll('\n', r'\n')}"';
