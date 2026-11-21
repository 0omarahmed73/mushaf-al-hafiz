import 'package:material_ui/material_ui.dart';

/// The WCAG 2.x contrast ratio of two colours, from 1.0 (the same) to 21.0 (black on white). Alpha is ignored:
/// blend a translucent colour onto what is behind it first.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// [color] when its contrast with [against] already reaches [ratio]; otherwise the same hue with its HSL
/// lightness moved away from [against] in 1% steps until it does (or until it cannot go further). Only the
/// lightness changes, so a set of colours that were different stay different.
Color liftToContrast(Color color, Color against, double ratio) {
  if (contrastRatio(color, against) >= ratio) return color;
  final hsl = HSLColor.fromColor(color);
  final lighten = against.computeLuminance() <= color.computeLuminance();
  var lightness = hsl.lightness;
  var best = color;
  for (var i = 0; i < 100; i++) {
    lightness = lighten ? lightness + 0.01 : lightness - 0.01;
    if (lightness > 1.0 || lightness < 0.0) break;
    best = hsl.withLightness(lightness).toColor();
    if (contrastRatio(best, against) >= ratio) return best;
  }
  return best;
}
