// Moving screen by screen across pages (feature 015, research D5, contracts/dart-interfaces.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/large_ayah/screen_layout.dart';
import 'package:mushaf/large_ayah/screen_navigator.dart';

/// Page p has (p % 3) + 1 screens; screen i of page p holds ayah (p, i + 1), except page 10, whose single ayah is split
/// in 3 parts.
class _FakeSource implements ScreenSource {
  final List<int> asked = [];

  @override
  Future<List<LargeScreen>> screensOf(int page) async {
    asked.add(page);
    if (page == 10) {
      return [
        for (var i = 1; i <= 3; i++)
          LargeScreen(page: 10, items: [AyahItem(const AyahRef(10, 1), const [])], part: (number: i, of: 3)),
      ];
    }
    return [
      for (var i = 0; i < page % 3 + 1; i++)
        LargeScreen(page: page, items: [AyahItem(AyahRef(page % 114 + 1, i + 1), const [])]),
    ];
  }
}

int _pageOf(AyahRef a) => a.surah == 10 ? 10 : a.surah - 1;

void main() {
  late _FakeSource source;
  late ScreenNavigator nav;

  setUp(() {
    source = _FakeSource();
    nav = ScreenNavigator(source, pageOfAyah: _pageOf);
  });

  test('next stays in the page, then goes to the next page\'s first screen', () async {
    expect(await nav.next(const ScreenRef(2, 0)), const ScreenRef(2, 1));
    expect(await nav.next(const ScreenRef(2, 1)), const ScreenRef(2, 2));
    expect(await nav.next(const ScreenRef(2, 2)), const ScreenRef(3, 0));
  });

  test('previous goes back to the previous page\'s last screen', () async {
    expect(await nav.previous(const ScreenRef(3, 0)), const ScreenRef(2, 2));
    expect(await nav.previous(const ScreenRef(2, 1)), const ScreenRef(2, 0));
  });

  test('the ends: nothing before page 1\'s first screen, nothing after page 604\'s last', () async {
    expect(await nav.previous(const ScreenRef(1, 0)), isNull);
    final last = (await source.screensOf(604)).length - 1;
    expect(await nav.next(ScreenRef(604, last)), isNull);
    expect(await nav.next(ScreenRef(604, last - 1 < 0 ? 0 : last - 1)), last == 0 ? isNull : ScreenRef(604, last));
  });

  test('firstOf, screen and screenOfAyah; a split ayah gives its first part', () async {
    expect(await nav.firstOf(7), const ScreenRef(7, 0));
    expect((await nav.screen(const ScreenRef(10, 2))).part, (number: 3, of: 3));
    expect(await nav.screenOfAyah(const AyahRef(10, 1)), const ScreenRef(10, 0));
    expect(await nav.screenOfAyah(const AyahRef(6, 2)), const ScreenRef(5, 1));
  });

  test('an ayah on no screen of its page falls back to the page\'s first screen', () async {
    expect(await nav.screenOfAyah(const AyahRef(6, 99)), const ScreenRef(5, 0));
  });

  test('a screen index outside its page is clamped', () async {
    expect(await nav.clamp(const ScreenRef(2, 9)), const ScreenRef(2, 2));
    expect(await nav.clamp(const ScreenRef(2, -1)), const ScreenRef(2, 0));
  });

  test('each page\'s screens are asked for once', () async {
    await nav.next(const ScreenRef(2, 2));
    await nav.previous(const ScreenRef(3, 0));
    await nav.firstOf(3);
    expect(source.asked.where((p) => p == 2), hasLength(1));
    expect(source.asked.where((p) => p == 3), hasLength(1));
  });

  test('pages outside 1..604 are refused', () async {
    expect(() => nav.firstOf(0), throwsRangeError);
    expect(() => nav.firstOf(605), throwsRangeError);
  });
}
