import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../mushaf/mushaf_page.dart' show kLineBoxEm, kMaxLineEm;
import '../mushaf/mushaf_repository.dart';
import 'screen_layout.dart';
import 'screen_navigator.dart';
import 'word_measurer.dart';

/// The sizes of a large-ayah screen in a box (feature 015, research D2). Pure numbers, shared by the layout and the
/// screen widget so they always agree.
@immutable
class LargeGeometry {
  factory LargeGeometry({required double width, required double height, required double factor}) {
    final shortest = math.min(width, height);
    final textHeight = math.max(0.0, height - 2 * vPad - headerHeight - footerHeight);
    // The chosen size, unless a short box (a phone on its side at the largest step) would hold fewer than 3 lines: then
    // the size that holds 3, so a title, a basmala and a line of words always fit.
    final fontSize = math.max(
      1.0,
      math.min(factor * math.max(1, shortest - 2 * hPad) / kMaxLineEm, textHeight / (minLines * kLineBoxEm)),
    );
    final lineHeight = fontSize * kLineBoxEm;
    return LargeGeometry._(
      width: width,
      height: height,
      fontSize: fontSize,
      lineHeight: lineHeight,
      lineWidth: math.max(1, width - 2 * hPad),
      linesPerScreen: math.max(minLines, (textHeight / lineHeight + 1e-9).floor()),
    );
  }

  const LargeGeometry._({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.lineHeight,
    required this.lineWidth,
    required this.linesPerScreen,
  });

  static const int minLines = 3;
  static const double hPad = 16;
  static const double vPad = 8;

  /// 48 px, the height of the reader's «المصحف» button that sits at its end.
  static const double headerHeight = 48;

  /// The width kept at the header's end for that button.
  static const double headerEndReserve = 112;
  static const double footerHeight = 32;

  /// The gap between two words, in em.
  static const double gapEm = 0.25;

  final double width;
  final double height;
  final double fontSize;
  final double lineHeight;
  final double lineWidth;
  final int linesPerScreen;

  double get wordGap => fontSize * gapEm;

  @override
  bool operator ==(Object other) =>
      other is LargeGeometry && other.width == width && other.height == height && other.fontSize == fontSize;

  @override
  int get hashCode => Object.hash(width, height, fontSize);
}

/// The screens of each page for one geometry and count: the page from the repository, its glyph widths from the
/// measurer, the screens from [layoutPage].
class PageScreens implements ScreenSource {
  PageScreens({required this.mushaf, required this.measurer, required this.geometry, required this.count});

  final MushafRepository mushaf;
  final WordMeasurer measurer;
  final LargeGeometry geometry;
  final int count;

  @override
  Future<List<LargeScreen>> screensOf(int page) async {
    final data = await mushaf.loadPage(page);
    final ayat = pageAyat(data);
    final widths = await measurer.widths(page, [for (final a in ayat) ...a.words], geometry.fontSize);
    var at = 0;
    final measured = <LayoutAyah>[];
    for (final a in ayat) {
      measured.add(a.withWidths(widths.sublist(at, at + a.words.length)));
      at += a.words.length;
    }
    return layoutPage(
      page: page,
      ayat: measured,
      lineWidth: geometry.lineWidth,
      wordGap: geometry.wordGap,
      linesPerScreen: geometry.linesPerScreen,
      count: count,
    );
  }
}
