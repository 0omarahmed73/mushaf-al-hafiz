import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

/// A page ready for the PDF: 8-bit indices into a 256-colour [palette] (768 bytes, RGB), deflated (the
/// `FlateDecode` filter of PDF is zlib). A page of the Mushaf has a handful of base colours plus the
/// anti-aliasing blends between them, so 256 entries are almost lossless and the image is a fraction of the
/// size of full RGB (research D7).
class IndexedPage {
  const IndexedPage({
    required this.width,
    required this.height,
    required this.palette,
    required this.flateBytes,
  });

  final int width;
  final int height;

  /// 256 colours, three bytes each; unused entries are zero.
  final Uint8List palette;
  final Uint8List flateBytes;
}

/// Reduces opaque RGBA pixels to at most [maxColors] colours: a palette (always 768 bytes) and one index per
/// pixel. The alpha channel is ignored. If the image has no more than [maxColors] distinct colours they are
/// kept exactly; otherwise a median cut over the distinct colours, weighted by how many pixels have each, picks
/// the palette. A colour that makes up more than half of its group's pixels stays exact, so the flat areas
/// (the green sheet, the paper, the ink) never drift.
({Uint8List palette, Uint8List indices}) reduceToPalette(
  Uint8List rgba, {
  int maxColors = 256,
}) {
  if (rgba.length % 4 != 0) {
    throw ArgumentError('RGBA bytes come in fours, got ${rgba.length}');
  }
  if (maxColors < 1 || maxColors > 256) {
    throw ArgumentError.value(maxColors, 'maxColors');
  }

  // How many pixels have each colour. Most pixels repeat the one before them, so runs are counted first.
  final counts = HashMap<int, int>();
  var previous = -1;
  var run = 0;
  for (var i = 0; i < rgba.length; i += 4) {
    final key = (rgba[i] << 16) | (rgba[i + 1] << 8) | rgba[i + 2];
    if (key == previous) {
      run++;
    } else {
      if (run > 0) counts[previous] = (counts[previous] ?? 0) + run;
      previous = key;
      run = 1;
    }
  }
  if (run > 0) counts[previous] = (counts[previous] ?? 0) + run;

  final keys = counts.keys.toList()..sort();
  final palette = Uint8List(768);
  final indexOf = HashMap<int, int>();

  void setEntry(int index, int key) {
    palette[index * 3] = (key >> 16) & 255;
    palette[index * 3 + 1] = (key >> 8) & 255;
    palette[index * 3 + 2] = key & 255;
  }

  if (keys.length <= maxColors) {
    for (var i = 0; i < keys.length; i++) {
      setEntry(i, keys[i]);
      indexOf[keys[i]] = i;
    }
  } else {
    final boxes = _medianCut(keys, counts, maxColors);
    for (var b = 0; b < boxes.length; b++) {
      final box = boxes[b];
      setEntry(b, box.representative(counts));
      for (var i = box.start; i < box.end; i++) {
        indexOf[box.members[i]] = b;
      }
    }
  }

  final indices = Uint8List(rgba.length ~/ 4);
  previous = -1;
  var previousIndex = 0;
  for (var i = 0, j = 0; i < rgba.length; i += 4, j++) {
    final key = (rgba[i] << 16) | (rgba[i + 1] << 8) | rgba[i + 2];
    if (key != previous) {
      previous = key;
      previousIndex = indexOf[key]!;
    }
    indices[j] = previousIndex;
  }
  return (palette: palette, indices: indices);
}

/// A group of distinct colours: [members] from [start] to [end] (a slice of a list shared by all boxes).
class _Box {
  _Box(this.members, this.start, this.end, Map<int, int> counts) {
    var rMin = 255, rMax = 0, gMin = 255, gMax = 0, bMin = 255, bMax = 0;
    var total = 0;
    for (var i = start; i < end; i++) {
      final key = members[i];
      total += counts[key]!;
      final r = (key >> 16) & 255, g = (key >> 8) & 255, b = key & 255;
      if (r < rMin) rMin = r;
      if (r > rMax) rMax = r;
      if (g < gMin) gMin = g;
      if (g > gMax) gMax = g;
      if (b < bMin) bMin = b;
      if (b > bMax) bMax = b;
    }
    pixels = total;
    final rRange = rMax - rMin, gRange = gMax - gMin, bRange = bMax - bMin;
    widest = rRange >= gRange && rRange >= bRange
        ? 16
        : (gRange >= bRange ? 8 : 0);
    range = math.max(rRange, math.max(gRange, bRange));
  }

  final List<int> members;
  final int start;
  final int end;
  late final int pixels;

  /// The bit shift (16, 8 or 0) of the channel with the widest range, and that range.
  late final int widest;
  late final int range;

  int get size => end - start;

  /// How much a split of this box is worth: wide boxes first, heavier ones a little more.
  double get score => size < 2 ? -1 : range * math.sqrt(pixels);

  /// The colour that stands for the box: its most common colour if that is more than half of its pixels,
  /// otherwise the pixel-weighted mean.
  int representative(Map<int, int> counts) {
    var best = members[start];
    var bestCount = 0;
    var r = 0, g = 0, b = 0;
    for (var i = start; i < end; i++) {
      final key = members[i];
      final n = counts[key]!;
      if (n > bestCount) {
        bestCount = n;
        best = key;
      }
      r += ((key >> 16) & 255) * n;
      g += ((key >> 8) & 255) * n;
      b += (key & 255) * n;
    }
    if (bestCount * 2 > pixels) return best;
    int mean(int sum) => (sum / pixels).round();
    return (mean(r) << 16) | (mean(g) << 8) | mean(b);
  }
}

List<_Box> _medianCut(List<int> keys, Map<int, int> counts, int maxColors) {
  final members = List<int>.of(keys);
  final boxes = <_Box>[_Box(members, 0, members.length, counts)];
  while (boxes.length < maxColors) {
    var pick = -1;
    var bestScore = 0.0;
    for (var i = 0; i < boxes.length; i++) {
      if (boxes[i].score > bestScore) {
        bestScore = boxes[i].score;
        pick = i;
      }
    }
    if (pick < 0) break; // every box is one colour
    final box = boxes[pick];
    final shift = box.widest;
    final slice = members.sublist(box.start, box.end)
      ..sort((a, b) {
        final byChannel = ((a >> shift) & 255).compareTo((b >> shift) & 255);
        return byChannel != 0 ? byChannel : a.compareTo(b);
      });
    members.setRange(box.start, box.end, slice);
    // Split where half of the pixels are on each side, with at least one colour on each.
    var seen = 0;
    var cut = box.start + 1;
    for (var i = box.start; i < box.end - 1; i++) {
      seen += counts[members[i]]!;
      cut = i + 1;
      if (seen * 2 >= box.pixels) break;
    }
    boxes[pick] = _Box(members, box.start, cut, counts);
    boxes.add(_Box(members, cut, box.end, counts));
  }
  return boxes;
}

/// Reduces a page to a palette and indices and deflates them, in a separate isolate so the reader stays
/// smooth.
Future<IndexedPage> indexedFlatePage({
  required int width,
  required int height,
  required Uint8List rgba,
}) async {
  if (rgba.length != width * height * 4) {
    throw ArgumentError(
      '${rgba.length} bytes are not a ${width}x$height RGBA image',
    );
  }
  final (palette, flate) = await Isolate.run(() {
    final reduced = reduceToPalette(rgba);
    return (reduced.palette, Uint8List.fromList(zlib.encode(reduced.indices)));
  });
  return IndexedPage(
    width: width,
    height: height,
    palette: palette,
    flateBytes: flate,
  );
}
