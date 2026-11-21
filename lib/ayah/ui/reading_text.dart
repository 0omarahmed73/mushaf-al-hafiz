import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../settings/text_size_settings.dart';
import '../../theme.dart';

/// The system text scale times the owner's size is kept at 3x at most, so a phone that already shows large
/// text and the 150% step together stay readable (research D4).
const double kMaxReadingScale = 3.0;

/// The styles of the reading texts of the ayah menu (tafsir, translation, word meanings) at a chosen size.
/// Each font size is the size these texts had before feature 003 times [factor]; line heights, weights and
/// colours never change with the size (spec FR-005, FR-006). [quiet] is the colour of the notes and sources: the
/// card's muted colour of the look in use (feature 004), Emerald & Gold's own by default.
class ReadingStyles {
  const ReadingStyles(this.factor, {this.quiet = const Color(0xFF2C4A3F)});

  final double factor;
  final Color quiet;

  /// Arabic paragraphs (the tafsir).
  TextStyle get arabic => TextStyle(fontSize: 17 * factor, height: 1.8);

  /// The English translation.
  TextStyle get english => TextStyle(fontSize: 17 * factor, height: 1.6);

  /// A difficult word.
  TextStyle get meaningWord =>
      TextStyle(fontSize: 18 * factor, fontWeight: FontWeight.w700);

  /// The meaning of a difficult word, and the line that says there is none.
  TextStyle get meaningText => TextStyle(fontSize: 16 * factor, height: 1.7);

  /// The line above a tafsir entry that covers several ayahs.
  TextStyle get note => TextStyle(
    fontSize: 13 * factor,
    fontWeight: FontWeight.w600,
    color: quiet,
  );

  /// The source of a meaning.
  TextStyle get source => TextStyle(fontSize: 12 * factor, color: quiet);
}

/// Puts the reading texts of the ayah menu (and the preview in Settings) at the owner's size: caps the system
/// text scale (see [kMaxReadingScale]) and rebuilds when the size changes. The styles come from [of].
class ReadingScope extends StatelessWidget {
  const ReadingScope({super.key, required this.child});

  final Widget child;

  /// The styles at the current size; 100% when the app has no size setting. Listens, so call it in `build`.
  static ReadingStyles of(BuildContext context) =>
      ReadingStyles(_factor(context), quiet: context.look.cardMuted);

  static double _factor(BuildContext context) =>
      context.watch<TextSizeSettings?>()?.factor ?? 1.0;

  @override
  Widget build(BuildContext context) {
    final factor = _factor(context);
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(
          maxScaleFactor: kMaxReadingScale / factor,
        ),
      ),
      child: child,
    );
  }
}
