import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';

import '../support/ayah_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets(
    'the menu has a «معاني الكلمات» row, a labelled button at least 48 px tall',
    (t) async {
      final h = AyahHarness();
      await h.pump(t);
      await h.open(t);
      expect(key('ayah-meanings'), findsOneWidget);
      expect(t.getSize(key('ayah-meanings')).height, greaterThanOrEqualTo(48));
      expect(
        find.descendant(
          of: key('ayah-meanings'),
          matching: find.text('معاني الكلمات'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'lists each difficult word in bold with its meaning below and the source of the book',
    (t) async {
      final h =
          AyahHarness(); // 2:6 has two entries, one from each classical book
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-meanings');
      expect(find.text('معاني الكلمات'), findsOneWidget);
      expect(find.text('شرح بشري وليس من نص القرآن'), findsOneWidget);
      for (final word in ['كلمة', 'عبارة']) {
        expect(
          t.widget<Text>(find.text(word)).style?.fontWeight,
          FontWeight.w700,
          reason: word,
        );
      }
      expect(
        t.getTopLeft(find.text('كلمة')).dy,
        lessThan(t.getTopLeft(find.text('معنى الكلمة')).dy),
      );
      expect(
        t.getTopLeft(find.text('عبارة')).dy,
        greaterThan(t.getTopLeft(find.text('معنى الكلمة')).dy),
        reason: 'in order',
      );
      expect(
        find.text('ابن الهائم · التبيان في تفسير غريب القرآن'),
        findsOneWidget,
      );
      expect(
        find.text('ابن الجوزي · تذكرة الأريب في تفسير الغريب'),
        findsOneWidget,
      );
      expect(find.text('لا توجد كلمات غريبة في هذه الآية'), findsNothing);
    },
  );

  testWidgets(
    'an ayah with no difficult words says so instead of an empty list',
    (t) async {
      final h = AyahHarness(ref: const AyahRef(2, 7));
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-meanings');
      expect(find.text('لا توجد كلمات غريبة في هذه الآية'), findsOneWidget);
      expect(
        find.text('ابن الهائم · التبيان في تفسير غريب القرآن'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'is set apart from the Quran text: no Quran words, and no share button',
    (t) async {
      final h = AyahHarness();
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-meanings');
      expect(find.textContaining('كلمةقرآنية'), findsNothing);
      expect(find.byIcon(Icons.share_outlined), findsNothing);
    },
  );

  testWidgets('the back arrow returns to the menu', (t) async {
    final h = AyahHarness();
    await h.pump(t);
    await h.open(t);
    await h.tapRow(t, 'ayah-meanings');
    await h.tapRow(t, 'ayah-back');
    expect(key('ayah-share'), findsOneWidget);
    expect(find.text('معنى الكلمة'), findsNothing);
  });

  testWidgets(
    'data that cannot be read gives the load-failure message and the sheet keeps working',
    (t) async {
      final files = viewFiles()..remove('assets/ayah/gharib/002.json');
      final h = AyahHarness(files: files);
      await h.pump(t);
      await h.open(t);
      await h.tapRow(t, 'ayah-meanings');
      expect(find.text('تعذّر تحميل هذا القسم'), findsOneWidget);
      await h.tapRow(t, 'ayah-back');
      expect(key('ayah-share'), findsOneWidget);
    },
  );
}
