// The tint of a bookmarked ayah, measured on the page paper of each look (feature 013, spec FR-023, SC-015; research D6):
// recomputed from the PageLook tokens, so a later change of a colour that breaks a rule fails. A translucent colour is
// blended on the paper and rounded to 8 bits a channel, as the screen shows it; contrast is WCAG 2.x, hue is HSL.
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/mushaf/page_look.dart';

int _ch(Color c, int shift) => (c.toARGB32() >> shift) & 0xFF;

/// [fg] (translucent) over the opaque [bg], each channel rounded to 8 bits.
Color blend(Color fg, Color bg) {
  final a = _ch(fg, 24) / 255;
  int mix(int shift) => (a * _ch(fg, shift) + (1 - a) * _ch(bg, shift)).round();
  return Color.fromARGB(255, mix(16), mix(8), mix(0));
}

List<int> rgb(Color c) => [_ch(c, 16), _ch(c, 8), _ch(c, 0)];

double hue(Color c) => HSLColor.fromColor(c).hue;

double hueGap(Color a, Color b) {
  final d = (hue(a) - hue(b)).abs();
  return math.min(d, 360 - d);
}

/// How far a wash moves the paper: the straight-line distance of the two colours in 8-bit sRGB.
double distance(Color a, Color b) {
  final x = rgb(a), y = rgb(b);
  var s = 0.0;
  for (var i = 0; i < 3; i++) {
    s += math.pow(x[i] - y[i], 2);
  }
  return math.sqrt(s);
}

void main() {
  final cases =
      <
        ({
          String name,
          PageLook look,
          List<int> tintRgb,
          List<int> highlightRgb,
          double ink,
          double? marker,
          double onPaper,
          double gap,
        })
      >[
        (
          name: 'Emerald & Gold',
          look: PageLook.emerald,
          tintRgb: [213, 225, 208],
          highlightRgb: [252, 228, 154],
          ink: 12.04,
          marker: null,
          onPaper: 1.24,
          gap: 57,
        ),
        (
          name: 'Night Reader',
          look: PageLook.night,
          tintRgb: [43, 42, 34],
          highlightRgb: [42, 70, 69],
          ink: 11.69,
          marker: 7.0,
          onPaper: 1.32,
          gap: 125,
        ),
      ];

  test('the tokens of research D6', () {
    expect(PageLook.emerald.bookmarkTint, const Color(0x290F766E));
    expect(PageLook.night.bookmarkTint, const Color(0x24E4C877));
    const plain = PageLook(
      paper: Color(0xFFFFFFFF),
      ink: Color(0xFF000000),
      frame: Color(0xFF000000),
      frameWidth: 1,
      bannerText: Color(0xFF000000),
      background: Color(0xFFFFFFFF),
    );
    expect(
      plain.bookmarkTint,
      const Color(0x290F766E),
      reason: 'the default of a look that does not set it',
    );
  });

  for (final c in cases) {
    test(
      '${c.name}: the tint is light, visible, readable and told apart from the highlight',
      () {
        final paper = c.look.paper;
        final tint = blend(c.look.bookmarkTint, paper);
        final highlight = blend(c.look.highlight, paper);
        final ink = contrastRatio(c.look.ink, tint);
        final onPaper = contrastRatio(tint, paper);
        final gap = hueGap(tint, highlight);
        final marker = c.look.endMarker == null
            ? null
            : contrastRatio(c.look.endMarker!, tint);
        final tintWash = distance(tint, paper);
        final highlightWash = distance(highlight, paper);
        print(
          'TINT ${c.name}: tint on paper ${rgb(tint)}, highlight on paper ${rgb(highlight)}, '
          'ink on tint ${ink.toStringAsFixed(2)}:1, '
          'end marker on tint ${marker?.toStringAsFixed(2) ?? '(ink)'}${marker == null ? '' : ':1'}, '
          'tint vs paper ${onPaper.toStringAsFixed(2)}:1 (highlight vs paper '
          '${contrastRatio(highlight, paper).toStringAsFixed(2)}:1), '
          'hue highlight ${hue(highlight).toStringAsFixed(1)} / tint ${hue(tint).toStringAsFixed(1)} '
          '(${gap.toStringAsFixed(1)} apart), wash highlight ${highlightWash.toStringAsFixed(1)} / '
          'tint ${tintWash.toStringAsFixed(1)}',
        );

        // The blended colours of the research table.
        expect(rgb(tint), c.tintRgb);
        expect(rgb(highlight), c.highlightRgb);

        // The rules.
        expect(
          ink,
          greaterThanOrEqualTo(4.5),
          reason: 'the page text on the tint',
        );
        if (marker != null) {
          expect(
            marker,
            greaterThanOrEqualTo(4.5),
            reason: 'the end marker on the tint',
          );
        }
        expect(
          onPaper,
          greaterThanOrEqualTo(1.15),
          reason: 'visible against the bare paper',
        );
        expect(
          onPaper,
          lessThanOrEqualTo(1.50),
          reason: 'light, never a block of colour',
        );
        expect(
          gap,
          greaterThanOrEqualTo(40),
          reason: 'hue apart from the highlight',
        );
        expect(
          highlightWash,
          greaterThan(tintWash),
          reason: 'the highlight is the stronger wash',
        );

        // The measured numbers of research D6.
        expect(ink, closeTo(c.ink, 0.01));
        if (marker != null) expect(marker, closeTo(c.marker!, 0.01));
        expect(onPaper, closeTo(c.onPaper, 0.01));
        expect(gap, closeTo(c.gap, 1));
      },
    );
  }
}
