// The Emerald & Gold look must stay exactly as it was before feature 004 (spec FR-002, SC-003): every token of
// `AppLook.emerald` is today's constant or literal, and `buildAppTheme()` still builds today's theme.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/theme.dart';

void main() {
  group(
    'AppLook.emerald tokens are today\'s values (data-model.md AppLook)',
    () {
      const l = AppLook.emerald;

      test('colours taken from AppColors', () {
        expect(l.background, AppColors.green);
        expect(l.barFill, AppColors.greenDeep);
        expect(l.barBorder, AppColors.greenLine);
        expect(l.line, AppColors.greenLine);
        expect(l.heading, AppColors.gold);
        expect(l.accent, AppColors.gold);
        expect(l.accentAlt, AppColors.goldDark);
        expect(l.text, AppColors.ivory);
        expect(l.textSecondary, AppColors.muted);
        expect(l.cardFill, AppColors.paper);
        expect(l.cardInk, AppColors.ink);
        expect(l.cardBorderStrong, AppColors.goldDark);
        expect(l.cardBorderActive, AppColors.gold);
        expect(l.controlBorder, AppColors.goldDark);
        expect(l.primaryFill, AppColors.gold);
        expect(l.onPrimary, AppColors.green);
        expect(l.doneFill, AppColors.green);
        expect(l.ring, AppColors.ring);
      });

      test('colours that were literals in the screens', () {
        expect(l.cardMuted, const Color(0xFF2C4A3F));
        expect(l.cardBorder, const Color(0xFFCDBE8E));
        expect(l.cardDivider, const Color(0xFFE2D6A9));
        expect(l.cardDisabled, const Color(0xFF8A8F86));
        expect(l.onDone, const Color(0xFFF3E3A6));
        expect(
          l.textDim.toARGB32(),
          AppColors.muted.withValues(alpha: 0.75).toARGB32(),
          reason: 'About draws its quiet lines in muted at 75%',
        );
      });

      test('shapes', () {
        expect(l.cardRadius, 16);
        expect(l.strongBorderWidth, 2);
        expect(l.pillShapes, isFalse);
        expect(l.roundAddButton, isFalse);
        expect(l.dotMarkers, isFalse);
        expect(l.floatingBar, isFalse);
        expect(l.buttonRadius(10), 10, reason: 'a screen keeps its own radius');
        expect(l.buttonRadius(14), 14);
        expect(l.tagRadius(8), 8);
      });
    },
  );

  group('buildAppTheme() is today\'s theme', () {
    final theme = buildAppTheme();

    test('colour scheme', () {
      final s = theme.colorScheme;
      expect(s.brightness, Brightness.dark);
      expect(s.primary, AppColors.gold);
      expect(s.onPrimary, AppColors.green);
      expect(s.secondary, AppColors.goldDark);
      expect(s.onSecondary, AppColors.green);
      expect(s.error, const Color(0xFFFFB4A9));
      expect(s.onError, const Color(0xFF410002));
      expect(s.surface, AppColors.green);
      expect(s.onSurface, AppColors.ivory);
      expect(s.surfaceContainerHighest, AppColors.greenDeep);
      expect(s.outline, AppColors.goldDark);
      expect(s.outlineVariant, AppColors.greenLine);
    });

    test('scaffold, app bar, tabs, list tile, divider', () {
      expect(theme.scaffoldBackgroundColor, AppColors.green);
      expect(theme.appBarTheme.backgroundColor, AppColors.green);
      expect(theme.appBarTheme.foregroundColor, AppColors.gold);
      expect(theme.appBarTheme.titleTextStyle?.color, AppColors.gold);
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 26);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.tabBarTheme.labelColor, AppColors.gold);
      expect(theme.tabBarTheme.unselectedLabelColor, AppColors.muted);
      expect(theme.tabBarTheme.indicatorColor, AppColors.gold);
      expect(theme.tabBarTheme.dividerColor, AppColors.greenLine);
      expect(theme.listTileTheme.textColor, AppColors.ivory);
      expect(theme.listTileTheme.iconColor, AppColors.gold);
      expect(theme.dividerTheme.color, AppColors.greenLine);
    });

    test('inputs and buttons', () {
      final input = theme.inputDecorationTheme;
      expect(
        (input.border as OutlineInputBorder).borderSide.color,
        AppColors.goldDark,
      );
      expect(
        (input.focusedBorder as OutlineInputBorder).borderSide,
        const BorderSide(color: AppColors.gold, width: 2),
      );
      expect(input.labelStyle?.color, AppColors.muted);
      final filled = theme.filledButtonTheme.style!;
      expect(filled.backgroundColor?.resolve({}), AppColors.gold);
      expect(filled.foregroundColor?.resolve({}), AppColors.green);
      expect(filled.minimumSize?.resolve({}), const Size(64, 48));
      expect(
        theme.textButtonTheme.style!.foregroundColor?.resolve({}),
        AppColors.gold,
      );
    });

    test('the theme carries the Emerald look', () {
      expect(theme.extension<AppLook>(), AppLook.emerald);
    });
  });

  group('context.look', () {
    testWidgets(
      'is Emerald under a plain MaterialApp (tests that set no look)',
      (t) async {
        late AppLook seen;
        await t.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                seen = context.look;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(seen, AppLook.emerald);
      },
    );

    testWidgets('is the look of the Theme above it', (t) async {
      late AppLook seen;
      await t.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(look: AppLook.night),
          home: Builder(
            builder: (context) {
              seen = context.look;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppLook.night);
    });
  });
}
