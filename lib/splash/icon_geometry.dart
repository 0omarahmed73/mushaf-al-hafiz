import 'dart:math' as math;
import 'dart:ui';

/// Where the art sits on the 108-unit canvas: [scale] about [pivot], then moved by [shift] (data-model.md `Icon geometry`).
class IconPlacement {
  const IconPlacement(this.scale, this.pivot, this.shift);

  final double scale;
  final Offset pivot;
  final Offset shift;

  /// Where a point of the drawing ends up on the canvas. The same rule as an Android vector `<group>` with these pivot, scale
  /// and translate values, and as the design's `translate(54 56) scale(.9) translate(-54 -54)`.
  Offset apply(Offset p) => pivot + (p - pivot) * scale + shift;
}

/// The drawing of icon 2 «المصحف المفتوح» (`Icon2.dc.html`) as data on a 108 x 108 canvas, shared by the splash tile, the
/// launcher PNGs and the Android vector layers so the three can never disagree (spec FR-004, research D5). Colours are in
/// `SplashColors`.
abstract final class AppIconGeometry {
  static const double canvas = 108;

  /// The star: a square and the same square turned 45 degrees about [starCentre], with a dark dot in the middle.
  static const String starSquare = 'M48 19 L60 19 L60 31 L48 31 Z';
  static const String starDiamond =
      'M54 16.5147 L62.4853 25 L54 33.4853 L45.5147 25 Z';
  static const Offset starCentre = Offset(54, 25);
  static const double starHoleRadius = 2;

  /// The hole as a path (four cubic curves), for the even-odd silhouette of the monochrome layer and for the vector layers.
  static const String starHole =
      'M56 25 C56 26.1046 55.1046 27 54 27 C52.8954 27 52 26.1046 52 25 '
      'C52 23.8954 52.8954 23 54 23 C55.1046 23 56 23.8954 56 25 Z';

  /// The two pages, the spine between them, and three lines of text on each page.
  static const String pageLeft =
      'M54 74 C46 68 34 66 24 68 L24 40 C34 38 46 40 54 46 Z';
  static const String pageRight =
      'M54 74 C62 68 74 66 84 68 L84 40 C74 38 62 40 54 46 Z';
  static const String spine = 'M54 46 L54 74';
  static const String pagesLinesLeft =
      'M30 48 C36 47 42 48 48 51 M30 54 C36 53 42 54 48 57 M30 60 C36 59 42 60 48 63';
  static const String pagesLinesRight =
      'M78 48 C72 47 66 48 60 51 M78 54 C72 53 66 54 60 57 M78 60 C72 59 66 60 60 63';

  /// The gold line that curves under the book.
  static const String goldLine = 'M22 73 C34 71 46 73 54 79 C62 73 74 71 86 73';

  static const double spineWidth = 0.8;
  static const double pageLinesWidth = 1;
  static const double goldWidth = 2.2;

  /// The monochrome layer (one colour, Android 13 themed icons): the star as a single eight-point outline (outer radius
  /// 6 * sqrt(2), inner 6 / cos 22.5 degrees) filled even-odd with [starHole]; the pages pulled 0.6 away from the spine so a
  /// thin gap shows it; the gold line a little heavier so it survives the small size.
  static const String monochromeStar =
      'M62.4853 25 L60 27.4853 L60 31 L56.4853 31 L54 33.4853 L51.5147 31 L48 31 L48 27.4853 '
      'L45.5147 25 L48 22.5147 L48 19 L51.5147 19 L54 16.5147 L56.4853 19 L60 19 L60 22.5147 Z';
  static const String monochromePageLeft =
      'M53.4 74 C46 68 34 66 24 68 L24 40 C34 38 46 40 53.4 46 Z';
  static const String monochromePageRight =
      'M54.6 74 C62 68 74 66 84 68 L84 40 C74 38 62 40 54.6 46 Z';
  static const double monochromeGoldWidth = 2.6;

  /// The design's own placement (scale 0.9, the art one unit lower than centre), used for the splash tile and the PNGs.
  static const IconPlacement legacy = IconPlacement(
    0.9,
    Offset(54, 54),
    Offset(0, 2),
  );

  /// The adaptive icon's foreground and monochrome layer: scale 0.85 about the centre of the smallest circle that holds the
  /// art, moved to the canvas centre, so the farthest point is 32.33 from (54, 54), inside the 33 of the 66 dp safe zone.
  static const IconPlacement adaptive = IconPlacement(
    0.85,
    Offset(54, 54.55),
    Offset(0, -0.55),
  );

  /// The farthest any painted point of the star, the pages and the gold line (stroke included) is from the canvas centre
  /// (54, 54) when the art is placed by [placement].
  static double farthestFromCentre(IconPlacement placement) {
    const centre = Offset(canvas / 2, canvas / 2);
    var farthest = 0.0;
    void scan(String d, double halfStroke) {
      for (final metric in parsePath(d).computeMetrics()) {
        final length = metric.length;
        for (var at = 0.0; at <= length + 0.25; at += 0.25) {
          final p = metric.getTangentForOffset(math.min(at, length))!.position;
          final r =
              (placement.apply(p) - centre).distance +
              halfStroke * placement.scale;
          if (r > farthest) farthest = r;
        }
      }
    }

    for (final d in [starSquare, starDiamond, pageLeft, pageRight]) {
      scan(d, 0);
    }
    scan(goldLine, goldWidth / 2);
    return farthest;
  }

  /// Turns one of the strings above into a [Path]. It understands the absolute commands `M`, `L`, `C` and `Z` with numbers
  /// separated by spaces or commas; anything else (arcs, relative commands, a missing number, a stray character) throws a
  /// [FormatException].
  static Path parsePath(String d) {
    final number = RegExp(r'-?(?:\d+\.?\d*|\.\d+)');
    final commands = <(String, List<double>)>[];
    var i = 0;
    while (i < d.length) {
      final c = d[i];
      if (c == ' ' || c == ',' || c == '\n' || c == '\t') {
        i++;
      } else if ('MLCZ'.contains(c)) {
        commands.add((c, <double>[]));
        i++;
      } else {
        final m = number.matchAsPrefix(d, i);
        if (m == null || commands.isEmpty) {
          throw FormatException('Unexpected "$c" in the path', d, i);
        }
        commands.last.$2.add(double.parse(m[0]!));
        i = m.end;
      }
    }
    final path = Path();
    for (final (cmd, n) in commands) {
      final size = switch (cmd) {
        'M' || 'L' => 2,
        'C' => 6,
        _ => 0,
      };
      if (size == 0) {
        if (n.isNotEmpty) throw FormatException('Z takes no numbers', d);
        path.close();
        continue;
      }
      if (n.isEmpty || n.length % size != 0) {
        throw FormatException('"$cmd" needs groups of $size numbers', d);
      }
      for (var k = 0; k < n.length; k += size) {
        switch (cmd) {
          case 'M':
            // Further pairs after the first are implicit line-tos, as in SVG.
            k == 0 ? path.moveTo(n[0], n[1]) : path.lineTo(n[k], n[k + 1]);
          case 'L':
            path.lineTo(n[k], n[k + 1]);
          default:
            path.cubicTo(
              n[k],
              n[k + 1],
              n[k + 2],
              n[k + 3],
              n[k + 4],
              n[k + 5],
            );
        }
      }
    }
    return path;
  }
}
