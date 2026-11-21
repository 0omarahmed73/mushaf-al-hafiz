// WCAG contrast maths used to hold the Night look to its readability bars (spec FR-012, FR-013).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';

void main() {
  group('contrastRatio', () {
    test('black on white is 21 and a colour on itself is 1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.001),
      );
      expect(
        contrastRatio(const Color(0xFF123456), const Color(0xFF123456)),
        1.0,
      );
    });

    test('it does not depend on the order', () {
      const a = Color(0xFFECE7DC);
      const b = Color(0xFF0D1014);
      expect(contrastRatio(a, b), contrastRatio(b, a));
    });

    test('the Night pairs of the research (D7) to two decimals', () {
      const bg = Color(0xFF0D1014);
      const card = Color(0xFF161B22);
      double r(int fg, Color on) =>
          double.parse(contrastRatio(Color(fg), on).toStringAsFixed(2));
      expect(r(0xFFECE7DC, bg), 15.46);
      expect(r(0xFFECE7DC, card), 14.03);
      expect(r(0xFF9AA4AD, card), 6.83);
      expect(r(0xFF6CC4B5, bg), 9.26);
      expect(r(0xFF6CC4B5, card), 8.40);
      expect(r(0xFF6E7983, bg), 4.29);
      expect(r(0xFF6E7983, card), 3.89);
      expect(r(0xFF85909B, bg), 5.87);
      expect(r(0xFF5F6B76, bg), 3.50);
      expect(r(0xFF2B343D, bg), 1.51);
    });

    test('alpha is ignored: the caller blends first', () {
      expect(
        contrastRatio(const Color(0x00FFFFFF), const Color(0xFF000000)),
        closeTo(21.0, 0.001),
      );
    });
  });

  group('liftToContrast', () {
    const card = Color(0xFF161B22);

    test('a colour that already passes is returned unchanged', () {
      const green = Color(0xFF2E7D32); // 3.37 on the card
      expect(liftToContrast(green, card, 3.0), green);
    });

    test(
      'a colour that fails is lightened until it passes, and the hue is kept',
      () {
        const purple = Color(0xFF6A1B9A); // 1.84 on the card
        final lifted = liftToContrast(purple, card, 3.0);
        expect(contrastRatio(lifted, card), greaterThanOrEqualTo(3.0));
        expect(
          contrastRatio(lifted, card),
          lessThan(3.2),
          reason: 'the smallest lift that passes',
        );
        expect(
          HSLColor.fromColor(lifted).hue,
          closeTo(HSLColor.fromColor(purple).hue, 1.5),
        );
        expect(
          HSLColor.fromColor(lifted).lightness,
          greaterThan(HSLColor.fromColor(purple).lightness),
        );
      },
    );

    test('brown and slate of the wird palette reach 3:1', () {
      for (final c in const [Color(0xFF4E342E), Color(0xFF37474F)]) {
        expect(
          contrastRatio(liftToContrast(c, card, 3.0), card),
          greaterThanOrEqualTo(3.0),
        );
      }
    });

    test('it never goes past white', () {
      final lifted = liftToContrast(
        const Color(0xFF808080),
        const Color(0xFFFFFFFF),
        21.0,
      );
      expect(lifted.toARGB32() & 0xFFFFFF, lessThanOrEqualTo(0xFFFFFF));
      final hsl = HSLColor.fromColor(lifted);
      expect(hsl.lightness, lessThanOrEqualTo(1.0));
    });

    test('the alpha channel is kept', () {
      final lifted = liftToContrast(const Color(0xFF4E342E), card, 3.0);
      expect(lifted.a, 1.0);
    });
  });
}
