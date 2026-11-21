// The quiet colours of the reading texts in both looks (feature 004, T032; spec FR-004, FR-012): the notes and the
// sources of the ayah menu take the card's muted colour of the look in use, readable on its card; Emerald & Gold
// keeps the colour it had before this feature, and the sizes never depend on the look.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ui/reading_text.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/theme.dart';

Future<ReadingStyles> stylesIn(WidgetTester t, AppLook look) async {
  late ReadingStyles styles;
  await t.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(look: look),
      home: ReadingScope(
        child: Builder(
          builder: (context) {
            styles = ReadingScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return styles;
}

void main() {
  testWidgets('Emerald keeps the colour the notes and sources always had', (
    t,
  ) async {
    final s = await stylesIn(t, AppLook.emerald);
    expect(s.note.color, const Color(0xFF2C4A3F));
    expect(s.source.color, const Color(0xFF2C4A3F));
    expect(s.note.color, AppLook.emerald.cardMuted);
  });

  testWidgets('Night takes the card\'s muted colour of the look', (t) async {
    final s = await stylesIn(t, AppLook.night);
    expect(s.note.color, AppLook.night.cardMuted);
    expect(s.source.color, AppLook.night.cardMuted);
  });

  for (final look in [AppLook.emerald, AppLook.night]) {
    testWidgets(
      'the quiet colour is readable on the card (${identical(look, AppLook.night) ? 'Night' : 'Emerald'})',
      (t) async {
        final s = await stylesIn(t, look);
        expect(
          contrastRatio(s.note.color!, look.cardFill),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(s.source.color!, look.cardFill),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }

  testWidgets('sizes, heights and weights do not depend on the look', (
    t,
  ) async {
    final a = await stylesIn(t, AppLook.emerald);
    final b = await stylesIn(t, AppLook.night);
    for (final pair in [
      (a.arabic, b.arabic),
      (a.english, b.english),
      (a.meaningWord, b.meaningWord),
      (a.meaningText, b.meaningText),
      (a.note, b.note),
      (a.source, b.source),
    ]) {
      expect(pair.$1.fontSize, pair.$2.fontSize);
      expect(pair.$1.height, pair.$2.height);
      expect(pair.$1.fontWeight, pair.$2.fontWeight);
    }
  });
}
