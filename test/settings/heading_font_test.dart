// The heading font (owner, 2026-11-26): every heading outside the Mushaf is Cairo bold, the interface font; the surah
// title in the Mushaf page keeps Reem Kufi so the page looks as before (Principle II).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';
import 'package:mushaf/settings/about_screen.dart';
import 'package:mushaf/theme.dart';

void main() {
  test('headings are Cairo bold; the surah title keeps Reem Kufi', () {
    expect(kHeadingFont, kUiFont);
    final h = headingStyle(20, const Color(0xFF000000));
    expect(h.fontFamily, 'Cairo');
    expect(h.fontWeight, FontWeight.w700);
    expect(kTitleFont, 'ReemKufi');
  });

  for (final look in [AppLook.emerald, AppLook.night]) {
    test(
      'the app bar title is Cairo bold (${look == AppLook.night ? 'Night' : 'Emerald'})',
      () {
        final style = buildAppTheme(look: look).appBarTheme.titleTextStyle!;
        expect(style.fontFamily, 'Cairo');
        expect(style.fontWeight, FontWeight.w700);
      },
    );
  }

  test('About names Reem Kufi for the surah titles only', () {
    final reem = AboutScreen.credits.firstWhere((c) => c.$1 == 'Reem Kufi');
    expect(reem.$2, 'خط عناوين السور');
    final cairo = AboutScreen.credits.firstWhere((c) => c.$1 == 'Cairo');
    expect(cairo.$2, 'خط الواجهة والعناوين');
  });
}
