// The helper that walks a pumped screen and reports every text or icon whose colour is too close to the colour
// behind it (spec FR-012, SC-005). Night screen tests use it so a pair the look's own list forgot is still found.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/contrast_walk.dart';

Widget host(Widget child, {Color? scaffold}) => MaterialApp(
  home: Scaffold(
    backgroundColor: scaffold ?? const Color(0xFF0D1014),
    body: child,
  ),
);

void main() {
  testWidgets('light text on a dark scaffold passes', (t) async {
    await t.pumpWidget(
      host(const Text('مرحبا', style: TextStyle(color: Color(0xFFECE7DC)))),
    );
    expect(contrastIssues(t), isEmpty);
  });

  testWidgets('dark text on a dark scaffold is reported with its ratio', (
    t,
  ) async {
    await t.pumpWidget(
      host(const Text('خافت', style: TextStyle(color: Color(0xFF2C4A3F)))),
    );
    final issues = contrastIssues(t);
    expect(issues, hasLength(1));
    expect(issues.single.text, 'خافت');
    expect(issues.single.ratio, lessThan(4.5));
    expect(issues.single.minimum, 4.5);
  });

  testWidgets(
    'the colour behind is the nearest painted one: a card hides the scaffold',
    (t) async {
      await t.pumpWidget(
        host(
          Container(
            color: const Color(0xFFFBF5E3),
            child: const Text(
              'على ورقة',
              style: TextStyle(color: Color(0xFF14231D)),
            ),
          ),
        ),
      );
      expect(
        contrastIssues(t),
        isEmpty,
        reason: 'ink on ivory is fine although the scaffold is dark',
      );
    },
  );

  testWidgets('a DecoratedBox and a Material are backgrounds too', (t) async {
    await t.pumpWidget(
      host(
        Column(
          children: const [
            DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF161B22)),
              child: Text('أ', style: TextStyle(color: Color(0xFF161B22))),
            ),
            Material(
              color: Color(0xFFFFFFFF),
              child: Text('ب', style: TextStyle(color: Color(0xFFFFFFFF))),
            ),
          ],
        ),
      ),
    );
    expect(contrastIssues(t).map((i) => i.text), unorderedEquals(['أ', 'ب']));
  });

  testWidgets('large text needs only 3:1', (t) async {
    // #6E7983 on #0D1014 is 4.29: fails as body text, passes as a 28 px title.
    await t.pumpWidget(
      host(
        Column(
          children: const [
            Text(
              'صغير',
              style: TextStyle(color: Color(0xFF6E7983), fontSize: 14),
            ),
            Text(
              'كبير',
              style: TextStyle(color: Color(0xFF6E7983), fontSize: 28),
            ),
          ],
        ),
      ),
    );
    expect(contrastIssues(t).map((i) => i.text), ['صغير']);
  });

  testWidgets('icons need 3:1', (t) async {
    await t.pumpWidget(
      host(
        Row(
          children: const [
            Icon(Icons.add, color: Color(0xFF2C4A3F)),
            Icon(Icons.add, color: Color(0xFF6CC4B5)),
          ],
        ),
      ),
    );
    final issues = contrastIssues(t);
    expect(issues, hasLength(1));
    expect(issues.single.kind, 'icon');
    expect(issues.single.minimum, 3.0);
  });

  testWidgets('content under reduced opacity (disabled items) is exempt', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const Opacity(
          opacity: 0.5,
          child: Text('قريباً', style: TextStyle(color: Color(0xFF2C4A3F))),
        ),
      ),
    );
    expect(contrastIssues(t), isEmpty);
  });

  testWidgets('a translucent background is blended onto what is behind it', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        Container(
          color: const Color(
            0x4D6CC4B5,
          ), // the Night highlight wash: teal at 30%
          child: const Text('مظلل', style: TextStyle(color: Color(0xFFECE7DC))),
        ),
      ),
    );
    expect(contrastIssues(t), isEmpty);
  });

  testWidgets('within limits the walk to one subtree', (t) async {
    await t.pumpWidget(
      host(
        Column(
          children: const [
            Text('خارج', style: TextStyle(color: Color(0xFF2C4A3F))),
            SizedBox(
              key: ValueKey('box'),
              child: Text('داخل', style: TextStyle(color: Color(0xFFECE7DC))),
            ),
          ],
        ),
      ),
    );
    expect(
      contrastIssues(t, within: find.byKey(const ValueKey('box'))),
      isEmpty,
    );
    expect(contrastIssues(t), hasLength(1));
  });
}
