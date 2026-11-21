// The «المظهر» row inside the Settings screen and the look changing under the open screen (spec FR-001,
// FR-003, SC-001; the screen's other tests stay unchanged).
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/harness.dart' show settle;

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late AppLookSettings look;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    look = AppLookSettings(repo);
  });
  tearDown(() async {
    look.dispose();
    await db.close();
  });

  Widget app({
    AppLookSettings? setting,
    Widget home = const SettingsScreen(),
  }) => MushafApp(
    wirdRepository: repo,
    mushafRepository: MushafRepository(rootBundle),
    textSize: TextSizeSettings(repo),
    appLook: setting,
    home: home,
  );

  Future<void> pumpSettings(
    WidgetTester t, {
    AppLookSettings? setting,
    Size screen = const Size(412, 915),
  }) async {
    t.view.physicalSize = screen;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await MushafRepository(rootBundle).loadMeta();
      await repo.ensureDefaults();
    });
    await t.pumpWidget(app(setting: setting));
    await settle(t);
  }

  testWidgets('the row is the first section of Settings, above the reminders', (
    t,
  ) async {
    await pumpSettings(t, setting: look);
    expect(key('look-title'), findsOneWidget);
    expect(
      t.getTopLeft(key('look-title')).dy,
      lessThan(t.getTopLeft(key('kahf-switch')).dy),
    );
    expect(key('look-emerald'), findsOneWidget);
    expect(key('look-night'), findsOneWidget);
    expect(key('look-note'), findsOneWidget);
  });

  testWidgets('choosing Night changes the Settings screen itself at once', (
    t,
  ) async {
    await pumpSettings(t, setting: look);
    expect(
      t.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      isNull,
    );
    expect(
      Theme.of(t.element(find.byType(Scaffold).first)).scaffoldBackgroundColor,
      AppLook.emerald.background,
    );
    await t.tap(key('look-night'));
    await t.pump();
    expect(
      Theme.of(t.element(find.byType(Scaffold).first)).scaffoldBackgroundColor,
      AppLook.night.background,
    );
    expect(look.choice, LookChoice.night);
    expect(
      key('look-title'),
      findsOneWidget,
      reason: 'still on the same screen',
    );
  });

  testWidgets(
    'a screen behind Settings is in the new look when the owner goes back',
    (t) async {
      t.view.physicalSize = const Size(412, 915);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.runAsync(() async {
        await MushafRepository(rootBundle).loadMeta();
        await repo.ensureDefaults();
      });
      Color? behind;
      await t.pumpWidget(
        app(
          setting: look,
          home: Builder(
            builder: (context) {
              behind = Theme.of(context).scaffoldBackgroundColor;
              return TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                child: const Text('إعدادات'),
              );
            },
          ),
        ),
      );
      await t.tap(find.text('إعدادات'));
      await settle(t);
      await t.tap(key('look-night'));
      await t.pump();
      expect(
        behind,
        AppLook.night.background,
        reason: 'the route below was rebuilt too',
      );
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.text('إعدادات'), findsOneWidget);
    },
  );

  testWidgets('the choice survives a new app on the same database', (t) async {
    await pumpSettings(t, setting: look);
    await t.tap(key('look-night'));
    await t.pump();
    await t.pumpWidget(const SizedBox());
    final again = AppLookSettings(repo);
    addTearDown(again.dispose);
    await t.runAsync(again.load);
    expect(again.choice, LookChoice.night);
    await t.pumpWidget(app(setting: again));
    await settle(t);
    expect(
      Theme.of(t.element(find.byType(Scaffold).first)).scaffoldBackgroundColor,
      AppLook.night.background,
    );
  });

  testWidgets(
    'without a look setting the row is not shown and Settings is as before',
    (t) async {
      await pumpSettings(t);
      expect(key('look-title'), findsNothing);
      expect(key('kahf-switch'), findsOneWidget);
    },
  );
}
