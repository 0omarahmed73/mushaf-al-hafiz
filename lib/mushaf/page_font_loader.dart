import 'dart:async';

import 'package:flutter/services.dart';

import 'models.dart';

/// Loads the per-page QCF V2 fonts (family `qpc_p<page>`) once each, on demand.
class PageFontLoader {
  PageFontLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<int, Future<String>> _loading = {};
  final Set<int> _loaded = {};

  static String familyOf(int page) => 'qpc_p$page';

  /// Loads the font for [page] (once) and returns its family name. Throws [RangeError] outside 1..604;
  /// a failed load can be retried by calling again.
  Future<String> ensure(int page) {
    if (page < 1 || page > MushafMeta.pageCount) {
      throw RangeError.range(page, 1, MushafMeta.pageCount, 'page');
    }
    return _loading.putIfAbsent(page, () async {
      try {
        final loader = FontLoader(familyOf(page))..addFont(_bundle.load('assets/fonts/qpc-v2/p$page.ttf'));
        await loader.load();
        _loaded.add(page);
        return familyOf(page);
      } catch (_) {
        _loading.remove(page);
        rethrow;
      }
    });
  }

  bool isLoaded(int page) => _loaded.contains(page);

  /// Starts loading the fonts of the pages around [page] (page ± 2), the shown page first, then the two pages in the
  /// direction the reader is turning ([direction] is 1 for the next pages and -1 for the previous ones), then the other
  /// side; errors are ignored here and surface when the page itself is requested.
  void prefetch(int page, {int direction = 1}) {
    final d = direction < 0 ? -1 : 1;
    for (final p in [page, page + d, page + 2 * d, page - d, page - 2 * d]) {
      if (p < 1 || p > MushafMeta.pageCount || _loading.containsKey(p)) continue;
      unawaited(ensure(p).then<void>((_) {}, onError: (Object _) {}));
    }
  }
}
