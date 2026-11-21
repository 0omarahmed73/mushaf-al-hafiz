// «المظهر» in Settings: two options with a colour sample, the chosen one marked, saved at once (spec FR-001,
// FR-003, FR-014, FR-018, SC-001; contracts/ui.md "Settings row").
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/settings/look_tile.dart';
import 'package:mushaf/theme.dart';

import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  Future<LookApp> pumpTile(
    WidgetTester t, {
    LookChoice choice = LookChoice.emerald,
    Size screen = const Size(412, 915),
    double textScale = 1.0,
    bool withLook = true,
  }) async {
    t.view.physicalSize = screen;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final a = await LookApp.create(t, choice: choice);
    await t.pumpWidget(
      a.app(
        withLook: withLook,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 6, 18, 40),
                child: LookTile(),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    return a;
  }

  testWidgets('shows the title, the two options and the note', (t) async {
    await pumpTile(t);
    expect(t.widget<Text>(key('look-title')).data, 'المظهر');
    expect(
      find.descendant(
        of: key('look-emerald'),
        matching: find.text('زمردي وذهبي'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: key('look-night'),
        matching: find.text('القارئ الليلي'),
      ),
      findsOneWidget,
    );
    expect(
      t.widget<Text>(key('look-note')).data,
      'يُطبَّق على التطبيق كله وعلى الصورة وملف PDF اللذين تشاركهما',
    );
    expect(LookTile.kEmerald, 'زمردي وذهبي');
    expect(LookTile.kNight, 'القارئ الليلي');
  });

  testWidgets(
    'Emerald is chosen by default: a check and an outline on it only',
    (t) async {
      await pumpTile(t);
      expect(
        find.descendant(
          of: key('look-emerald'),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('look-night'),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('each option has a colour sample of its own look', (t) async {
    await pumpTile(t);
    Set<Color> colours(String option) => {
      for (final d in t.widgetList<DecoratedBox>(
        find.descendant(
          of: key('look-swatch-$option'),
          matching: find.byType(DecoratedBox),
        ),
      ))
        if ((d.decoration as BoxDecoration).color != null)
          (d.decoration as BoxDecoration).color!,
    };
    expect(
      colours('emerald'),
      containsAll([
        AppLook.emerald.background,
        AppLook.emerald.cardFill,
        AppLook.emerald.accent,
      ]),
    );
    expect(
      colours('night'),
      containsAll([
        AppLook.night.background,
        AppLook.night.cardFill,
        AppLook.night.accent,
      ]),
    );
  });

  testWidgets('a tap on the other option saves it at once and moves the mark', (
    t,
  ) async {
    final a = await pumpTile(t);
    await t.tap(key('look-night'));
    await t.pump();
    expect(a.look.choice, LookChoice.night);
    expect(await t.runAsync(a.repo.appLookRaw), 'night');
    expect(
      find.descendant(
        of: key('look-night'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: key('look-emerald'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNothing,
    );
    await t.tap(key('look-emerald'));
    await t.pump();
    expect(a.look.choice, LookChoice.emerald);
  });

  testWidgets('the tile follows a look chosen elsewhere', (t) async {
    final a = await pumpTile(t);
    await a.choose(t, LookChoice.night);
    expect(
      find.descendant(
        of: key('look-night'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'semantics: each option is a button with its name, the chosen one is selected',
    (t) async {
      final handle = t.ensureSemantics();
      await pumpTile(t);
      final emerald = t.getSemantics(key('look-emerald'));
      final night = t.getSemantics(key('look-night'));
      expect(emerald.label, contains('زمردي وذهبي'));
      expect(night.label, contains('القارئ الليلي'));
      expect(emerald.flagsCollection.isButton, isTrue);
      expect(night.flagsCollection.isButton, isTrue);
      expect(
        emerald.flagsCollection.isSelected,
        isNot(night.flagsCollection.isSelected),
      );
      expect(emerald.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    },
  );

  testWidgets('targets are at least 56 px high and 48 px wide', (t) async {
    await pumpTile(t);
    for (final k in ['look-emerald', 'look-night']) {
      final s = t.getSize(key(k));
      expect(s.height, greaterThanOrEqualTo(56), reason: k);
      expect(s.width, greaterThanOrEqualTo(48), reason: k);
    }
  });

  testWidgets('side by side on a wide window, Emerald on the right (Arabic)', (
    t,
  ) async {
    await pumpTile(t);
    final e = t.getTopLeft(key('look-emerald'));
    final n = t.getTopLeft(key('look-night'));
    expect(e.dy, n.dy, reason: 'one row');
    expect(
      e.dx,
      greaterThan(n.dx),
      reason: 'the first option is at the start, the right',
    );
  });

  testWidgets('stacked on a 320 dp window, nothing overflows', (t) async {
    await pumpTile(t, screen: const Size(320, 640));
    expect(
      t.getTopLeft(key('look-night')).dy,
      greaterThan(t.getTopLeft(key('look-emerald')).dy),
    );
    expect(t.getSize(key('look-night')).width, greaterThan(250));
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'stacked with a 2x system font on 320 dp, nothing overflows, targets stay',
    (t) async {
      await pumpTile(t, screen: const Size(320, 640), textScale: 2.0);
      expect(t.takeException(), isNull);
      expect(t.getSize(key('look-emerald')).height, greaterThanOrEqualTo(56));
      expect(
        t.getTopLeft(key('look-night')).dy,
        greaterThan(t.getTopLeft(key('look-emerald')).dy),
      );
    },
  );

  testWidgets(
    'it draws in Night too, and shows nothing without a look setting',
    (t) async {
      await pumpTile(t, choice: LookChoice.night);
      expect(key('look-night'), findsOneWidget);
      await pumpTile(t, withLook: false);
      expect(key('look-title'), findsNothing);
      expect(key('look-emerald'), findsNothing);
    },
  );
}
