// Position, wirds and jumps in the large-ayah view (feature 015, User Story 3; FR-012, FR-013; research D6; SC-004).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:mushaf/wirds/wirds_screen.dart';

import '../support/large_ayah_harness.dart';
import '../support/reader_harness.dart';
import '../support/reader_search_harness.dart' show popIndexWith;

Future<void> _readInto(WidgetTester t, int page) async {
  var guard = 0;
  while (shownLargeScreen(t).screen.page != page && guard++ < 40) {
    await nextScreen(t);
  }
  expect(shownLargeScreen(t).screen.page, page);
}

void main() {
  testWidgets('inside the active wird, reading into the next page moves the wird there', (t) async {
    final r = await pumpLargeReader(t, startPage: 10, on: true);
    expect(await r.wirdPage(t), 10);
    await _readInto(t, 11);
    expect(await r.wirdPage(t), 11);
  });

  testWidgets('after a jump the view browses: reading on moves no wird', (t) async {
    final r = await pumpLargeReader(t, startPage: 10, on: true);
    await popIndexWith(t, 20);
    await settleReader(t);
    expect(shownLargeScreen(t).screen.page, 20, reason: 'a jump opens the first screen of its page');
    await _readInto(t, 21);
    expect(await r.wirdPage(t), 10);
  });

  testWidgets('the first ayah of the screen shown is remembered', (t) async {
    final r = await pumpLargeReader(t, startPage: 3, on: true);
    expect(shownLargeScreen(t).screen.ayat.first, const AyahRef(2, 6));
    await nextScreen(t);
    final first = shownLargeScreen(t).screen.ayat.first;
    expect(first, const AyahRef(2, 7));
    expect(r.settings.at, first);
    expect(await t.runAsync(r.repo.largeAyahAtRaw), '2:7');
  });

  testWidgets('a restart opens at the remembered ayah when it is on the position\'s page', (t) async {
    await pumpLargeReader(t, startPage: 3, on: true, at: const AyahRef(2, 9));
    expect(shownLargeScreen(t).screen.ayat.first, const AyahRef(2, 9));
  });

  testWidgets('a restart opens at the page\'s first screen when the remembered ayah is elsewhere', (t) async {
    await pumpLargeReader(t, startPage: 3, on: true, at: const AyahRef(2, 30));
    expect(shownLargeScreen(t).screen.ayat.first, const AyahRef(2, 6));
  });

  testWidgets('a search result opens the screen that holds its ayah, highlighted', (t) async {
    await pumpLargeReader(t, startPage: 10, on: true);
    await popIndexWith(t, const AyahTarget(AyahRef(3, 5), 50));
    await settleReader(t);
    final s = shownLargeScreen(t);
    expect(s.screen.ayat, contains(const AyahRef(3, 5)));
    final ids = {
      for (final w in s.screen.words)
        if (w.surah == 3 && w.ayah == 5) w.id,
    };
    expect(s.highlightedWordIds, containsAll(ids));
    expect(
      t
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((d) => (d.decoration as BoxDecoration?)?.color == PageLook.screen.highlight),
      isNotEmpty,
    );
  });

  testWidgets('the «اذهب إلى صفحة» page jump re-anchors too', (t) async {
    await pumpLargeReader(t, startPage: 10, on: true);
    await popIndexWith(t, 300);
    await settleReader(t);
    expect(shownLargeScreen(t).screen.page, 300);
  });

  testWidgets('a wird switch while the view is on opens the first screen of that wird\'s page', (t) async {
    final r = await pumpLargeReader(t, startPage: 10, on: true);
    final id = (await t.runAsync(
      () => r.repo.create(const WirdDraft(name: 'تجربة', type: WirdType.reading, startPage: 200, color: 0xFF1565C0)),
    ))!;
    await t.tap(find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: find.text('أوراد')));
    await settleReader(t);
    Navigator.of(t.element(find.byType(WirdsScreen))).pop(id);
    await settleReader(t);
    await settleReader(t);
    expect(shownLargeScreen(t).screen.page, 200);
  });
}
