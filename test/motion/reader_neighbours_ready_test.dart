// Feature 010 T012 (FR-002, SC-002): the next and the previous page are built while the reader rests, so the first frames of
// a swipe build and lay out nothing for the incoming page; and the earlier tests still see one page.
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';

import '../support/motion_harness.dart';

/// Every label in the semantics tree, as a screen reader would meet them.
List<String> _labels(WidgetTester t) {
  final labels = <String>[];
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
  return labels;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a screen reader meets the shown page only: the neighbours at rest are not in the semantics tree',
    (t) async {
      final handle = t.ensureSemantics();
      await pumpMotionReader(t, startPage: 50, withWird: false);
      await t.pump();
      final labels = _labels(t);
      expect(labels.where((l) => l.contains('50')), isNotEmpty);
      expect(
        labels.where((l) => l == '49' || l == '51'),
        isEmpty,
        reason: 'the neighbours are built but not read out',
      );
      handle.dispose();
    },
  );

  testWidgets(
    'at rest both neighbours are built with their text, and finders still see one page',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: false);
      expect(find.byType(MushafPage, skipOffstage: false), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('page-number')),
        findsOneWidget,
        reason: 'neighbours are offstage for finders',
      );
      expect(
        find.byType(MushafPageLoading, skipOffstage: false),
        findsNothing,
        reason: 'no neighbour is still a page-number-only card',
      );
    },
  );

  for (final withWird in [false, true]) {
    final mode = withWird ? 'wird mode' : 'browse mode';
    testWidgets(
      'a swipe in $mode builds nothing in the first frames and at most one page in all',
      (t) async {
        final reader = await pumpMotionReader(
          t,
          startPage: 50,
          withWird: withWird,
        );
        await reader.swipeToNext(t, prefix: 'turn-');
        expect(
          reader.probe.countAll('turn-a', 'MushafPage'),
          0,
          reason: 'finger down',
        );
        expect(
          reader.probe.countAll('turn-b', 'MushafPage'),
          0,
          reason: 'dragging',
        );
        expect(
          reader.probe.countAll('turn-c', 'MushafPage'),
          0,
          reason: 'past the middle',
        );
        expect(
          reader.probe.countAll('turn-', 'MushafPage'),
          lessThanOrEqualTo(1),
          reason: 'only the next neighbour, at the end',
        );
        expect(
          find.byType(MushafPage, skipOffstage: false),
          findsNWidgets(3),
          reason: 'the new neighbours are ready again',
        );
      },
    );
  }
}
