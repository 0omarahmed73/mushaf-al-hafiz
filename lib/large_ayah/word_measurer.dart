import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../mushaf/models.dart';
import '../mushaf/page_font_loader.dart';

/// The width of each word's glyph in its page font at a font size (feature 015, research D4). Waits for the page font;
/// keeps the last [cacheSize] results.
class WordMeasurer {
  WordMeasurer(this._fonts);

  final PageFontLoader _fonts;
  static const int cacheSize = 8;
  final LinkedHashMap<(int, double), List<double>> _cache = LinkedHashMap();

  /// How many (page, size) pairs were measured, for tests.
  int measured = 0;

  Future<List<double>> widths(int page, List<MushafWord> words, double fontSize) async {
    final key = (page, fontSize);
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    final family = await _fonts.ensure(page);
    final style = TextStyle(fontFamily: family, fontSize: fontSize, height: 1);
    final painter = TextPainter(textDirection: TextDirection.rtl);
    final out = <double>[];
    for (final w in words) {
      painter
        ..text = TextSpan(text: w.glyph, style: style)
        ..layout();
      out.add(painter.width);
    }
    painter.dispose();
    measured++;
    _cache[key] = out;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return out;
  }
}
