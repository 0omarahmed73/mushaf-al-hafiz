import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
  });
  tearDown(() async {
    await db.close();
  });

  Future<void> pump(
    WidgetTester t, {
    TextSizeSettings? textSize,
    required Widget home,
  }) => t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: MushafRepository(rootBundle),
      textSize: textSize,
      home: home,
    ),
  );

  testWidgets('a widget under the app reads the same instance that was given', (
    t,
  ) async {
    final settings = TextSizeSettings(repo);
    addTearDown(settings.dispose);
    TextSizeSettings? seen;
    await pump(
      t,
      textSize: settings,
      home: Builder(
        builder: (context) {
          seen = context.read<TextSizeSettings?>();
          return const SizedBox();
        },
      ),
    );
    expect(identical(seen, settings), isTrue);
  });

  testWidgets(
    'without a setting the provider holds null, which every reader treats as 100%',
    (t) async {
      TextSizeSettings? seen = TextSizeSettings(repo);
      final unused = seen;
      addTearDown(unused.dispose);
      await pump(
        t,
        home: Builder(
          builder: (context) {
            seen = context.read<TextSizeSettings?>();
            return const SizedBox();
          },
        ),
      );
      expect(seen, isNull);
    },
  );

  testWidgets(
    'a widget that watches the setting rebuilds when the size changes',
    (t) async {
      final settings = TextSizeSettings(repo);
      addTearDown(settings.dispose);
      final built = <int>[];
      await pump(
        t,
        textSize: settings,
        home: Builder(
          builder: (context) {
            built.add(context.watch<TextSizeSettings?>()!.percent);
            return const SizedBox();
          },
        ),
      );
      expect(built, [100]);
      await t.runAsync(() => settings.set(130));
      await t.pump();
      expect(built, [100, 130]);
    },
  );
}
