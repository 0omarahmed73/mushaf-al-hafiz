// The sun arc of the day view (design A «قوس الشمس», research D13): a dashed arc from sunrise to maghrib, the part the
// sun has crossed drawn solid, a dot for each prayer and a ring on the next one. Decoration only: every time is also
// written in the rows under it, so the arc is left out of the semantics tree.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'prayer_calc.dart';

/// Where the sun is between sunrise (0) and maghrib (1) at [now]; null before sunrise or after maghrib.
double? sunFraction(DayTimes day, DateTime now) {
  final rise = day.utc[Prayer.sunrise]!, set = day.utc[Prayer.maghrib]!;
  if (now.isBefore(rise) || now.isAfter(set)) return null;
  return now.difference(rise).inMilliseconds /
      set.difference(rise).inMilliseconds;
}

/// Each prayer's place on the arc, by the same measure: Fajr below 0, Isha above 1.
Map<Prayer, double> arcMarks(DayTimes day) {
  final rise = day.utc[Prayer.sunrise]!, set = day.utc[Prayer.maghrib]!;
  final span = set.difference(rise).inMilliseconds;
  return {
    for (final p in Prayer.values)
      p: day.utc[p]!.difference(rise).inMilliseconds / span,
  };
}

class SunArcPainter extends CustomPainter {
  const SunArcPainter({
    required this.marks,
    required this.sun,
    required this.next,
    required this.nextLabel,
    required this.direction,
    required this.line,
    required this.dot,
    required this.accent,
  });

  final Map<Prayer, double> marks;
  final double? sun;
  final Prayer next;
  final String nextLabel;

  /// Right to left puts the morning on the right.
  final TextDirection direction;
  final Color line;
  final Color dot;
  final Color accent;

  static const double _labelRoom = 18;

  /// The next prayer's name on the arc. A painter does not see the theme, so it names Cairo itself.
  TextStyle get labelStyle => TextStyle(
    fontFamily: kUiFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: accent,
  );

  double _horizon(Size s) => s.height - _labelRoom;

  /// The point at [t] on the arc (0 sunrise, 1 maghrib); outside 0..1 it sits on the horizon past the arc's ends.
  Offset point(double t, Size s) {
    final m = s.width * 0.12, y0 = _horizon(s);
    // The control point puts the top of the arc 12 px under the box's top.
    final c = 24 - y0;
    double x, y;
    if (t < 0) {
      x = m * 0.4;
      y = y0;
    } else if (t > 1) {
      x = s.width - m * 0.4;
      y = y0;
    } else {
      final u = 1 - t;
      x = u * u * m + 2 * u * t * (s.width / 2) + t * t * (s.width - m);
      y = u * u * y0 + 2 * u * t * c + t * t * y0;
    }
    return Offset(direction == TextDirection.rtl ? s.width - x : x, y);
  }

  Path _arc(Size s, double from, double to) {
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final p = point(from + (to - from) * i / steps, s);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final y0 = _horizon(size);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, y0),
      Offset(size.width, y0),
      stroke
        ..color = line
        ..strokeWidth = 1.5,
    );

    // The dashed arc: short pieces of the same curve.
    stroke
      ..color = line
      ..strokeWidth = 2;
    const dashes = 30;
    for (var i = 0; i < dashes; i++) {
      canvas.drawPath(_arc(size, i / dashes, (i + 0.45) / dashes), stroke);
    }
    final sun = this.sun;
    if (sun != null && sun > 0) {
      canvas.drawPath(
        _arc(size, 0, sun),
        stroke
          ..color = accent
          ..strokeWidth = 2.5,
      );
    }

    final fill = Paint()..style = PaintingStyle.fill;
    for (final e in marks.entries) {
      final p = point(e.value, size);
      if (e.key == next) {
        canvas.drawCircle(
          p,
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = accent,
        );
      } else {
        canvas.drawCircle(p, 4, fill..color = dot);
      }
    }
    if (sun != null) {
      final p = point(sun, size);
      canvas.drawCircle(p, 15, fill..color = accent.withValues(alpha: 0.18));
      canvas.drawCircle(p, 8, fill..color = accent);
    }

    final label = TextPainter(
      text: TextSpan(text: nextLabel, style: labelStyle),
      textDirection: TextDirection.rtl,
    )..layout();
    final at = point(marks[next]!, size);
    final below = at.dy + 10 + label.height <= size.height;
    final x = (at.dx - label.width / 2)
        .clamp(0.0, math.max(0.0, size.width - label.width))
        .toDouble();
    label.paint(
      canvas,
      Offset(x, below ? at.dy + 10 : at.dy - 10 - label.height),
    );
  }

  @override
  bool shouldRepaint(SunArcPainter old) =>
      old.sun != sun ||
      old.next != next ||
      old.nextLabel != nextLabel ||
      old.direction != direction ||
      old.line != line ||
      old.dot != dot ||
      old.accent != accent ||
      !_sameMarks(old.marks, marks);

  static bool _sameMarks(Map<Prayer, double> a, Map<Prayer, double> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
