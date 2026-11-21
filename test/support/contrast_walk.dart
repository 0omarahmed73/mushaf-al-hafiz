import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';

/// One text or icon whose colour is too close to the colour behind it.
class ContrastIssue {
  const ContrastIssue({
    required this.kind,
    required this.text,
    required this.fg,
    required this.bg,
    required this.ratio,
    required this.minimum,
  });

  /// `text` or `icon`.
  final String kind;

  /// The words of the text, or the icon's code point.
  final String text;
  final Color fg;
  final Color bg;
  final double ratio;
  final double minimum;

  @override
  String toString() =>
      '$kind "$text" ${_hex(fg)} on ${_hex(bg)} = ${ratio.toStringAsFixed(2)} (needs $minimum)';

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Walks the pumped widget tree (or the subtree of [within]) and reports every text and icon whose colour has less
/// than [normalMin] contrast (large text: 24 px, or 18.66 px and bold, and icons: [largeMin]) against the colour
/// painted behind it: the nearest opaque background above it (a [ColoredBox], a [DecoratedBox] colour, a [Material],
/// a [Scaffold]), with translucent ones blended on what is behind them. Content under a reduced [Opacity] is exempt
/// (disabled items, spec FR-012). Nothing is drawn or pumped here.
List<ContrastIssue> contrastIssues(
  WidgetTester t, {
  Finder? within,
  double normalMin = 4.5,
  double largeMin = 3.0,
}) {
  final issues = <ContrastIssue>[];
  Finder inside(Finder what) =>
      within == null ? what : find.descendant(of: within, matching: what);

  for (final element in inside(find.byType(RichText)).evaluate()) {
    final rich = element.widget as RichText;
    final span = rich.text;
    final style = span.style;
    final plain = span.toPlainText();
    if (plain.trim().isEmpty || style?.color == null) continue;
    if (_exempt(element) || _insideIcon(element)) continue;
    final size = style!.fontSize ?? 14;
    final bold = (style.fontWeight?.value ?? 400) >= 700;
    final large = size >= 24 || (bold && size >= 18.66);
    _check(
      issues,
      element,
      kind: 'text',
      label: plain,
      fg: style.color!,
      minimum: large ? largeMin : normalMin,
    );
  }

  for (final element in inside(find.byType(Icon)).evaluate()) {
    final icon = element.widget as Icon;
    if (_exempt(element)) continue;
    final color = icon.color ?? IconTheme.of(element).color;
    if (color == null) continue;
    _check(
      issues,
      element,
      kind: 'icon',
      label: icon.icon == null ? '?' : '${icon.icon!.codePoint}',
      fg: color,
      minimum: largeMin,
    );
  }
  return issues;
}

void _check(
  List<ContrastIssue> issues,
  Element element, {
  required String kind,
  required String label,
  required Color fg,
  required double minimum,
}) {
  final bg = _backgroundBehind(element);
  final solid = fg.a < 1 ? Color.alphaBlend(fg, bg) : fg;
  final ratio = contrastRatio(solid, bg);
  if (ratio < minimum) {
    issues.add(
      ContrastIssue(
        kind: kind,
        text: label,
        fg: solid,
        bg: bg,
        ratio: ratio,
        minimum: minimum,
      ),
    );
  }
}

bool _exempt(Element element) {
  var exempt = false;
  element.visitAncestorElements((a) {
    final w = a.widget;
    if ((w is Opacity && w.opacity < 1) ||
        (w is AnimatedOpacity && w.opacity < 1)) {
      exempt = true;
      return false;
    }
    return true;
  });
  return exempt;
}

bool _insideIcon(Element element) {
  var inside = false;
  element.visitAncestorElements((a) {
    if (a.widget is Icon) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

Color _backgroundBehind(Element element) {
  final layers = <Color>[];
  Color? base;
  element.visitAncestorElements((a) {
    final w = a.widget;
    Color? c;
    if (w is ColoredBox) {
      c = w.color;
    } else if (w is DecoratedBox) {
      final d = w.decoration;
      if (d is BoxDecoration) c = d.color;
    } else if (w is Material) {
      if (w.type != MaterialType.transparency) {
        c = w.color ?? Theme.of(a).canvasColor;
      }
    } else if (w is Scaffold) {
      c = w.backgroundColor ?? Theme.of(a).scaffoldBackgroundColor;
    }
    if (c != null && c.a > 0) {
      if (c.a >= 1) {
        base = c;
        return false;
      }
      layers.add(c);
    }
    return true;
  });
  var result = base ?? const Color(0xFF000000);
  for (final layer in layers.reversed) {
    result = Color.alphaBlend(layer, result);
  }
  return result;
}
