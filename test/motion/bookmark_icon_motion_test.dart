// The bookmark icon changes softly (feature 010, task T033, spec FR-011): when a tap flips its state the icon of the other
// state is the only one in the tree, it starts at 0.8 size and transparent and is at full size and colour 160 ms later;
// the 48 x 48 target and the one semantics node of feature 006 do not change; with «remove animations» it is the end state
// in the next frame.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/bookmark_button.dart';
import 'package:mushaf/theme.dart';

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> pumpButton(
  WidgetTester t,
  ValueNotifier<bool> state, {
  bool disableAnimations = false,
}) async {
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(look: AppLook.emerald),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: BookmarkButton(page: 5, bookmarked: state, onPressed: () {}),
          ),
        ),
      ),
    ),
  );
}

Finder icon(IconData data) =>
    find.descendant(of: key('bookmark-button'), matching: find.byIcon(data));

/// The opacity and the scale the icon is drawn with right now.
({double opacity, double scale}) drawn(WidgetTester t, IconData data) {
  final fade = find.ancestor(
    of: icon(data),
    matching: find.byType(FadeTransition),
  );
  final scale = find.ancestor(of: fade.first, matching: find.byType(Transform));
  return (
    opacity: t.widget<FadeTransition>(fade.first).opacity.value,
    scale: t.widget<Transform>(scale.first).transform.entry(0, 0),
  );
}

void main() {
  testWidgets(
    'the first build shows the icon as it is: opaque, full size, no motion',
    (t) async {
      final state = ValueNotifier<bool>(true);
      addTearDown(state.dispose);
      await pumpButton(t, state);
      final d = drawn(t, Icons.bookmark_added);
      expect(d.opacity, 1.0);
      expect(d.scale, closeTo(1.0, 1e-9));
      expect(t.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'after a tap the other icon is the only one, 0.8 and transparent, then full 160 ms later',
    (t) async {
      final state = ValueNotifier<bool>(false);
      addTearDown(state.dispose);
      await pumpButton(t, state);
      expect(icon(Icons.bookmark_add_outlined), findsOneWidget);

      state.value = true;
      await t.pump(); // the first frame of the new state
      // One icon at any time (the feature 006 expectation): the outlined one is already gone.
      expect(icon(Icons.bookmark_added), findsOneWidget);
      expect(icon(Icons.bookmark_add_outlined), findsNothing);
      final first = drawn(t, Icons.bookmark_added);
      expect(first.opacity, closeTo(0.0, 0.05));
      expect(first.scale, closeTo(0.8, 0.02));

      await t.pump(const Duration(milliseconds: 80));
      final middle = drawn(t, Icons.bookmark_added);
      expect(middle.opacity, greaterThan(0.1));
      expect(middle.opacity, lessThan(1.0));
      expect(middle.scale, greaterThan(0.8));
      expect(middle.scale, lessThan(1.0));

      await t.pump(
        const Duration(milliseconds: 90),
      ); // 170 ms in all, 160 ms is the duration
      final last = drawn(t, Icons.bookmark_added);
      expect(last.opacity, 1.0);
      expect(last.scale, closeTo(1.0, 1e-9));
      // (The IconButton's own 200 ms colour change from feature 006 may still run: it is the framework's, not this motion.)
    },
  );

  testWidgets(
    'the 48 x 48 target and the one semantics node are the same before, during and after',
    (t) async {
      final handle = t.ensureSemantics();
      final state = ValueNotifier<bool>(false);
      addTearDown(state.dispose);
      await pumpButton(t, state);
      final before = t.getSize(find.byType(IconButton));
      expect(before, const Size(48, 48));
      expect(key('bookmark-button'), findsOneWidget);

      state.value = true;
      await t.pump();
      for (final ms in [0, 40, 80, 120]) {
        await t.pump(Duration(milliseconds: ms));
        expect(t.getSize(find.byType(IconButton)), before, reason: '$ms ms');
        expect(key('bookmark-button'), findsOneWidget, reason: '$ms ms');
        expect(
          t.getSemantics(key('bookmark-button')),
          isSemantics(isButton: true),
          reason: '$ms ms',
        );
      }
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(IconButton)), before);
      handle.dispose(); // inside the test: the framework checks the handle before the tear-downs run
    },
  );

  testWidgets('with «remove animations» the end state is in the next frame', (
    t,
  ) async {
    final state = ValueNotifier<bool>(false);
    addTearDown(state.dispose);
    await pumpButton(t, state, disableAnimations: true);
    state.value = true;
    await t.pump();
    final d = drawn(t, Icons.bookmark_added);
    expect(d.opacity, 1.0);
    expect(d.scale, closeTo(1.0, 1e-9));
  });

  testWidgets('a rebuild with the same state does not restart the motion', (
    t,
  ) async {
    final state = ValueNotifier<bool>(true);
    addTearDown(state.dispose);
    await pumpButton(t, state);
    state.value = false;
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await pumpButton(t, state); // same state again
    await t.pump();
    final d = drawn(t, Icons.bookmark_add_outlined);
    expect(d.opacity, 1.0);
    expect(d.scale, closeTo(1.0, 1e-9));
  });
}
