// The look reaches the app: provided, applied from the first frame, switched without a restart (spec FR-003,
// FR-015, SC-006; contracts/dart-interfaces.md `lib/app.dart`).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:provider/provider.dart';

import '../support/look_harness.dart';

class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);

  final void Function(BuildContext) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox();
  }
}

void main() {
  testWidgets('the first frame is already in the saved look', (t) async {
    final a = await LookApp.create(t, choice: LookChoice.night);
    Color? scaffold;
    AppLook? look;
    await t.pumpWidget(
      a.app(
        home: _Probe((c) {
          scaffold = Theme.of(c).scaffoldBackgroundColor;
          look = c.look;
        }),
      ),
    );
    expect(scaffold, AppLook.night.background);
    expect(look, AppLook.night);
  });

  testWidgets('a look that is Emerald, or none at all, gives today\'s theme', (
    t,
  ) async {
    final a = await LookApp.create(t);
    AppLook? withEmerald;
    await t.pumpWidget(a.app(home: _Probe((c) => withEmerald = c.look)));
    expect(withEmerald, AppLook.emerald);
    AppLook? without;
    await t.pumpWidget(
      a.app(withLook: false, home: _Probe((c) => without = c.look)),
    );
    expect(without, AppLook.emerald);
  });

  testWidgets(
    'a widget under the app reads the same AppLookSettings, or null',
    (t) async {
      final a = await LookApp.create(t);
      AppLookSettings? seen;
      await t.pumpWidget(
        a.app(home: _Probe((c) => seen = c.read<AppLookSettings?>())),
      );
      expect(identical(seen, a.look), isTrue);
      await t.pumpWidget(
        a.app(
          withLook: false,
          home: _Probe((c) => seen = c.read<AppLookSettings?>()),
        ),
      );
      expect(seen, isNull);
    },
  );

  testWidgets(
    'choosing a look changes the open app at once and keeps the route',
    (t) async {
      final a = await LookApp.create(t);
      final looks = <AppLook>[];
      await t.pumpWidget(
        a.app(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      Scaffold(body: _Probe((c) => looks.add(c.look))),
                ),
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      );
      await t.tap(find.text('افتح'));
      await t.pumpAndSettle();
      expect(looks.last, AppLook.emerald);
      await a.choose(t, LookChoice.night);
      expect(
        looks.last,
        AppLook.night,
        reason: 'the open route is rebuilt in the new look',
      );
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'still on the pushed route',
      );
      await a.choose(t, LookChoice.emerald);
      expect(looks.last, AppLook.emerald);
    },
  );

  testWidgets('the theme is switched instantly, with no fade', (t) async {
    final a = await LookApp.create(t);
    await t.pumpWidget(a.app(home: const SizedBox()));
    expect(
      t.widget<MaterialApp>(find.byType(MaterialApp)).themeAnimationDuration,
      Duration.zero,
    );
  });

  test('both looks are dark, so the system bars keep light icons in both', () {
    expect(buildAppTheme().colorScheme.brightness, Brightness.dark);
    expect(
      buildAppTheme(look: AppLook.night).colorScheme.brightness,
      Brightness.dark,
    );
  });
}
