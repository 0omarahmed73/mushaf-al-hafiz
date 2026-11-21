/// Where a page image sits on an A4 sheet (spec FR-015): inside a 10 mm margin, as large as the margin
/// allows, with its own proportion, centred.
class A4Layout {
  const A4Layout._();

  /// A4 in PDF points (1 pt = 1/72 in).
  static const double width = 595.28;
  static const double height = 841.89;

  /// 10 mm.
  static const double margin = 28.35;

  /// The rectangle for an image of [imageW] x [imageH] pixels, in PDF page coordinates (the origin is the
  /// lower left corner, y goes up), so it can be used directly in `w 0 0 h x y cm`.
  static ({double x, double y, double w, double h}) place(
    int imageW,
    int imageH,
  ) {
    if (imageW <= 0 || imageH <= 0) {
      throw ArgumentError('the image must have a size, got ${imageW}x$imageH');
    }
    const areaW = width - 2 * margin;
    const areaH = height - 2 * margin;
    final scale = (areaW / imageW) < (areaH / imageH)
        ? areaW / imageW
        : areaH / imageH;
    final w = imageW * scale;
    final h = imageH * scale;
    return (x: (width - w) / 2, y: (height - h) / 2, w: w, h: h);
  }
}
