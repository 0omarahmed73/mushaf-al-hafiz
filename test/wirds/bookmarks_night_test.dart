// «علامات» in both looks (spec FR-004, FR-012, FR-014; contracts/ui.md «علامات»). Emerald keeps its ivory rows;
// Night puts charcoal rows on the dark sheet.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/bookmarks_sheet.dart';

import '../support/contrast_walk.dart';
import '../support/harness.dart' show settle;
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

Future<LookApp> open(
  WidgetTester t,
  LookChoice choice, {
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  final a = await LookApp.create(t, choice: choice);
  await t.runAsync(() async {
    await a.repo.ensureDefaults();
    await a.repo.addBookmark(77, 'آية الكرسي', wirdId: 1);
    await a.repo.addBookmark(293, null);
  });
  await a.show(
    t,
    Scaffold(
      body: BookmarksSheet(
        page: 5,
        ownerName: 'الورد اليومي',
        onAdd: (_) async {},
      ),
    ),
    screen: screen,
    textScale: textScale,
  );
  await settle(t);
  return a;
}

Material rowMaterial(WidgetTester t, int id) => t.widget<Material>(
  find
      .descendant(of: key('bookmark-$id'), matching: find.byType(Material))
      .first,
);

void main() {
  testWidgets('Emerald: ivory rows with their own radius and a gold heading', (
    t,
  ) async {
    await open(t, LookChoice.emerald);
    final row = rowMaterial(t, 1);
    expect(row.color, AppColors.paper);
    expect(row.borderRadius, BorderRadius.circular(14));
    final heading = t.widget<Text>(find.text('علامات'));
    expect(heading.style!.color, AppColors.gold);
    final add = t.widget<FilledButton>(key('bookmark-add'));
    expect(
      (add.style!.shape!.resolve({}) as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(14),
    );
  });

  group('Night', () {
    testWidgets('charcoal rows, light heading, pill add button', (t) async {
      await open(t, LookChoice.night);
      final row = rowMaterial(t, 1);
      expect(row.color, AppLook.night.cardFill);
      expect(row.borderRadius, BorderRadius.circular(20));
      final heading = t.widget<Text>(find.text('علامات'));
      expect(heading.style!.color, AppLook.night.heading);
      final add = t.widget<FilledButton>(key('bookmark-add'));
      expect(
        (add.style!.shape!.resolve({}) as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(999),
      );
      expect(find.text('آية الكرسي'), findsOneWidget);
    });

    testWidgets('every text and icon meets the contrast, rows included', (
      t,
    ) async {
      await open(t, LookChoice.night);
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });

    testWidgets('the swipe-to-delete background keeps a readable icon', (
      t,
    ) async {
      await open(t, LookChoice.night);
      await t.drag(key('bookmark-1'), const Offset(120, 0));
      await t.pump(const Duration(milliseconds: 200));
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });
  });

  for (final choice in LookChoice.values) {
    testWidgets(
      '${choice.name}: nothing overflows on a 320 dp window with a 2x system font',
      (t) async {
        await open(t, choice, screen: const Size(320, 640), textScale: 2.0);
        expect(t.takeException(), isNull);
        expect(key('bookmark-list'), findsOneWidget);
      },
    );
  }
}
