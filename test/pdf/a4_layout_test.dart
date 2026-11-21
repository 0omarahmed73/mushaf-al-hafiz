import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/pdf/a4_layout.dart';

void main() {
  test('the sheet is A4 in points and the margin is 10 mm', () {
    expect(A4Layout.width, closeTo(595.28, 0.01));
    expect(A4Layout.height, closeTo(841.89, 0.01));
    expect(A4Layout.margin, closeTo(10 / 25.4 * 72, 0.01));
  });

  test('a 2:3 page touches the top and bottom margins and is centred', () {
    final r = A4Layout.place(1600, 2400);
    expect(r.y, closeTo(A4Layout.margin, 0.001));
    expect(r.y + r.h, closeTo(A4Layout.height - A4Layout.margin, 0.001));
    expect(r.x, closeTo(A4Layout.width - r.x - r.w, 0.001));
    expect(r.x, greaterThan(A4Layout.margin));
  });

  test('the Mushaf proportion is kept', () {
    final r = A4Layout.place(1600, 2400);
    expect(r.w / r.h, closeTo(2 / 3, 1e-9));
  });

  test('the side margins are about 12.65 mm', () {
    final r = A4Layout.place(1600, 2400);
    expect(r.x / 72 * 25.4, closeTo(12.65, 0.1));
  });

  test('the effective resolution is at least 200 pixels per inch (FR-015)', () {
    final r = A4Layout.place(1600, 2400);
    final ppiAcross = 1600 / (r.w / 72);
    final ppiDown = 2400 / (r.h / 72);
    expect(ppiAcross, greaterThanOrEqualTo(200));
    expect(ppiDown, greaterThanOrEqualTo(200));
    expect(ppiAcross, closeTo(220, 1));
  });

  test('a wide image is limited by the width and centred vertically', () {
    final r = A4Layout.place(3000, 1000);
    expect(r.x, closeTo(A4Layout.margin, 0.001));
    expect(r.w, closeTo(A4Layout.width - 2 * A4Layout.margin, 0.001));
    expect(r.y, closeTo(A4Layout.height - r.y - r.h, 0.001));
  });

  test('an empty image is refused', () {
    expect(() => A4Layout.place(0, 100), throwsArgumentError);
    expect(() => A4Layout.place(100, -1), throwsArgumentError);
  });
}
