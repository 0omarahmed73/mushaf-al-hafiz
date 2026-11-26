// Every piece of interface text is Cairo (the owner, 2026-11-26: «حدد موقعي» was drawn in the phone's own font).
// A theme style with no family (the filled buttons, Night's snack bar and tooltip) used to drop Cairo for that text.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/theme.dart';

String? _family(WidgetTester t, Finder of, String text) => t
    .widget<RichText>(
      find.descendant(of: of, matching: find.byType(RichText)).last,
    )
    .text
    .style
    ?.fontFamily;

void main() {
  for (final look in [AppLook.emerald, AppLook.night]) {
    final name = look == AppLook.night ? 'Night' : 'Emerald';

    testWidgets('$name: filled, outlined and text buttons draw in Cairo', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(look: look),
          home: Scaffold(
            body: Column(
              children: [
                FilledButton(
                  key: const ValueKey('f'),
                  onPressed: () {},
                  child: const Text('حدد موقعي'),
                ),
                FilledButton.icon(
                  key: const ValueKey('fi'),
                  onPressed: () {},
                  icon: const Icon(Icons.my_location),
                  label: const Text('حدد موقعي'),
                ),
                OutlinedButton(
                  key: const ValueKey('o'),
                  onPressed: () {},
                  child: const Text('غيّر المكان'),
                ),
                TextButton(
                  key: const ValueKey('x'),
                  onPressed: () {},
                  child: const Text('إيقاف'),
                ),
              ],
            ),
          ),
        ),
      );
      for (final k in ['f', 'fi', 'o', 'x']) {
        expect(_family(t, find.byKey(ValueKey(k)), ''), kUiFont, reason: k);
      }
    });

    testWidgets('$name: the snack bar and the tooltip draw in Cairo', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(look: look),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  const Tooltip(
                    key: ValueKey('tip'),
                    message: 'تلميح',
                    child: Text('؟'),
                  ),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت الإضافة')),
                    ),
                    child: const Text('اعرض'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('اعرض'));
      await t.pumpAndSettle();
      expect(_family(t, find.byType(SnackBar), ''), kUiFont);
      await t.longPress(find.byKey(const ValueKey('tip')));
      await t.pumpAndSettle();
      final tip = t.widget<RichText>(
        find
            .descendant(of: find.text('تلميح'), matching: find.byType(RichText))
            .first,
      );
      expect(tip.text.style?.fontFamily, kUiFont);
    });
  }
}
