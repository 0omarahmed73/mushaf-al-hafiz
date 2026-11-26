// RELEASE BLOCKER (feature 014, T032, research D8): the takbir of the prayer notification must be bundled, short, and
// have a named source and licence. It stays red until the owner gives the recording (his own, or a CC0 / CC BY one he
// approves); until then the prayer notification uses the phone's default sound.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('takbir.ogg is bundled, under 150 KB, and credited in licenses.md', () {
    final f = File('android/app/src/main/res/raw/takbir.ogg');
    expect(
      f.existsSync(),
      isTrue,
      reason: 'waiting for the owner\'s takbir recording (T032)',
    );
    expect(f.lengthSync(), lessThan(150 * 1024));
    expect(
      File('docs/research/licenses.md').readAsStringSync(),
      contains('takbir.ogg'),
    );
  });
}
