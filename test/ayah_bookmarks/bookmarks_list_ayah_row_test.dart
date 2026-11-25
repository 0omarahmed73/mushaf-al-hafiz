// The row of an ayah bookmark in «علامات» (feature 013, task T022; spec FR-010, SC-006; contracts/ui.md §4): its title, page,
// note and owner, a mark that is not colour (its own icon and the word «آية»), one list newest first, the same swipe, and a
// tap that hands the ayah back as an AyahTarget. Page rows are as they were.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/bookmarks_sheet.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import '../support/ayah_bookmark_harness.dart';

class ListHarness {
  ListHarness(this.db, this.repo, this.meta);

  final AppDatabase db;
  final WirdRepository repo;
  final MushafMeta meta;
  final List<Object?> popped = [];
}

Future<ListHarness> pumpList(
  WidgetTester t, {
  Future<void> Function(AppDatabase db, WirdRepository repo, MushafMeta meta)?
  seed,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  final meta = (await t.runAsync(realMeta))!;
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  await t.runAsync(() async {
    await repo.ensureDefaults();
    if (seed != null) await seed(db, repo, meta);
  });
  final h = ListHarness(db, repo, meta);
  await t.pumpWidget(
    Provider<WirdRepository>.value(
      value: repo,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: const ValueKey('open'),
                onPressed: () async {
                  h.popped.add(
                    await showModalBottomSheet<Object>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BookmarksSheet(
                        page: 48,
                        ownerName: null,
                        onAdd: (_) async {},
                        meta: meta,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(byKey('open'));
  for (var i = 0; i < 6; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
  return h;
}

Finder tile(int id) => byKey('bookmark-$id');

void main() {
  late int ayahId;
  late int pageId;

  Future<void> seedTwo(
    AppDatabase db,
    WirdRepository repo,
    MushafMeta meta,
  ) async {
    pageId = await repo.addBookmark(77, 'صفحة', wirdId: 1);
    ayahId = await seedAyahBookmark(
      db,
      meta,
      const AyahRef(2, 282),
      wirdId: 1,
      note: 'أراجع هنا',
      at: DateTime(2099),
    );
  }

  testWidgets(
    'an ayah row: title, page, note, owner tag, its icon and its label',
    (t) async {
      final semantics = t.ensureSemantics();
      await pumpList(t, seed: seedTwo);
      final row = tile(ayahId);
      expect(
        find.descendant(
          of: row,
          matching: find.text(kAyahRowTitle('البقرة', 282)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('ص 48')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('أراجع هنا')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('الورد اليومي')),
        findsOneWidget,
      );
      final icon = byKey('bookmark-ayah-icon-$ayahId');
      expect(find.descendant(of: row, matching: icon), findsOneWidget);
      expect(t.widget<Icon>(icon).icon, Icons.auto_stories_outlined);
      expect(
        t
            .widget<Text>(
              find.descendant(of: row, matching: find.text('أراجع هنا')),
            )
            .maxLines,
        3,
      );
      expect(
        find.bySemanticsLabel(kAyahRowLabel('البقرة', 282, 48, 'الورد اليومي')),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets('a page row is as it was: no icon, «ص P», its note and tag', (
    t,
  ) async {
    await pumpList(t, seed: seedTwo);
    final row = tile(pageId);
    expect(find.descendant(of: row, matching: find.byType(Icon)), findsNothing);
    expect(
      find.descendant(of: row, matching: find.text('ص 77')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('صفحة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('الورد اليومي')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.textContaining('آية')),
      findsNothing,
    );
  });

  testWidgets('one list, newest first, and a general ayah row says «عامة»', (
    t,
  ) async {
    late int general;
    await pumpList(
      t,
      seed: (db, repo, meta) async {
        await seedTwo(db, repo, meta);
        general = await seedAyahBookmark(
          db,
          meta,
          const AyahRef(1, 1),
          at: DateTime(2000),
        );
      },
    );
    final tops = [
      for (final id in [ayahId, pageId, general]) t.getRect(tile(id)).top,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(
      find.descendant(
        of: tile(general),
        matching: find.text(kAyahOwnerGeneral),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tile(general),
        matching: find.text('سورة الفاتحة · آية 1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'a tap on an ayah row pops an AyahTarget, on a page row the page',
    (t) async {
      final h = await pumpList(t, seed: seedTwo);
      await t.tap(tile(ayahId));
      await t.pumpAndSettle();
      final target = h.popped.single as AyahTarget;
      expect((target.ref, target.page), (const AyahRef(2, 282), 48));
      await t.tap(byKey('open'));
      await t.pumpAndSettle();
      await t.tap(tile(pageId));
      await t.pumpAndSettle();
      expect(h.popped.last, 77);
    },
  );

  testWidgets('the swipe deletes an ayah row and a page row', (t) async {
    final h = await pumpList(t, seed: seedTwo);
    for (final id in [ayahId, pageId]) {
      await t.drag(tile(id), const Offset(-500, 0));
      await t.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    expect(await t.runAsync(() => allBookmarks(h.db)), isEmpty);
  });

  testWidgets(
    'at 320 dp with a 2x font a long surah name does not push «ص P» out',
    (t) async {
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = previous);
      late int id;
      final h = await pumpList(
        t,
        screen: const Size(320, 640),
        textScale: 2,
        seed: (db, repo, meta) async {
          id = await seedAyahBookmark(
            db,
            meta,
            const AyahRef(63, 11),
            wirdId: 1,
            note: 'ملاحظة',
          );
        },
      );
      FlutterError.onError = previous;
      expect(errors.where((e) => e.contains('overflowed')), isEmpty);
      final row = t.getRect(tile(id));
      final page = t.getRect(
        find.descendant(
          of: tile(id),
          matching: find.text('ص ${h.meta.pageOfAyah(63, 11)}'),
        ),
      );
      expect(page.left, greaterThanOrEqualTo(row.left));
      expect(page.right, lessThanOrEqualTo(row.right));
    },
  );
}
