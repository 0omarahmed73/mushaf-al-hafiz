// The «حجم الخط» row inside the Settings screen (spec FR-001; the screen's other tests stay unchanged).
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/harness.dart' show settle;

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late TextSizeSettings size;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    size = TextSizeSettings(repo);
  });
  tearDown(() async {
    size.dispose();
    await db.close();
  });

  Future<void> pumpSettings(
    WidgetTester t, {
    TextSizeSettings? setting,
    Size screen = const Size(412, 915),
  }) async {
    t.view.physicalSize = screen;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await MushafRepository(rootBundle).loadMeta();
      await repo.ensureDefaults();
    });
    await t.pumpWidget(
      MushafApp(
        wirdRepository: repo,
        mushafRepository: MushafRepository(rootBundle),
        textSize: setting,
        home: const SettingsScreen(),
      ),
    );
    await settle(t);
  }

  testWidgets(
    'the row is on the screen after the reminders and before «عن التطبيق»',
    (t) async {
      await pumpSettings(t, setting: size);
      expect(key('text-size-title'), findsOneWidget);
      expect(key('text-size-slider'), findsOneWidget);
      final kahf = t.getTopLeft(key('kahf-switch')).dy;
      final sizeRow = t.getTopLeft(key('text-size-title')).dy;
      expect(sizeRow, greaterThan(kahf));
      await t.scrollUntilVisible(
        key('open-about'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        t.getTopLeft(key('open-about')).dy,
        greaterThan(t.getTopLeft(key('text-size-reset')).dy),
      );
    },
  );

  testWidgets('moving the slider in Settings saves the size', (t) async {
    await pumpSettings(t, setting: size);
    t.widget<Slider>(key('text-size-slider')).onChanged!(130);
    await t.pump();
    expect(size.percent, 130);
    expect(await t.runAsync(repo.textSizeRaw), '130');
  });

  testWidgets('without a size setting in the app the row is not shown', (
    t,
  ) async {
    await pumpSettings(t);
    expect(key('text-size-title'), findsNothing);
    expect(key('kahf-switch'), findsOneWidget);
  });

  testWidgets(
    'the whole screen with the row fits a small phone without overflow',
    (t) async {
      await pumpSettings(t, setting: size, screen: const Size(320, 568));
      await t.scrollUntilVisible(
        key('text-size-reset'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.scrollUntilVisible(
        key('open-about'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(t.takeException(), isNull);
    },
  );
}
