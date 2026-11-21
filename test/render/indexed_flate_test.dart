// The PDF pages are 256-colour images: a palette chosen for the page and 8-bit indices, deflated.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/render/indexed_flate.dart';

Uint8List rgbaOf(List<int> rgb) {
  final out = Uint8List(rgb.length ~/ 3 * 4);
  for (var i = 0, j = 0; i < rgb.length; i += 3, j += 4) {
    out[j] = rgb[i];
    out[j + 1] = rgb[i + 1];
    out[j + 2] = rgb[i + 2];
    out[j + 3] = 255;
  }
  return out;
}

/// The colour an index stands for.
List<int> colourOf(Uint8List palette, int index) => [
  palette[index * 3],
  palette[index * 3 + 1],
  palette[index * 3 + 2],
];

void main() {
  test('a page with few colours keeps every colour exactly', () {
    final reduced = reduceToPalette(
      rgbaOf([
        14,
        59,
        48,
        251,
        245,
        227,
        14,
        59,
        48,
        20,
        35,
        29,
        251,
        245,
        227,
      ]),
    );
    expect(reduced.palette, hasLength(768));
    final colours = [
      for (final i in reduced.indices) colourOf(reduced.palette, i),
    ];
    expect(colours, [
      [14, 59, 48],
      [251, 245, 227],
      [14, 59, 48],
      [20, 35, 29],
      [251, 245, 227],
    ]);
  });

  test('equal colours share one index, different colours do not', () {
    final reduced = reduceToPalette(rgbaOf([1, 2, 3, 1, 2, 3, 9, 9, 9]));
    expect(reduced.indices[0], reduced.indices[1]);
    expect(reduced.indices[0], isNot(reduced.indices[2]));
  });

  test('thousands of blended colours fit 256 entries with a small error', () {
    // Ink-to-paper blends, as the anti-aliased edge of a letter, plus a big flat paper area and an ink core.
    const ink = [20, 35, 29], paper = [251, 245, 227];
    final pixels = <int>[];
    for (var i = 0; i < 20000; i++) {
      pixels.addAll(paper);
    }
    for (var i = 0; i < 3000; i++) {
      pixels.addAll(ink);
    }
    for (var step = 0; step <= 1000; step++) {
      final t = step / 1000;
      for (var c = 0; c < 3; c++) {
        pixels.add(
          (ink[c] + (paper[c] - ink[c]) * t + (step % 7) - 3).round().clamp(
            0,
            255,
          ),
        );
      }
    }
    final reduced = reduceToPalette(rgbaOf(pixels));
    var worst = 0;
    for (var p = 0; p < pixels.length ~/ 3; p++) {
      final got = colourOf(reduced.palette, reduced.indices[p]);
      for (var c = 0; c < 3; c++) {
        final e = (got[c] - pixels[p * 3 + c]).abs();
        if (e > worst) worst = e;
      }
    }
    expect(
      worst,
      lessThanOrEqualTo(8),
      reason: 'no pixel is off by more than 8 of 255',
    );
    // The dominant colours are exact: the sheet and the paper must not drift.
    expect(colourOf(reduced.palette, reduced.indices[0]), paper);
    expect(colourOf(reduced.palette, reduced.indices[20000]), ink);
  });

  test('alpha is ignored and the output size is one index per pixel', () {
    final rgba = Uint8List.fromList([10, 20, 30, 7, 10, 20, 30, 255]);
    final reduced = reduceToPalette(rgba);
    expect(reduced.indices, hasLength(2));
    expect(reduced.indices[0], reduced.indices[1]);
  });

  test(
    'the result does not depend on how often the image repeats a colour first',
    () {
      final a = reduceToPalette(rgbaOf([5, 5, 5, 200, 100, 50, 5, 5, 5]));
      final b = reduceToPalette(rgbaOf([5, 5, 5, 200, 100, 50, 5, 5, 5]));
      expect(a.palette, b.palette);
      expect(a.indices, b.indices);
    },
  );

  test('bytes that are not whole pixels are refused', () {
    expect(() => reduceToPalette(Uint8List(7)), throwsArgumentError);
  });

  test('indexedFlatePage inflates back to width x height indices', () async {
    final rgba = rgbaOf([
      255,
      255,
      255,
      0,
      0,
      0,
      10,
      0,
      0,
      200,
      0,
      0,
      255,
      255,
      255,
      1,
      0,
      0,
    ]);
    final page = await indexedFlatePage(width: 3, height: 2, rgba: rgba);
    expect((page.width, page.height), (3, 2));
    expect(page.palette, hasLength(768));
    final indices = zlib.decode(page.flateBytes);
    expect(indices, hasLength(6));
    expect(colourOf(page.palette, indices[0]), [255, 255, 255]);
    expect(colourOf(page.palette, indices[1]), [0, 0, 0]);
    expect(colourOf(page.palette, indices[3]), [200, 0, 0]);
    expect(indices[0], indices[4]);
  });

  test('a flat page deflates to far fewer bytes than it holds', () async {
    final rgba = Uint8List(400 * 600 * 4)..fillRange(0, 400 * 600 * 4, 255);
    final page = await indexedFlatePage(width: 400, height: 600, rgba: rgba);
    expect(page.flateBytes.length, lessThan(2000));
    expect(zlib.decode(page.flateBytes), hasLength(400 * 600));
  });

  test('a size that does not match the pixels is refused', () async {
    await expectLater(
      indexedFlatePage(width: 5, height: 5, rgba: Uint8List(8)),
      throwsArgumentError,
    );
  });
}
