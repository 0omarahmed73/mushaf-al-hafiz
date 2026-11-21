// A look change fades softly (feature 010, task T035, spec FR-012; research D6, D11): the picture of the old look is laid over
// the new one and fades out in 220 ms; the new theme and the saved choice are in place on the first frame; with «remove
// animations» on, or with no host, it is the instant switch of feature 004; a look change with Settings open fades over
// Settings; the picture never takes a tap.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/motion/look_fade.dart';
import 'package:mushaf/settings/look_tile.dart';
import 'package:mushaf/theme.dart';

import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// The picture that is laid over the app while a look fades out.
Finder get picture => find.byType(RawImage);

double pictureOpacity(WidgetTester t) {
  final fade = find.ancestor(
    of: picture,
    matching: find.byType(FadeTransition),
  );
  return t.widget<FadeTransition>(fade.first).opacity.value;
}

/// A screen with the look tile, as Settings has it, and a button that opens another screen with the tile.
class _Home extends StatelessWidget {
  const _Home({this.onBuild});

  final void Function(AppLook)? onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild?.call(context.look);
    return Scaffold(
      body: ListView(
        children: [
          const LookTile(),
          TextButton(
            key: const ValueKey('open-settings'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  key: const ValueKey('second-screen'),
                  body: const LookTile(),
                ),
              ),
            ),
            child: const Text('open'),
          ),
          TextButton(
            key: const ValueKey('probe-button'),
            onPressed: () => probeTaps++,
            child: const Text('probe'),
          ),
        ],
      ),
    );
  }
}

int probeTaps = 0;

/// Lets the real async work of a tap (the picture of the screen, the database) finish, then draws a frame.
Future<void> letItRun(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await t.pump();
}

void main() {
  setUp(() => probeTaps = 0);

  testWidgets(
    'a tap on the other look: the new theme and the saved choice are in the first frame, the old look fades out over 220 ms',
    (t) async {
      final a = await LookApp.create(t);
      AppLook? seen;
      await t.pumpWidget(a.app(home: _Home(onBuild: (l) => seen = l)));
      await t.pump();
      expect(seen, AppLook.emerald);
      expect(picture, findsNothing);

      await t.tap(key('look-night'));
      await letItRun(t); // the picture was taken, the look set, the fade started (some real time has passed too)
      // The new look is in place at once: nothing interpolates between the two.
      expect(seen, AppLook.night);
      expect(a.look.choice, LookChoice.night);
      expect(await t.runAsync(a.repo.appLookRaw), LookChoice.night.name);
      expect(picture, findsOneWidget);
      expect(pictureOpacity(t), greaterThan(0.5));

      await t.pump(const Duration(milliseconds: 100));
      expect(picture, findsOneWidget);
      expect(pictureOpacity(t), lessThan(1.0));
      expect(pictureOpacity(t), greaterThan(0.0));

      await t.pump(const Duration(milliseconds: 140)); // 240 ms: past 220 ms
      expect(picture, findsNothing);
    },
  );

  testWidgets(
    'the picture never takes a tap: the screen under it answers while it fades',
    (t) async {
      final a = await LookApp.create(t);
      await t.pumpWidget(a.app(home: const _Home()));
      await t.pump();
      await t.tap(key('look-night'));
      await letItRun(t);
      expect(picture, findsOneWidget);
      await t.tap(key('probe-button'));
      expect(probeTaps, 1);
      await t.pump(const Duration(milliseconds: 300));
      expect(picture, findsNothing);
    },
  );

  testWidgets('with Settings open the old look fades over Settings', (t) async {
    final a = await LookApp.create(t);
    await t.pumpWidget(a.app(home: const _Home()));
    await t.pump();
    await t.tap(key('open-settings'));
    await t.pumpAndSettle();
    expect(key('second-screen'), findsOneWidget);
    await t.tap(
      find.descendant(of: key('second-screen'), matching: key('look-night')),
    );
    await letItRun(t);
    expect(a.look.choice, LookChoice.night);
    expect(picture, findsOneWidget);
    // The picture is above the open screen: it is drawn after it (later in the paint order).
    final order = t.allWidgets.toList();
    expect(
      order.indexWhere((w) => w is RawImage),
      greaterThan(
        order.indexWhere((w) => w.key == const ValueKey('second-screen')),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(picture, findsNothing);
  });

  testWidgets(
    'with «remove animations» on it is the instant switch: no picture at all',
    (t) async {
      final a = await LookApp.create(t);
      await t.pumpWidget(
        a.app(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: const _Home(),
            ),
          ),
        ),
      );
      await t.pump();
      await t.tap(key('look-night'));
      await letItRun(t);
      expect(a.look.choice, LookChoice.night);
      expect(picture, findsNothing);
    },
  );

  testWidgets('with no host above it is just the change', (t) async {
    var ran = false;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('go'),
            onPressed: () => LookFade.around(context, () async => ran = true),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(key('go'));
    await t.pump();
    expect(ran, isTrue);
    expect(picture, findsNothing);
  });

  testWidgets('a change that throws still takes the picture away', (t) async {
    final a = await LookApp.create(t);
    await t.pumpWidget(
      a.app(
        home: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('boom'),
            onPressed: () => LookFade.around(
              context,
              () async => throw StateError('boom'),
            ).catchError((Object _) {}),
            child: const Text('boom'),
          ),
        ),
      ),
    );
    await t.pump();
    await t.tap(key('boom'));
    await letItRun(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(picture, findsNothing);
  });

  test('the app wraps its navigator in the host and the tile goes through LookFade, and the theme still never animates', () {
    final app = File('lib/app.dart').readAsStringSync();
    expect(app, contains('LookFadeHost'));
    expect(app, contains('themeAnimationDuration: Duration.zero'));
    expect(
      File('lib/settings/look_tile.dart').readAsStringSync(),
      contains('LookFade.around('),
    );
  });
}
