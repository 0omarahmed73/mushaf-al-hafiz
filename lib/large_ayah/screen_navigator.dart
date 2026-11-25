import 'package:flutter/foundation.dart';

import '../ayah/ayah_ref.dart';
import '../mushaf/models.dart';
import 'screen_layout.dart';

/// A screen of the large-ayah view: its page and its index among that page's screens (feature 015, data-model.md).
@immutable
class ScreenRef {
  const ScreenRef(this.page, this.index);

  final int page;
  final int index;

  @override
  bool operator ==(Object other) => other is ScreenRef && other.page == page && other.index == index;

  @override
  int get hashCode => Object.hash(page, index);

  @override
  String toString() => 'ScreenRef($page, $index)';
}

/// Where the screens of a page come from (measured and laid out for one size, count and screen box).
abstract interface class ScreenSource {
  Future<List<LargeScreen>> screensOf(int page);
}

/// Walks the screens one by one across pages (research D5). Each page's screens are asked for once.
class ScreenNavigator {
  ScreenNavigator(this._source, {required this.pageOfAyah});

  final ScreenSource _source;
  final int Function(AyahRef) pageOfAyah;
  final Map<int, Future<List<LargeScreen>>> _pages = {};

  static void _check(int page) {
    if (page < 1 || page > MushafMeta.pageCount) throw RangeError.range(page, 1, MushafMeta.pageCount, 'page');
  }

  /// The screens of [page], asked for once.
  Future<List<LargeScreen>> screensOf(int page) {
    _check(page);
    return _pages.putIfAbsent(page, () => _source.screensOf(page));
  }

  /// The screens already known for [page], or null if they are not ready yet.
  Future<List<LargeScreen>>? known(int page) => _pages[page];

  Future<LargeScreen> screen(ScreenRef r) async {
    final c = await clamp(r);
    return (await screensOf(c.page))[c.index];
  }

  Future<ScreenRef> clamp(ScreenRef r) async {
    final n = (await screensOf(r.page)).length;
    return ScreenRef(r.page, r.index.clamp(0, n - 1));
  }

  Future<ScreenRef> firstOf(int page) async {
    await screensOf(page);
    return ScreenRef(page, 0);
  }

  Future<ScreenRef> lastOf(int page) async => ScreenRef(page, (await screensOf(page)).length - 1);

  /// The next screen; null after the last screen of page 604.
  Future<ScreenRef?> next(ScreenRef r) async {
    if (r.index + 1 < (await screensOf(r.page)).length) return ScreenRef(r.page, r.index + 1);
    if (r.page == MushafMeta.pageCount) return null;
    return firstOf(r.page + 1);
  }

  /// The previous screen; null before the first screen of page 1.
  Future<ScreenRef?> previous(ScreenRef r) async {
    if (r.index > 0) return ScreenRef(r.page, r.index - 1);
    if (r.page == 1) return null;
    return lastOf(r.page - 1);
  }

  /// The screen that holds [ayah] (the first part of a split one); the first screen of its page if no screen holds it.
  Future<ScreenRef> screenOfAyah(AyahRef ayah) async {
    final page = pageOfAyah(ayah);
    final screens = await screensOf(page);
    final i = screens.indexWhere((s) => s.ayat.contains(ayah));
    return ScreenRef(page, i < 0 ? 0 : i);
  }
}
