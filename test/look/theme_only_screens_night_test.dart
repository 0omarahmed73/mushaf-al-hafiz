// Screens and widgets that take every colour from the theme, under the Night look (spec FR-004, FR-012, FR-014,
// SC-002): the index, the go-to-page dialog, a snack bar, text fields, a switch, a slider, a dialog, a bottom sheet,
// a popup menu, a tooltip and a tab bar. None keeps an ivory or bright fill, and the texts meet their contrast.
// Emerald & Gold is pinned too: its theme must not change.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/mushaf/go_to_page_dialog.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/theme.dart';

import '../support/contrast_walk.dart';
import '../support/harness.dart' show settle;
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// The painted fills that are bright (an ivory card, a light snack bar) among the widgets now on screen.
List<String> brightFills(WidgetTester t) {
  final found = <String>[];
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final c = (d.decoration as BoxDecoration).color;
    if (c != null && c.a > 0.5 && c.computeLuminance() > 0.5) {
      found.add('DecoratedBox #${c.toARGB32().toRadixString(16)}');
    }
  }
  for (final m in t.widgetList<Material>(find.byType(Material))) {
    final c = m.color;
    if (c != null && c.a > 0.5 && c.computeLuminance() > 0.5) {
      found.add('Material ${m.runtimeType} #${c.toARGB32().toRadixString(16)}');
    }
  }
  return found;
}

