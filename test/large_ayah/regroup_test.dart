// Choosing 1, 2 or 3 ayat per screen and the size (feature 015, User Story 2; FR-006, FR-007, FR-009, FR-019).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/large_ayah/large_ayah_settings.dart';
import 'package:mushaf/large_ayah/large_ayah_tile.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import '../support/large_ayah_harness.dart';
import '../support/reader_harness.dart';

Future<void> _set(WidgetTester t, Future<void> Function() change) async {
  await t.runAsync(change);
  await settleReader(t);
  await settleReader(t);
}

void main() {
  testWidgets('the count regroups at once, on the screen that holds the same first ayah (FR-007)', (t) async {
    final r = await pumpLargeReader(t, startPage: 3, on: true, at: const AyahRef(2, 7));
    expect(largeHeader(t), 'البقرة ٧ · صفحة ٣');
    expect(shownLargeScreen(t).screen.ayat, [const AyahRef(2, 7)]);
    // Screens are cut from the page's first ayah (FR-008): 2:7 may now share a screen with 2:6 before it.
    await _set(t, () => r.settings.setCount(2));
    var ayat = shownLargeScreen(t).screen.ayat;
    expect(ayat, contains(const AyahRef(2, 7)));
    expect(ayat.length, inInclusiveRange(1, 2));
    await _set(t, () => r.settings.setCount(3));
    ayat = shownLargeScreen(t).screen.ayat;
    expect(ayat, contains(const AyahRef(2, 7)));
    expect(ayat.length, inInclusiveRange(1, 3));
    await _set(t, () => r.settings.setCount(1));
    expect(shownLargeScreen(t).screen.ayat, [const AyahRef(2, 7)]);
  });

  testWidgets('short ayat fill the screen with the chosen count', (t) async {
    await pumpLargeReader(t, startPage: 604, on: true, count: 3);
    final ayat = shownLargeScreen(t).screen.ayat;
    expect(ayat.length, 3, reason: 'the first ayat of page 604 are short');
  });

  testWidgets('a size step and a rotation keep the first ayah', (t) async {
    final r = await pumpLargeReader(t, startPage: 3, on: true, at: const AyahRef(2, 9));
    expect(shownLargeScreen(t).screen.ayat.first, const AyahRef(2, 9));
    final before = shownLargeScreen(t).geometry.fontSize;
    await _set(t, () => r.settings.setSizeStep(3));
    expect(shownLargeScreen(t).screen.ayat, contains(const AyahRef(2, 9)));
    expect(shownLargeScreen(t).geometry.fontSize, greaterThan(before));
    t.view.physicalSize = const Size(915, 412);
    await settleReader(t);
    await settleReader(t);
    expect(shownLargeScreen(t).screen.ayat, contains(const AyahRef(2, 9)));
    expect(t.takeException(), isNull);
  });

  testWidgets('a split ayah re-anchors at its first part', (t) async {
    final r = await pumpLargeReader(t, startPage: 48, on: true, sizeStep: 3);
    expect(shownLargeScreen(t).screen.part?.number, 1);
    await nextScreen(t);
    expect(shownLargeScreen(t).screen.part?.number, 2);
    await _set(t, () => r.settings.setSizeStep(2));
    expect(shownLargeScreen(t).screen.ayat.single, const AyahRef(2, 282));
    expect(shownLargeScreen(t).screen.part?.number, 1);
  });

  testWidgets('the choices are kept: the app opens with them', (t) async {
    await pumpLargeReader(t, startPage: 604, on: true, count: 2, sizeStep: 2);
    expect(shownLargeScreen(t).screen.ayat.length, 2);
    expect(shownLargeScreen(t).geometry.fontSize, closeTo(2.5 * (412 - 32) / 16.2, 0.01));
  });

  testWidgets('the preview in Settings follows the size step', (t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final settings = LargeAyahSettings(WirdRepository(db));
    await t.runAsync(() => settings.setOn(true));
    await t.pumpWidget(
      ListenableProvider<LargeAyahSettings?>.value(
        value: settings,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: LargeAyahTile())),
        ),
      ),
    );
    double previewSize() => t.widget<Text>(find.byKey(const ValueKey('large-size-preview'))).style!.fontSize!;
    final small = previewSize();
    await t.runAsync(() => settings.setSizeStep(3));
    await t.pump();
    expect(previewSize(), closeTo(small * 1.5, 0.01));
    await t.pumpWidget(const SizedBox());
    settings.dispose();
    await t.runAsync(db.close);
  });
}
