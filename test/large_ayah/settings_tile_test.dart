// The Settings tile of the large-ayah view (feature 015, FR-017, contracts/ui.md).
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/large_ayah/large_ayah_settings.dart';
import 'package:mushaf/large_ayah/large_ayah_strings.dart';
import 'package:mushaf/large_ayah/large_ayah_tile.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

import '../support/reader_harness.dart';

Future<LargeAyahSettings> _pump(
  WidgetTester t, {
  bool on = false,
  Size size = const Size(412, 915),
  double scale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.runAsync(db.close);
  });
  final repo = WirdRepository(db);
  final settings = LargeAyahSettings(repo);
  addTearDown(settings.dispose);
  await t.runAsync(() async {
    await repo.ensureDefaults();
    await settings.setOn(on);
  });
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: MushafRepository(rootBundle),
      largeAyah: settings,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => const SettingsScreen())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('open'));
  await settleReader(t);
  return settings;
}

void main() {
  testWidgets('the tile is the first entry of Settings', (t) async {
    await _pump(t);
    final tile = t.getTopLeft(find.byType(LargeAyahTile));
    for (final other in [find.text('التذكيرات')]) {
      expect(tile.dy, lessThan(t.getTopLeft(other).dy));
    }
    expect(find.text(LargeAyahStrings.title), findsOneWidget);
    expect(find.text(LargeAyahStrings.subtitle), findsOneWidget);
  });

  testWidgets('its switch turns the view on and returns to the reader', (t) async {
    final s = await _pump(t);
    expect(find.text(LargeAyahStrings.countTitle), findsNothing, reason: 'the choices show only while on');
    await t.tap(find.byKey(const ValueKey('large-ayah-switch')));
    await settleReader(t);
    expect(s.on, isTrue);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('while on: the count and the size, saved at once', (t) async {
    final s = await _pump(t, on: true);
    expect(find.text(LargeAyahStrings.countTitle), findsOneWidget);
    expect(find.text(LargeAyahStrings.sizeTitle), findsOneWidget);
    for (final label in [...LargeAyahStrings.counts, ...LargeAyahStrings.sizes]) {
      expect(find.text(label), findsOneWidget);
    }
    await t.tap(find.byKey(const ValueKey('large-count-2')));
    await settleReader(t);
    expect(s.count, 2);
    await t.tap(find.byKey(const ValueKey('large-size-3')));
    await settleReader(t);
    expect(s.sizeStep, 3);
    for (final k in ['large-count-1', 'large-count-3', 'large-size-1', 'large-size-2']) {
      final size = t.getSize(find.byKey(ValueKey(k)));
      expect(size.height, greaterThanOrEqualTo(48), reason: '$k target');
    }
    await t.tap(find.byKey(const ValueKey('large-ayah-switch')));
    await settleReader(t);
    expect(s.on, isFalse);
  });

  testWidgets('nothing overflows at 320 dp with a 2x system font', (t) async {
    await _pump(t, on: true, size: const Size(320, 640), scale: 2);
    expect(t.takeException(), isNull);
    await t.scrollUntilVisible(find.byKey(const ValueKey('large-size-3')), 100);
    expect(t.takeException(), isNull);
  });
}
