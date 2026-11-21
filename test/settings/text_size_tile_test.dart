// The «حجم الخط» row of Settings: slider with eight stops, live preview, note and reset (spec FR-001, FR-002,
// FR-004, FR-017; contracts/ui.md).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/settings/text_size_tile.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late TextSizeSettings size;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    size = TextSizeSettings(repo);
  });
  tearDown(() async {
    size.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester t, {TextSizeSettings? setting}) =>
      t.pumpWidget(
        ListenableProvider<TextSizeSettings?>.value(
          value: setting,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildAppTheme(),
            home: Scaffold(body: ListView(children: const [TextSizeTile()])),
          ),
        ),
      );

  double fontOf(WidgetTester t, String k) =>
      t.widget<Text>(key(k)).style!.fontSize!;

  testWidgets('shows the title and the value at the default size', (t) async {
    await pump(t, setting: size);
    expect(t.widget<Text>(key('text-size-title')).data, 'حجم الخط');
    expect(t.widget<Text>(key('text-size-value')).data, '100%');
  });

  testWidgets('without a setting in the app it shows nothing', (t) async {
    await pump(t);
    expect(key('text-size-title'), findsNothing);
    expect(key('text-size-slider'), findsNothing);
  });

  testWidgets(
    'the slider has eight stops from 80 to 150 and starts at the stored size',
    (t) async {
      await t.runAsync(() => size.set(120));
      await pump(t, setting: size);
      final slider = t.widget<Slider>(key('text-size-slider'));
      expect(
        (slider.min, slider.max, slider.divisions, slider.value),
        (80, 150, 7, 120),
      );
    },
  );

  testWidgets('the 100% stop is marked', (t) async {
    await pump(t, setting: size);
    expect(key('text-size-default-mark'), findsOneWidget);
  });

  testWidgets(
    'the preview shows an Arabic and an English sample at today\'s sizes',
    (t) async {
      await pump(t, setting: size);
      expect(find.text('معاينة'), findsOneWidget);
      expect(
        t.widget<Text>(key('text-size-preview-ar')).data,
        'هذه فقرة تجريبية تُعرض بحجم نص التفسير، لترى الحجم قبل أن تعود إلى القراءة.',
      );
      expect(
        t.widget<Text>(key('text-size-preview-en')).data,
        'This is a sample sentence shown at the size of the translation.',
      );
      expect(fontOf(t, 'text-size-preview-ar'), 17);
      expect(fontOf(t, 'text-size-preview-en'), 17);
      final en = t.widget<Text>(key('text-size-preview-en'));
      expect(
        Directionality.of(t.element(key('text-size-preview-en'))),
        TextDirection.ltr,
      );
      expect(en.textAlign, TextAlign.left);
    },
  );

  testWidgets('the note says where the size applies', (t) async {
    await pump(t, setting: size);
    expect(
      find.text('يُطبَّق على التفسير والترجمة ومعاني الكلمات وعلى صفحة المصحف'),
      findsOneWidget,
    );
  });

  testWidgets(
    'moving the slider changes the value and the preview at once and saves the size',
    (t) async {
      await pump(t, setting: size);
      t.widget<Slider>(key('text-size-slider')).onChanged!(140);
      await t.pump();
      expect(t.widget<Text>(key('text-size-value')).data, '140%');
      expect(fontOf(t, 'text-size-preview-ar'), closeTo(17 * 1.4, 1e-9));
      expect(fontOf(t, 'text-size-preview-en'), closeTo(17 * 1.4, 1e-9));
      expect(size.percent, 140);
      expect(await t.runAsync(repo.textSizeRaw), '140');
    },
  );

  testWidgets(
    'in an RTL screen a finger moving left raises the size and moving right lowers it',
    (t) async {
      await pump(t, setting: size);
      await t.drag(key('text-size-slider'), const Offset(-2000, 0));
      await t.pump();
      expect(size.percent, 150);
      await t.drag(key('text-size-slider'), const Offset(2000, 0));
      await t.pump();
      expect(size.percent, 80);
      expect(fontOf(t, 'text-size-preview-ar'), closeTo(17 * 0.8, 1e-9));
    },
  );

  testWidgets(
    '«الحجم الافتراضي» is off at 100% and returns to 100% when pressed',
    (t) async {
      await pump(t, setting: size);
      expect(t.widget<TextButton>(key('text-size-reset')).onPressed, isNull);
      t.widget<Slider>(key('text-size-slider')).onChanged!(130);
      await t.pump();
      final reset = t.widget<TextButton>(key('text-size-reset'));
      expect(reset.onPressed, isNotNull);
      expect(
        find.descendant(
          of: key('text-size-reset'),
          matching: find.text('الحجم الافتراضي'),
        ),
        findsOneWidget,
      );
      await t.tap(key('text-size-reset'));
      await t.pump();
      expect(size.percent, 100);
      expect(t.widget<Slider>(key('text-size-slider')).value, 100);
      expect(t.widget<Text>(key('text-size-value')).data, '100%');
      expect(fontOf(t, 'text-size-preview-ar'), 17);
      expect(t.widget<TextButton>(key('text-size-reset')).onPressed, isNull);
    },
  );

  testWidgets('the slider and the reset button are at least 48 px high', (
    t,
  ) async {
    await pump(t, setting: size);
    t.widget<Slider>(key('text-size-slider')).onChanged!(120);
    await t.pump();
    expect(t.getSize(key('text-size-slider')).height, greaterThanOrEqualTo(48));
    expect(t.getSize(key('text-size-reset')).height, greaterThanOrEqualTo(48));
  });

  testWidgets('screen readers hear the title and the value', (t) async {
    final handle = t.ensureSemantics();
    await t.runAsync(() => size.set(120));
    await pump(t, setting: size);
    final node = find.semantics.byValue('120%').evaluate().single;
    final data = node.getSemanticsData();
    expect(data.label, contains('حجم الخط'));
    expect(data.value, contains('120%'));
    handle.dispose();
  });

  testWidgets('a very large phone text scale does not overflow the row', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.runAsync(() => size.set(150));
    await pump(t, setting: size);
    expect(t.takeException(), isNull);
  });
}
