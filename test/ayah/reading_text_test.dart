import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ui/reading_text.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

void main() {
  group('ReadingStyles', () {
    test('at 100% they are exactly the sizes the ayah views had before', () {
      const s = ReadingStyles(1.0);
      expect((s.arabic.fontSize, s.arabic.height), (17, 1.8));
      expect((s.english.fontSize, s.english.height), (17, 1.6));
      expect(
        (s.meaningWord.fontSize, s.meaningWord.fontWeight),
        (18, FontWeight.w700),
      );
      expect((s.meaningText.fontSize, s.meaningText.height), (16, 1.7));
      expect(s.note.fontSize, 13);
      expect(s.note.fontWeight, FontWeight.w600);
      expect(s.note.color, const Color(0xFF2C4A3F));
      expect(s.source.fontSize, 12);
      expect(s.source.color, const Color(0xFF2C4A3F));
    });

    test('every size is the old size times the factor', () {
      const big = ReadingStyles(1.5);
      expect(big.arabic.fontSize, 25.5);
      expect(big.english.fontSize, 25.5);
      expect(big.meaningWord.fontSize, 27);
      expect(big.meaningText.fontSize, 24);
      expect(big.note.fontSize, 19.5);
      expect(big.source.fontSize, 18);
      const small = ReadingStyles(0.8);
      expect(small.arabic.fontSize, closeTo(13.6, 1e-9));
      expect(small.source.fontSize, closeTo(9.6, 1e-9));
    });

    test('line heights, weights and colours do not change with the size', () {
      const a = ReadingStyles(1.0), b = ReadingStyles(1.4);
      expect(a.arabic.height, b.arabic.height);
      expect(a.english.height, b.english.height);
      expect(a.meaningText.height, b.meaningText.height);
      expect(a.note.color, b.note.color);
      expect(a.meaningWord.fontWeight, b.meaningWord.fontWeight);
    });
  });

  group('ReadingScope', () {
    late AppDatabase db;
    late TextSizeSettings settings;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = TextSizeSettings(WirdRepository(db));
    });
    tearDown(() async {
      settings.dispose();
      await db.close();
    });

    Widget app({
      required double systemScale,
      TextSizeSettings? size,
      required Widget child,
    }) {
      return ListenableProvider<TextSizeSettings?>.value(
        value: size,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(systemScale)),
          child: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      );
    }

    testWidgets(
      'of() is the styles at the chosen size, and 100% without a setting',
      (t) async {
        ReadingStyles? seen;
        await t.pumpWidget(
          app(
            systemScale: 1,
            size: settings,
            child: Builder(
              builder: (context) {
                seen = ReadingScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(seen!.factor, 1.0);
        await t.runAsync(() => settings.set(120));
        await t.pump();
        expect(seen!.factor, 1.2);
        await t.pumpWidget(
          app(
            systemScale: 1,
            size: null,
            child: Builder(
              builder: (context) {
                seen = ReadingScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(seen!.factor, 1.0);
      },
    );

    testWidgets('a widget with no provider at all reads 100%', (t) async {
      ReadingStyles? seen;
      await t.pumpWidget(
        Builder(
          builder: (context) {
            seen = ReadingScope.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(seen!.factor, 1.0);
    });

    testWidgets('the system text scale times the size is kept at 3x at most', (
      t,
    ) async {
      // 2.0 x 150% = 3.0 is allowed; 3.0 x 150% would be 4.5, so the system part is cut to 2.0.
      Future<double> measure(double system, int percent) async {
        await t.runAsync(() => settings.set(percent));
        double? result;
        await t.pumpWidget(
          app(
            systemScale: system,
            size: settings,
            child: ReadingScope(
              child: Builder(
                builder: (context) {
                  result = MediaQuery.textScalerOf(context).scale(10);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        return result!;
      }

      expect(
        await measure(1.0, 150),
        10,
        reason: 'a normal phone is untouched',
      );
      expect(await measure(2.0, 150), 20, reason: '2.0 x 1.5 = 3.0 is allowed');
      expect(
        await measure(3.0, 150),
        20,
        reason: 'cut to 2.0 so that it stays at 3x',
      );
      expect(
        await measure(3.0, 100),
        30,
        reason: 'at 100% the system scale up to 3 is untouched',
      );
      expect(
        await measure(0.8, 80),
        closeTo(8, 1e-9),
        reason: 'smaller system scales stay',
      );
    });
  });
}
