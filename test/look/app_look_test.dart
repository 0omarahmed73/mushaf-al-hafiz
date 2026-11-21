// The Night look: its tokens are the design's values with the two lifted colours, every pair of the required list
// meets its contrast, and every colour is either in a pair or listed as decorative (spec FR-005, FR-012, SC-005;
// data-model.md AppLook and "Required pairs").
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/theme.dart';

void main() {
  const n = AppLook.night;

  test(
    'colours are the design\'s values with the two lifted ones (data-model.md)',
    () {
      expect(n.background, const Color(0xFF0D1014));
      expect(n.barFill, const Color(0xFF161B22));
      expect(n.barBorder, const Color(0xFF232A33));
      expect(n.line, const Color(0xFF2B343D));
      expect(n.heading, const Color(0xFFECE7DC));
      expect(n.accent, const Color(0xFF6CC4B5));
      expect(n.accentAlt, const Color(0xFFE3B05A));
      expect(n.text, const Color(0xFFECE7DC));
      expect(n.textSecondary, const Color(0xFF9AA4AD));
      expect(
        n.textDim,
        const Color(0xFF85909B),
        reason: 'lifted from #6E7983 (4.29:1)',
      );
      expect(n.cardFill, const Color(0xFF161B22));
      expect(n.cardInk, const Color(0xFFECE7DC));
      expect(n.cardMuted, const Color(0xFF9AA4AD));
      expect(n.cardBorder, const Color(0xFF232A33));
      expect(n.cardBorderStrong, const Color(0xFF232A33));
      expect(n.cardBorderActive, const Color(0xFF6CC4B5));
      expect(n.cardDivider, const Color(0xFF232A33));
      expect(n.cardDisabled, const Color(0xFF6B7782));
      expect(
        n.controlBorder,
        const Color(0xFF5F6B76),
        reason: 'lifted from #2B343D (1.51:1)',
      );
      expect(n.primaryFill, const Color(0xFF6CC4B5));
      expect(n.onPrimary, const Color(0xFF08201C));
      expect(n.doneFill, const Color(0xFF6CC4B5));
      expect(n.onDone, const Color(0xFF08201C));
      expect(n.ring, const Color(0xFF46525E));
    },
  );

  test('shapes are the design\'s', () {
    expect(n.cardRadius, 20);
    expect(n.strongBorderWidth, 1);
    expect(n.pillShapes, isTrue);
    expect(n.roundAddButton, isTrue);
    expect(n.dotMarkers, isTrue);
    expect(n.floatingBar, isTrue);
    expect(
      n.buttonRadius(10),
      999,
      reason: 'pills ignore the screen\'s own radius',
    );
    expect(n.tagRadius(8), 999);
  });

  group('contrast (FR-012, SC-005)', () {
    test('every required pair meets its minimum', () {
      for (final p in n.requiredPairs) {
        final ratio = contrastRatio(p.fg, p.bg);
        expect(
          ratio,
          greaterThanOrEqualTo(p.min),
          reason: '${p.name}: ${ratio.toStringAsFixed(2)} < ${p.min}',
        );
      }
    });

    test('the list is not trivially short and uses only the three minimums 3.0 and 4.5', () {
      expect(n.requiredPairs.length, greaterThanOrEqualTo(15));
      expect(n.requiredPairs.map((p) => p.min).toSet(), {3.0, 4.5});
    });

    test('every colour token is in a pair or named as decorative, and nothing else is exempt', () {
      final inPairs = <Color>{};
      final names = <String>{};
      for (final p in n.requiredPairs) {
        names.addAll(p.name.split(RegExp(r'[ /]+')));
        inPairs
          ..add(p.fg)
          ..add(p.bg);
      }
      expect(n.decorative, {
        'barBorder',
        'line',
        'cardBorder',
        'cardBorderStrong',
        'cardDivider',
        'cardDisabled',
        'ring',
      });
      for (final e in n.tokens.entries) {
        final covered = inPairs.contains(e.value) && names.contains(e.key);
        expect(
          covered || n.decorative.contains(e.key),
          isTrue,
          reason: '${e.key} is in no pair and not decorative',
        );
      }
      for (final d in n.decorative) {
        expect(
          n.tokens.containsKey(d),
          isTrue,
          reason: 'decorative "$d" is not a token',
        );
      }
    });

    test(
      'the lifted values really needed lifting (the design\'s ones fail)',
      () {
        expect(
          contrastRatio(const Color(0xFF6E7983), n.background),
          lessThan(4.5),
        );
        expect(
          contrastRatio(const Color(0xFF2B343D), n.background),
          lessThan(3.0),
        );
      },
    );
  });

  test('copyWith changes only what is named', () {
    final c = n.copyWith(accent: const Color(0xFF123456), cardRadius: 8);
    expect(c.accent, const Color(0xFF123456));
    expect(c.cardRadius, 8);
    expect(c.background, n.background);
    expect(c.pillShapes, n.pillShapes);
  });

  test('lerp switches at the half: the theme change is instant', () {
    expect(n.lerp(AppLook.emerald, 0.2), n);
    expect(n.lerp(AppLook.emerald, 0.8), AppLook.emerald);
    expect(n.lerp(null, 0.9), n);
  });

  test('the two looks differ and each LookChoice has its look', () {
    expect(AppLook.emerald == AppLook.night, isFalse);
    expect(LookChoice.emerald.look, AppLook.emerald);
    expect(LookChoice.night.look, AppLook.night);
  });

  group('buildAppTheme(look: night)', () {
    final theme = buildAppTheme(look: AppLook.night);

    test('colour scheme from the Night tokens', () {
      final s = theme.colorScheme;
      expect(s.brightness, Brightness.dark);
      expect(s.primary, n.primaryFill);
      expect(s.onPrimary, n.onPrimary);
      expect(s.secondary, n.accentAlt);
      expect(s.surface, n.background);
      expect(s.onSurface, n.text);
      expect(s.surfaceContainerHighest, n.barFill);
      expect(s.outline, n.controlBorder);
      expect(s.outlineVariant, n.line);
    });

    test('scaffold, app bar, tabs, list tile, divider, inputs and buttons', () {
      expect(theme.scaffoldBackgroundColor, n.background);
      expect(theme.appBarTheme.backgroundColor, n.background);
      expect(theme.appBarTheme.foregroundColor, n.heading);
      expect(theme.appBarTheme.titleTextStyle?.color, n.heading);
      expect(theme.tabBarTheme.labelColor, n.accent);
      expect(theme.tabBarTheme.unselectedLabelColor, n.textSecondary);
      expect(theme.tabBarTheme.dividerColor, n.line);
      expect(theme.listTileTheme.textColor, n.text);
      expect(theme.listTileTheme.iconColor, n.accent);
      expect(theme.dividerTheme.color, n.line);
      expect(
        (theme.inputDecorationTheme.border as OutlineInputBorder)
            .borderSide
            .color,
        n.controlBorder,
      );
      expect(theme.inputDecorationTheme.labelStyle?.color, n.textSecondary);
      expect(
        theme.filledButtonTheme.style!.backgroundColor?.resolve({}),
        n.primaryFill,
      );
      expect(
        theme.filledButtonTheme.style!.foregroundColor?.resolve({}),
        n.onPrimary,
      );
      expect(
        theme.textButtonTheme.style!.foregroundColor?.resolve({}),
        n.accent,
      );
      expect(theme.extension<AppLook>(), n);
    });
  });
}