/// A screen with one of everything the theme styles, so a single pump covers the lot.
class _Gallery extends StatefulWidget {
  const _Gallery();

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  bool on = true;
  bool off = false;
  double value = 0.4;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('معرض')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TextField(
          key: ValueKey('field-empty'),
          decoration: InputDecoration(labelText: 'اسم'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('field-error'),
          decoration: const InputDecoration(
            labelText: 'صفحة',
            errorText: 'أدخل رقماً من 1 إلى 604',
          ),
          controller: TextEditingController(text: '700'),
        ),
        SwitchListTile(
          key: const ValueKey('switch-on'),
          title: const Text('مفعّل'),
          value: on,
          onChanged: (v) => setState(() => on = v),
        ),
        SwitchListTile(
          key: const ValueKey('switch-off'),
          title: const Text('غير مفعّل'),
          value: off,
          onChanged: (v) => setState(() => off = v),
        ),
        Slider(
          key: const ValueKey('slider'),
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
        const LinearProgressIndicator(value: 0.5),
        const SizedBox(height: 12),
        Tooltip(
          message: 'تلميح',
          child: IconButton(
            key: const ValueKey('tooltip-target'),
            onPressed: () {},
            icon: const Icon(Icons.info_outline),
          ),
        ),
        PopupMenuButton<String>(
          key: const ValueKey('popup'),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'a', child: Text('خيار')),
          ],
        ),
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                key: const ValueKey('show-snack'),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم النسخ'),
                    action: SnackBarAction(label: 'تراجع', onPressed: () {}),
                  ),
                ),
                child: const Text('snack'),
              ),
              TextButton(
                key: const ValueKey('show-dialog'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('حذف؟'),
                    content: const Text('لا يمكن التراجع.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                ),
                child: const Text('dialog'),
              ),
              TextButton(
                key: const ValueKey('show-sheet'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const SizedBox(
                    height: 120,
                    child: Center(child: Text('ورقة سفلية')),
                  ),
                ),
                child: const Text('sheet'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<LookApp> pumpHome(
  WidgetTester t,
  LookChoice choice,
  Widget home, {
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  final a = await LookApp.create(t, choice: choice);
  await a.show(t, home, defaults: false, screen: screen, textScale: textScale);
  return a;
}

void main() {
  group('Emerald & Gold keeps its theme', () {
    test('dialog, sheet, snack bar, slider and tooltip are the defaults', () {
      final theme = buildAppTheme();
      expect(theme.dialogTheme.backgroundColor, isNull);
      expect(theme.snackBarTheme.backgroundColor, isNull);
      expect(theme.bottomSheetTheme.backgroundColor, isNull);
      expect(theme.sliderTheme.activeTrackColor, isNull);
      expect(theme.popupMenuTheme.color, isNull);
      expect(theme.tooltipTheme.decoration, isNull);
      expect(theme.colorScheme.inverseSurface, theme.colorScheme.onSurface);
    });
  });

  group('Night theme components', () {
    final theme = buildAppTheme(look: AppLook.night);
    final n = AppLook.night;

    test(
      'dialog, popup menu, snack bar and tooltip are charcoal, not light',
      () {
        expect(theme.dialogTheme.backgroundColor, n.cardFill);
        expect(theme.popupMenuTheme.color, n.cardFill);
        expect(theme.snackBarTheme.backgroundColor, n.cardFill);
        expect(theme.snackBarTheme.actionTextColor, n.accent);
        expect(theme.colorScheme.inverseSurface, n.cardFill);
        expect(theme.colorScheme.onInverseSurface, n.cardInk);
        final tip = theme.tooltipTheme.decoration! as BoxDecoration;
        expect(tip.color, n.cardFill);
      },
    );

    test('slider has a teal active track on the hairline', () {
      expect(theme.sliderTheme.activeTrackColor, n.accent);
      expect(theme.sliderTheme.inactiveTrackColor, n.line);
      expect(theme.sliderTheme.thumbColor, n.accent);
    });

    test('the dialog and the popup menu use the card radius', () {
      final dialog = theme.dialogTheme.shape! as RoundedRectangleBorder;
      expect(dialog.borderRadius, BorderRadius.circular(20));
      final popup = theme.popupMenuTheme.shape! as RoundedRectangleBorder;
      expect(popup.borderRadius, BorderRadius.circular(16));
    });
  });

  group('Night screens', () {
    testWidgets(
      'the index: surahs, parts and the page field have no bright fill and meet the contrast',
      (t) async {
        await pumpHome(t, LookChoice.night, const IndexScreen());
        await settle(t);
        for (final tab in ['السور', 'الأجزاء', 'صفحة']) {
          await t.tap(find.text(tab));
          await settle(t);
          expect(brightFills(t), isEmpty, reason: tab);
          final issues = contrastIssues(t);
          expect(issues, isEmpty, reason: '$tab\n${issues.join('\n')}');
        }
      },
    );

    testWidgets('the go-to-page dialog is charcoal and readable', (t) async {
      await pumpHome(
        t,
        LookChoice.night,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const ValueKey('open'),
              onPressed: () => showDialog<int>(
                context: context,
                builder: (_) => const GoToPageDialog(current: 42),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.tap(key('open'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GoToPageDialog), findsOneWidget);
      expect(brightFills(t), isEmpty);
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
      // An error state too.
      await t.enterText(find.byType(TextField), '999');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(contrastIssues(t), isEmpty);
    });

    testWidgets('fields, switches, slider, progress and tab bar', (t) async {
      await pumpHome(t, LookChoice.night, const _Gallery());
      expect(brightFills(t), isEmpty);
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });

    for (final what in ['snack', 'dialog', 'sheet']) {
      testWidgets(
        'the $what is not a bright block and its texts meet the contrast',
        (t) async {
          await pumpHome(t, LookChoice.night, const _Gallery());
          await t.tap(key('show-$what'));
          await t.pump();
          await t.pump(const Duration(milliseconds: 400));
          expect(brightFills(t), isEmpty);
          final issues = contrastIssues(t);
          expect(issues, isEmpty, reason: issues.join('\n'));
        },
      );
    }

    testWidgets('the popup menu and the tooltip are charcoal', (t) async {
      await pumpHome(t, LookChoice.night, const _Gallery());
      await t.tap(key('popup'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('خيار'), findsOneWidget);
      expect(brightFills(t), isEmpty);
      expect(contrastIssues(t), isEmpty);
      await t.tapAt(const Offset(5, 5));
      await t.pump(const Duration(milliseconds: 300));
      await t.longPress(key('tooltip-target'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('تلميح'), findsOneWidget);
      expect(brightFills(t), isEmpty);
      expect(contrastIssues(t), isEmpty);
    });
  });

  for (final look in LookChoice.values) {
    testWidgets(
      '${look.name}: the gallery, the index and the dialog do not overflow on 320 dp with a 2x font',
      (t) async {
        await pumpHome(
          t,
          look,
          const _Gallery(),
          screen: const Size(320, 640),
          textScale: 2.0,
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await pumpHome(
          t,
          look,
          const IndexScreen(),
          screen: const Size(320, 640),
          textScale: 2.0,
        );
        await settle(t);
        expect(t.takeException(), isNull);
      },
    );
  }
}
