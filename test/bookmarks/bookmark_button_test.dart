// The icon button alone (feature 006, task T007): its two states, its size, its tooltip and its semantics.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/bookmark_button.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';
import 'package:mushaf/theme.dart';

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> pumpButton(
  WidgetTester t, {
  required ValueNotifier<bool> state,
  required VoidCallback onPressed,
  int page = 5,
  AppLook look = AppLook.emerald,
  void Function()? onParentBuild,
}) async {
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(look: look),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              onParentBuild?.call();
              return BookmarkButton(
                page: page,
                bookmarked: state,
                onPressed: onPressed,
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'outlined while the page has no bookmark, filled when it has one',
    (t) async {
      final state = ValueNotifier<bool>(false);
      addTearDown(state.dispose);
      await pumpButton(t, state: state, onPressed: () {});
      expect(
        find.descendant(
          of: key('bookmark-button'),
          matching: find.byIcon(Icons.bookmark_add_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('bookmark-button'),
          matching: find.byIcon(Icons.bookmark_added),
        ),
        findsNothing,
      );
      state.value = true;
      await t.pump();
      expect(
        find.descendant(
          of: key('bookmark-button'),
          matching: find.byIcon(Icons.bookmark_added),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.bookmark_add_outlined), findsNothing);
    },
  );

  testWidgets('changing the state rebuilds the icon alone, not its parent', (
    t,
  ) async {
    final state = ValueNotifier<bool>(false);
    addTearDown(state.dispose);
    var parentBuilds = 0;
    await pumpButton(
      t,
      state: state,
      onPressed: () {},
      onParentBuild: () => parentBuilds++,
    );
    expect(parentBuilds, 1);
    state.value = true;
    await t.pump();
    state.value = false;
    await t.pump();
    expect(parentBuilds, 1);
  });

  testWidgets('the target is at least 48 x 48 in both looks', (t) async {
    for (final look in [AppLook.emerald, AppLook.night]) {
      final state = ValueNotifier<bool>(false);
      addTearDown(state.dispose);
      await pumpButton(t, state: state, onPressed: () {}, look: look);
      final size = t.getSize(key('bookmark-button'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('a tap calls back once', (t) async {
    final state = ValueNotifier<bool>(false);
    addTearDown(state.dispose);
    var taps = 0;
    await pumpButton(t, state: state, onPressed: () => taps++);
    await t.tap(key('bookmark-button'));
    await t.pump();
    expect(taps, 1);
  });

  testWidgets('the tooltip names the action and the page, in both states', (
    t,
  ) async {
    final state = ValueNotifier<bool>(false);
    addTearDown(state.dispose);
    await pumpButton(t, state: state, onPressed: () {}, page: 604);
    expect(find.byTooltip(kBookmarkAdd(604)), findsOneWidget);
    state.value = true;
    await t.pump();
    expect(find.byTooltip(kBookmarkRemove(604)), findsOneWidget);
    expect(find.byTooltip(kBookmarkAdd(604)), findsNothing);
  });

  testWidgets('a screen reader hears a button, its action and its state', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    final state = ValueNotifier<bool>(false);
    addTearDown(state.dispose);
    await pumpButton(t, state: state, onPressed: () {}, page: 5);
    expect(
      t.getSemantics(key('bookmark-button')),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        label: kBookmarkAdd(5),
        value: kBookmarkStateOff,
      ),
    );
    state.value = true;
    await t.pump();
    expect(
      t.getSemantics(key('bookmark-button')),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        label: kBookmarkRemove(5),
        value: kBookmarkStateOn,
      ),
    );
    handle.dispose();
  });
}
