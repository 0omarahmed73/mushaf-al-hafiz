import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/settings/text_size.dart';

void main() {
  test('the steps are 80 to 150 in tens and the default is 100', () {
    expect(TextSize.steps, [80, 90, 100, 110, 120, 130, 140, 150]);
    expect(TextSize.defaultPercent, 100);
    expect(TextSize.steps, contains(TextSize.defaultPercent));
  });

  test('factor is the percent over 100', () {
    expect(TextSize.factor(100), 1.0);
    expect(TextSize.factor(150), 1.5);
    expect(TextSize.factor(80), 0.8);
  });

  test('every step parses to itself', () {
    for (final step in TextSize.steps) {
      expect(TextSize.parse('$step'), step);
    }
  });

  test('missing, empty or not a number is the default', () {
    for (final raw in [null, '', ' ', 'abc', '12x', '1.5', '١٢٠', 'NaN']) {
      expect(TextSize.parse(raw), 100, reason: '$raw');
    }
  });

  test('outside 80..150 is the default, not a clamp', () {
    for (final raw in ['79', '151', '0', '-5', '999', '-100', '1000000']) {
      expect(TextSize.parse(raw), 100, reason: raw);
    }
  });

  test('inside the range but not a step is the nearest step', () {
    expect(TextSize.parse('81'), 80);
    expect(TextSize.parse('87'), 90);
    expect(TextSize.parse('104'), 100);
    expect(TextSize.parse('106'), 110);
    expect(TextSize.parse('149'), 150);
    expect(TextSize.parse('112'), 110);
  });

  test('a tie goes to the lower step', () {
    expect(TextSize.parse('85'), 80);
    expect(TextSize.parse('105'), 100);
    expect(TextSize.parse('145'), 140);
  });

  test('surrounding spaces are ignored and it never throws', () {
    expect(TextSize.parse(' 120 '), 120);
    expect(TextSize.parse('99999999999999999999999'), 100);
  });
}
