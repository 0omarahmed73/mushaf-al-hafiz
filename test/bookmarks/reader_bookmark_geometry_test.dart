// The reader's top bar and page rectangles, recorded on the code BEFORE feature 006 (task T002) and kept as literals.
// The bookmark icon must not move the Mushaf page or change the bar (spec FR-003, SC-007; research D9).
//
// `exact` elements must stay exactly where they are forever. The second row (the wird pill, the «اليوم» chip and
// «اجعلها موضعي») is also exact here; task T010 replaces `secondRow` with the rule of the 48 px reserve.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/wirds/today_panel.dart';

import '../support/bookmark_harness.dart';

typedef R = List<double>; // left, top, right, bottom

R rect(WidgetTester t, Finder f) {
  final x = t.getRect(f);
  return [x.left, x.top, x.right, x.bottom];
}

void expectRect(String name, R actual, R expected) {
  expect(actual.length, 4, reason: '$name was not found');
  for (var i = 0; i < 4; i++) {
    expect(
      actual[i],
      closeTo(expected[i], 0.01),
      reason: '$name edge $i: $actual vs baseline $expected',
    );
  }
}

class Baseline {
  const Baseline({
    required this.topBar,
    required this.openIndex,
    required this.juzHizb,
    required this.pager,
    required this.pageNumber,
    required this.pill,
    required this.chip,
    this.makePosition,
  });
  final R topBar, openIndex, juzHizb, pager, pageNumber, pill, chip;
  final R? makePosition;
}

// Measured on the unchanged reader on 2026-11-21 (page 50 followed by the default wird, then page 51 in browse mode).
const wide = Size(412, 915);
const narrow = Size(320, 640);

final baselines = <(String, Size, bool, Baseline)>[
  (
    'wird',
    wide,
    false,
    Baseline(
      topBar: [0, 0, 412, 84],
      openIndex: [22, 5.5, 390, 34.5],
      juzHizb: [22, 12.25, 212, 25.44],
      pager: [0, 84, 412, 847],
      pageNumber: [191.75, 804, 220.25, 824],
      pill: [214, 48, 390, 73],
      chip: [22, 48.82, 206, 72.18],
    ),
  ),
  (
    'browse',
    wide,
    true,
    Baseline(
      topBar: [0, 0, 412, 84],
      openIndex: [22, 5.5, 390, 34.5],
      juzHizb: [22, 12.25, 212, 25.44],
      pager: [0, 84, 412, 847],
      pageNumber: [191.75, 804, 220.25, 824],
      pill: [275.33, 48, 390, 73],
      chip: [144.67, 52.71, 267.33, 68.29],
      makePosition: [29.67, 54.11, 137, 66.89],
    ),
  ),
  (
    'wird',
    narrow,
    false,
    Baseline(
      topBar: [0, 0, 320, 84],
      openIndex: [22, 10.03, 298, 29.97],
      juzHizb: [22, 16.78, 212, 29.97],
      pager: [0, 84, 320, 572],
      pageNumber: [145.75, 529, 174.25, 549],
      pill: [168, 43.47, 298, 68.47],
      chip: [22, 47.21, 160, 64.73],
    ),
  ),
  (
    'browse',
    narrow,
    true,
    Baseline(
      topBar: [0, 0, 320, 84],
      openIndex: [22, 10.03, 298, 29.97],
      juzHizb: [22, 16.78, 212, 29.97],
      pager: [0, 84, 320, 572],
      pageNumber: [145.75, 529, 174.25, 549],
      pill: [214, 43.47, 298, 68.47],
      chip: [114, 50.13, 206, 61.81],
      makePosition: [27.75, 51.18, 108.25, 60.76],
    ),
  ),
];

/// Today the second row must be exactly the baseline. Task T010 changes this function to the reserve rule
/// (right edges of the pill unchanged, nothing left of `topBar.left + 22 + 48` in the second row, no overlap with the
/// icon) and records the new numbers next to the old ones.
void secondRow(WidgetTester t, Baseline b) {
  final icon = t.getRect(key('bookmark-button'));
  final barLeft = t.getRect(key('top-bar')).left;
  const reserve = 22.0 + 48.0; // the bar's side padding plus the icon's 48 px
  final pill = t.getRect(key('wird-pill'));
  expect(
    pill.right,
    closeTo(b.pill[2], 0.01),
    reason: 'the pill stays anchored at the start edge',
  );
  expect(pill.top, closeTo(b.pill[1], 0.01));
  expect(pill.bottom, closeTo(b.pill[3], 0.01));
  final parts = <String, Rect>{
    'wird-pill': pill,
    'chip': t.getRect(find.byType(TodaySummaryChip)),
    if (b.makePosition != null)
      'make-position': t.getRect(find.text('اجعلها موضعي')),
  };
  final baselineCentre = <String, double>{
    'wird-pill': (b.pill[1] + b.pill[3]) / 2,
    'chip': (b.chip[1] + b.chip[3]) / 2,
    if (b.makePosition != null)
      'make-position': (b.makePosition![1] + b.makePosition![3]) / 2,
  };
  parts.forEach((name, r) {
    expect(
      r.left,
      greaterThanOrEqualTo(barLeft + reserve - 0.01),
      reason: '$name stays out of the 48 px kept for the icon',
    );
    expect(r.overlaps(icon), isFalse, reason: '$name does not touch the icon');
    expect(
      r.center.dy,
      closeTo(baselineCentre[name]!, 0.5),
      reason: '$name stays on the row it was on',
    );
  });
}

void main() {
  for (final look in LookChoice.values) {
    for (final (modeName, screen, browse, b) in baselines) {
      testWidgets(
        '${look.name} ${screen.width.toInt()} dp, $modeName: the bar and the page are where they were',
        (t) async {
          final reader = await pumpBookmarkReader(
            t,
            look: look,
            screen: screen,
            browseWithWird: browse,
          );
          expect(
            reader.unexpectedErrors,
            isEmpty,
            reason: 'only the bottom bar may overflow at 320 dp (T020)',
          );
          expectRect('top-bar', rect(t, key('top-bar')), b.topBar);
          expectRect('open-index', rect(t, key('open-index')), b.openIndex);
          expectRect('juz-hizb', rect(t, key('juz-hizb')), b.juzHizb);
          expectRect('pager', rect(t, find.byType(PageView)), b.pager);
          expectRect('page-number', rect(t, key('page-number')), b.pageNumber);
          secondRow(t, b);
          if (browse) {
            expect(find.text('اجعلها موضعي'), findsOneWidget);
          } else {
            expect(find.text('اجعلها موضعي'), findsNothing);
          }
        },
      );
    }
  }
}
