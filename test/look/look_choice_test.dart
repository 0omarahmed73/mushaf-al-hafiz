// Which look the owner chose, read from the stored text (spec FR-016; data-model.md `Look setting.value`).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/look/look_choice.dart';

void main() {
  group('LookChoice.parse', () {
    test('the two known values', () {
      expect(LookChoice.parse('emerald'), LookChoice.emerald);
      expect(LookChoice.parse('night'), LookChoice.night);
    });

    test('nothing stored, empty, unknown or a different case is Emerald', () {
      for (final raw in <String?>[
        null,
        '',
        ' ',
        'purple',
        'Night',
        'NIGHT',
        'night ',
        'dark',
        '1',
        'null',
      ]) {
        expect(LookChoice.parse(raw), LookChoice.emerald, reason: '"$raw"');
      }
    });

    test('never throws on odd text', () {
      for (final raw in ['\u0000', 'ليلي', '{"look":"night"}', 'a' * 10000]) {
        expect(() => LookChoice.parse(raw), returnsNormally);
      }
    });
  });

  test('the stored name round-trips through parse', () {
    for (final c in LookChoice.values) {
      expect(LookChoice.parse(c.name), c);
    }
    expect(LookChoice.emerald.name, 'emerald');
    expect(LookChoice.night.name, 'night');
  });

  test('the default is Emerald and Gold', () {
    expect(LookChoice.defaultChoice, LookChoice.emerald);
  });
}
