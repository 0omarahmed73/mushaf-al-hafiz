// Feature 010 T006: the order the page fonts are asked for (research D4).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';

class _Recording extends CachingAssetBundle {
  final List<int> asked = [];

  @override
  Future<ByteData> load(String key) async {
    final page = int.parse(RegExp(r'p(\d+)\.ttf').firstMatch(key)!.group(1)!);
    asked.add(page);
    throw StateError('no font in this test');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shown page first, then two pages in the direction of the turn, then the other side', () async {
    final bundle = _Recording();
    PageFontLoader(bundle: bundle).prefetch(50);
    await Future<void>.delayed(Duration.zero);
    expect(bundle.asked, [50, 51, 52, 49, 48]);

    final back = _Recording();
    PageFontLoader(bundle: back).prefetch(50, direction: -1);
    await Future<void>.delayed(Duration.zero);
    expect(back.asked, [50, 49, 48, 51, 52]);
  });

  test('pages outside 1..604 are skipped and a page already asked for is not asked again', () async {
    final bundle = _Recording();
    final fonts = PageFontLoader(bundle: bundle);
    fonts.prefetch(1);
    await Future<void>.delayed(Duration.zero);
    expect(bundle.asked, [1, 2, 3]);
    bundle.asked.clear();
    final end = _Recording();
    PageFontLoader(bundle: end).prefetch(604);
    await Future<void>.delayed(Duration.zero);
    expect(end.asked, [604, 603, 602]);
  });

  test('a failed load is retried by a later ensure', () async {
    final bundle = _Recording();
    final fonts = PageFontLoader(bundle: bundle);
    await expectLater(fonts.ensure(7), throwsStateError);
    await expectLater(fonts.ensure(7), throwsStateError);
    expect(bundle.asked, [7, 7]);
  });
}
